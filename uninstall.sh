#!/usr/bin/env bash
# Removes celeryman's scripts, hooks, slash commands and glossary block.
# Leaves everything else in ~/.claude alone. Safe to run repeatedly.

set -euo pipefail

ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/bin}"
CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SETTINGS="$CLAUDE_DIR/settings.json"
MEMORY="$CLAUDE_DIR/CLAUDE.md"
START_MARK='<!-- celeryman:start -->'
END_MARK='<!-- celeryman:end -->'

command -v jq >/dev/null || { echo "uninstall needs jq" >&2; exit 1; }

# Scripts: only remove links that point into this repo.
for f in celeryman celery-pane; do
  link="$PREFIX/$f"
  if [ -L "$link" ] && [ "$(readlink "$link")" = "$ROOT/bin/$f" ]; then
    rm "$link"
    echo "removed $link"
  fi
done

# Slash commands: only files celeryman installed.
for src in "$ROOT"/claude/commands/*.md; do
  dest="$CLAUDE_DIR/commands/$(basename "$src")"
  if [ -f "$dest" ] && grep -q 'installed by celeryman' "$dest"; then
    rm "$dest"
    echo "removed $dest"
    if [ -f "$dest.bak" ]; then
      mv "$dest.bak" "$dest"
      echo "restored your original $(basename "$dest")"
    fi
  fi
done

# Glossary block.
if [ -f "$MEMORY" ] && grep -qF "$START_MARK" "$MEMORY"; then
  tmp="$(mktemp)"
  awk -v s="$START_MARK" -v e="$END_MARK" '
    $0 == s { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip
  ' "$MEMORY" > "$tmp"
  content="$(cat "$tmp")"   # strips trailing blank lines
  rm -f "$tmp"
  if [ -z "$content" ]; then
    rm "$MEMORY"
  else
    printf '%s\n' "$content" > "$MEMORY"
  fi
  echo "removed the glossary from $MEMORY"
fi

# Hooks.
if [ -f "$SETTINGS" ]; then
  backup="$SETTINGS.celeryman-backup.$(date +%Y%m%d%H%M%S)"
  cp "$SETTINGS" "$backup"
  jq '
    def is_ours: (.command // "") | test("celery-pane (idle|crunching|waiting|prompt)$");
    if .hooks then
      .hooks |= (with_entries(.value |= (map(.hooks |= map(select(is_ours | not)))
                                         | map(select(.hooks | length > 0))))
                 | with_entries(select(.value | length > 0)))
      | if .hooks == {} then del(.hooks) else . end
    else . end
  ' "$SETTINGS" > "$SETTINGS.tmp"
  if cmp -s "$SETTINGS" "$SETTINGS.tmp"; then
    rm "$SETTINGS.tmp" "$backup"
  else
    mv "$SETTINGS.tmp" "$SETTINGS"
    echo "removed celeryman hooks from $SETTINGS (backup: $(basename "$backup"))"
  fi
fi

echo "celeryman uninstalled. Your gifs/ folder was left in place."
