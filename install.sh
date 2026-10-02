#!/usr/bin/env bash
# Installs celeryman. Safe to run repeatedly.
#
#   PREFIX             where to link the scripts (default ~/.local/bin)
#   CLAUDE_CONFIG_DIR  Claude Code's config dir (default ~/.claude)

set -euo pipefail

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
MEMORY="$CLAUDE_DIR/CLAUDE.md"
START_MARK='<!-- celeryman:start -->'
END_MARK='<!-- celeryman:end -->'

# --- dependencies ------------------------------------------------------------

hint() {
  case "$(uname -s)" in
    Darwin) echo "brew install $1" ;;
    *)      echo "sudo apt install $1" ;;
  esac
}

missing=0
for dep in tmux chafa jq; do
  if ! command -v "$dep" >/dev/null; then
    echo "missing: $dep   (install with: $(hint "$dep"))"
    missing=1
  fi
done
if ! command -v claude >/dev/null; then
  echo "missing: claude   (see https://code.claude.com/docs/en/setup)"
  missing=1
fi
if command -v tmux >/dev/null; then
  v="$(tmux -V | sed -E 's/[^0-9]*([0-9]+)\.([0-9]+).*/\1 \2/')"
  set -- $v
  if [ "${1:-0}" -lt 3 ] || { [ "${1:-0}" -eq 3 ] && [ "${2:-0}" -lt 3 ]; }; then
    echo "tmux 3.3 or newer is required (found $(tmux -V)). Upgrade with: $(hint tmux)"
    missing=1
  fi
fi
[ "$missing" -eq 0 ] || exit 1

# --- scripts -----------------------------------------------------------------

mkdir -p "$PREFIX"
for f in celeryman celery-pane; do
  chmod +x "$ROOT/bin/$f"
  ln -sfn "$ROOT/bin/$f" "$PREFIX/$f"
done
echo "linked celeryman and celery-pane into $PREFIX"

# --- slash commands ----------------------------------------------------------

mkdir -p "$CLAUDE_DIR/commands"
for src in "$ROOT"/claude/commands/*.md; do
  dest="$CLAUDE_DIR/commands/$(basename "$src")"
  if [ -f "$dest" ] && ! grep -q 'installed by celeryman' "$dest"; then
    cp "$dest" "$dest.bak"
    echo "backed up your existing $(basename "$dest") to $(basename "$dest").bak"
  fi
  cp "$src" "$dest"
done
echo "installed slash commands into $CLAUDE_DIR/commands"

# --- glossary ----------------------------------------------------------------

touch "$MEMORY"
tmp="$(mktemp)"
# Drop any previous celeryman block, then append the current one.
awk -v s="$START_MARK" -v e="$END_MARK" '
  $0 == s { skip = 1; next }
  $0 == e { skip = 0; next }
  !skip
' "$MEMORY" > "$tmp"
# Trim trailing blank lines left behind by a previous block.
printf '%s\n' "$(cat "$tmp")" > "$tmp.2"
{
  [ -s "$tmp" ] && { cat "$tmp.2"; echo; }
  echo "$START_MARK"
  cat "$ROOT/claude/glossary.md"
  echo "$END_MARK"
} > "$MEMORY"
rm -f "$tmp" "$tmp.2"
echo "added the phrase glossary to $MEMORY"

# --- hooks -------------------------------------------------------------------

[ -s "$SETTINGS" ] || echo '{}' > "$SETTINGS"
jq empty "$SETTINGS" || { echo "$SETTINGS is not valid JSON; not touching it." >&2; exit 1; }
backup="$SETTINGS.celeryman-backup.$(date +%Y%m%d%H%M%S)"
cp "$SETTINGS" "$backup"

pane_cmd="$(printf '%q' "$PREFIX/celery-pane")"
new_hooks="$(sed "s|@CELERY_PANE@|$pane_cmd|g" "$ROOT/hooks/celeryman-hooks.json")"

# Remove any earlier celeryman hooks, then append ours to each event's list.
# Hooks belonging to anything else are left exactly as they were.
jq --argjson new "$new_hooks" '
  def is_ours: (.command // "") | test("celery-pane (idle|crunching|waiting|prompt)$");
  .hooks = (
    (.hooks // {})
    | with_entries(.value |= (map(.hooks |= map(select(is_ours | not)))
                              | map(select(.hooks | length > 0))))
    | with_entries(select(.value | length > 0))
    | reduce ($new.hooks | to_entries[]) as $e (.; .[$e.key] = ((.[$e.key] // []) + $e.value))
  )
' "$SETTINGS" > "$SETTINGS.tmp"
mv "$SETTINGS.tmp" "$SETTINGS"
echo "merged hooks into $SETTINGS (backup: $(basename "$backup"))"

# --- done --------------------------------------------------------------------

case ":$PATH:" in
  *":$PREFIX:"*) ;;
  *) echo; echo "note: $PREFIX is not on your PATH. Add it to your shell profile." ;;
esac
cat <<EOF

Done. Put idle.gif, crunching.gif and waiting.gif in $ROOT/gifs, then run: celeryman
For the "Computer, load up Celery Man" command, add this to your ~/.zshrc or ~/.bashrc:
  source $(printf '%q' "$ROOT/shell/celeryman-alias.sh")
EOF
