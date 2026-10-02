# celeryman configuration. Sourced by bin/celeryman and bin/celery-pane.
# Every value can be overridden from the environment, e.g.
#   CELERYMAN_CHAFA_FORMAT=kitty celeryman

# Prefix for tmux session names. Each directory gets its own session,
# named <prefix>-<directory name>, e.g. celeryman-myproject.
CELERYMAN_SESSION="${CELERYMAN_SESSION:-celeryman}"

# Width of the GIF pane, as a percentage of the window.
CELERYMAN_PANE_WIDTH="${CELERYMAN_PANE_WIDTH:-30}"

# Directory holding idle.gif, hatwobble.gif and waiting.gif.
CELERYMAN_GIF_DIR="${CELERYMAN_GIF_DIR:-$CELERYMAN_ROOT/gifs}"

# chafa output format: symbols | kitty | iterm | sixels.
# "symbols" (text-art) works everywhere, including inside tmux. The graphics
# formats look much better but need a graphics-capable terminal (Kitty, iTerm2,
# WezTerm) and tmux passthrough, which celeryman enables for its session.
CELERYMAN_CHAFA_FORMAT="${CELERYMAN_CHAFA_FORMAT:-symbols}"

# Extra flags passed to chafa, e.g. "--symbols=block --colors=256".
CELERYMAN_CHAFA_FLAGS="${CELERYMAN_CHAFA_FLAGS:-}"

# Command run in the left pane.
CELERYMAN_CLAUDE_CMD="${CELERYMAN_CLAUDE_CMD:-claude}"
