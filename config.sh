# celeryman configuration. Sourced by bin/celeryman and bin/celery-pane.
# Every value can be overridden from the environment, e.g.
#   CELERYMAN_CHAFA_FORMAT=kitty celeryman

# Prefix for tmux session names. Each directory gets its own session,
# named <prefix>-<directory name>, e.g. celeryman-myproject.
CELERYMAN_SESSION="${CELERYMAN_SESSION:-celeryman}"

# Width of the GIF pane, as a percentage of the window.
CELERYMAN_PANE_WIDTH="${CELERYMAN_PANE_WIDTH:-30}"

# Directory holding celeryman.gif, crunching.gif, waiting.gif and any
# per-command GIFs (e.g. hatwobble.gif).
CELERYMAN_GIF_DIR="${CELERYMAN_GIF_DIR:-$CELERYMAN_ROOT/gifs}"

# Per-command images that don't follow the <command>.gif naming, one
# "command = file" per line. Files are relative to CELERYMAN_GIF_DIR (or
# absolute) and can be any format chafa shows, including still images.
# If a mapped file is missing, <command>.gif is used as usual.
CELERYMAN_COMMAND_GIFS="${CELERYMAN_COMMAND_GIFS:-
oyster = oyster smiling.jpg
}"

# chafa output format: symbols | kitty | iterm | sixels.
# "symbols" (text-art) works everywhere, including inside tmux. The graphics
# formats look much better but need a graphics-capable terminal (Kitty, iTerm2,
# WezTerm) and tmux passthrough, which celeryman enables for its session.
CELERYMAN_CHAFA_FORMAT="${CELERYMAN_CHAFA_FORMAT:-symbols}"

# Extra flags passed to chafa, e.g. "--symbols=block --colors=256".
CELERYMAN_CHAFA_FLAGS="${CELERYMAN_CHAFA_FLAGS:-}"

# Name used in the greeting when Claude opens ("Good morning <name>, ...") and
# in the reply to "Computer, load up Celery Man" ("Yes, <name>").
# Empty means the first word of your git user.name, else your account name.
CELERYMAN_NAME="${CELERYMAN_NAME:-}"

# Replies shown when a command starts, one "command = reply" per line.
CELERYMAN_COMMAND_REPLIES="${CELERYMAN_COMMAND_REPLIES:-
4d3d3d3 = 4d3d3d3 engaged.
}"

# Command run in the left pane.
CELERYMAN_CLAUDE_CMD="${CELERYMAN_CLAUDE_CMD:-claude}"

# --- helpers -----------------------------------------------------------------

# Prints the name to greet: CELERYMAN_NAME as given, otherwise the first word
# of your git user.name, macOS full name, or login name.
celeryman_name() {
  local name="$CELERYMAN_NAME"
  if [ -z "$name" ]; then
    name="$(git config user.name 2>/dev/null || true)"
    [ -n "$name" ] || name="$(id -F 2>/dev/null || true)"
    [ -n "$name" ] || name="$USER"
    name="${name%% *}"
  fi
  printf '%s' "$name"
}

# Prints the value for key $2 in $1, a list of "key = value" lines.
celeryman_lookup() {
  printf '%s\n' "$1" | awk -F= -v key="$2" '
    { k = $1; gsub(/^[ \t]+|[ \t]+$/, "", k) }
    k == key { sub(/^[^=]*=[ \t]*/, ""); sub(/[ \t]+$/, ""); print; exit }'
}
