# celeryman

Claude Code, but with Celery Man. Type "Can I get a hat wobble?" and Claude reviews your branch while a GIF crunches away in a tmux side pane.

```
┌──────────────────────────────┬─────────────┐
│ > Can I get a hat wobble?    │             │
│                              │  crunching  │
│ ● Reviewing branch...        │    .gif     │
│                              │             │
└──────────────────────────────┴─────────────┘
         Claude Code (70%)        GIF (30%)
```

The left pane runs the real Claude Code. The right pane plays one of three GIFs, switched by Claude Code hooks:

| State | When | Hook |
| --- | --- | --- |
| `crunching` (or the command's own GIF) | You send a prompt, or a tool finishes | `UserPromptSubmit`, `PostToolUse` |
| `waiting` | Claude needs permission or input | `Notification` (`permission_prompt`, `elicitation_dialog`) |
| `idle` | Claude finishes its turn | `Stop`, `StopFailure` |

## Requirements

- [Claude Code](https://code.claude.com/docs/en/setup)
- tmux 3.3 or newer, [chafa](https://hpjansson.org/chafa/), jq, bash
- macOS or Linux

```sh
brew install tmux chafa jq          # macOS
sudo apt install tmux chafa jq      # Debian/Ubuntu
```

## Install

```sh
git clone <this repo> celeryman && cd celeryman
./install.sh
```

The installer:

- links `celeryman` and `celery-pane` into `~/.local/bin` (set `PREFIX` to change it)
- copies the slash commands into `~/.claude/commands/`, backing up any existing file with the same name
- appends the phrase glossary to `~/.claude/CLAUDE.md` between `<!-- celeryman:start -->` and `<!-- celeryman:end -->` markers
- backs up `~/.claude/settings.json` and merges in the hooks with jq, leaving your existing hooks alone

You can run it as often as you like. Re-running it updates the installed files in place. `./uninstall.sh` removes only what celeryman added.

## Add your GIFs

No GIFs ship with celeryman. Put three files in `gifs/`:

```
gifs/idle.gif
gifs/crunching.gif
gifs/waiting.gif
```

If a GIF is missing, the pane shows the state name in plain text instead.

### Per-command GIFs

To give a command its own animation, add `gifs/<command>.gif`. It plays instead of `crunching.gif` while that command runs:

```
gifs/hatwobble.gif       # "Can I get a hat wobble?" or /hatwobble
gifs/flarhgunnstow.gif
gifs/oyster.gif
gifs/nudetayne.gif
gifs/4d3d3d3.gif
gifs/tayne.gif
```

The command is detected from what you type: a slash command (`/hatwobble`), or a phrase from `claude/glossary.md`, matched loosely like Claude does. Any slash command works, not just celeryman's, so `gifs/review.gif` plays during `/review`. When Claude stops to ask for permission, `waiting.gif` plays, then the command's GIF resumes. A command without its own GIF falls back to `crunching.gif`.

## Run

```sh
celeryman              # or: celeryman --continue, etc. (args go to claude)
```

Each directory gets its own session (`celeryman-<directory name>`), and Claude starts in the directory you launched from. Running `celeryman` again from the same directory attaches to its existing session instead of creating a new one. When you quit Claude, the session closes.

To start it the proper way, add this to `~/.zshrc` or `~/.bashrc`:

```sh
source /path/to/celeryman/shell/celeryman-alias.sh
```

Then:

```
$ Computer, load up Celery Man
```

## Commands

Type the phrase (loosely: case, punctuation, and small variations are fine) or the slash command.

| Phrase | Slash command | What Claude does |
| --- | --- | --- |
| Can I get a hat wobble? | `/hatwobble` | Reviews the current branch against main. Summarizes the changes and flags bugs, risks, and style issues. |
| Flarhgunnstow | `/flarhgunnstow` | Runs the test suite and fixes any failures. |
| Give me a printout of Oyster smiling | `/oyster` | Summarizes what changed since main in plain language. |
| Nude Tayne | `/nudetayne` | Shows the full git diff with no summarizing. |
| Engage 4d3d3d3 | `/4d3d3d3` | Runs the linter and formatter and fixes what they report. |
| Now Tayne I can get into | `/tayne` | Writes a conventional commit message for the staged changes and commits them. |

To change them, edit `claude/glossary.md` and `claude/commands/*.md`, then re-run `./install.sh`. Each command file's body is the real prompt sent to Claude. Keep the `<!-- installed by celeryman -->` line so uninstall can find it.

## Configuration

Settings live in `config.sh`. Each can also be set as an environment variable.

| Variable | Default | Meaning |
| --- | --- | --- |
| `CELERYMAN_SESSION` | `celeryman` | Prefix for tmux session names (`<prefix>-<directory name>`) |
| `CELERYMAN_PANE_WIDTH` | `30` | GIF pane width, in percent |
| `CELERYMAN_GIF_DIR` | `<repo>/gifs` | Where the GIFs live |
| `CELERYMAN_CHAFA_FORMAT` | `symbols` | `symbols`, `kitty`, `iterm`, or `sixels` |
| `CELERYMAN_CHAFA_FLAGS` | (empty) | Extra chafa flags, e.g. `--symbols=block --colors=256` |
| `CELERYMAN_CLAUDE_CMD` | `claude` | Command run in the left pane |

### Real graphics instead of text-art

The default `symbols` mode draws the GIF with Unicode characters, which works in any terminal. For real pixels, use a graphics-capable terminal (Kitty, WezTerm, or iTerm2) and set the format to match:

```sh
CELERYMAN_CHAFA_FORMAT=kitty celeryman     # Kitty, WezTerm
CELERYMAN_CHAFA_FORMAT=iterm celeryman     # iTerm2
```

celeryman turns on `allow-passthrough` for its own session, which tmux needs to forward image data. If images still don't appear, switch back to `symbols`.

IDE terminals (WebStorm, VS Code) don't render the GIFs well. Use a standalone terminal.

## How it works

- `bin/celeryman` creates a tmux session for the current directory with Claude on the left and the GIF pane on the right, and stores the GIF pane's id in the session option `@celeryman_gif_pane`.
- `bin/celery-pane <state>` runs from the hooks. On `UserPromptSubmit` it runs as `celery-pane prompt`, reads the prompt from the hook's JSON input, and stores the matching command in the pane option `@celeryman_cmd` so later `crunching` events keep that command's GIF. It replaces the GIF pane's process with `tmux respawn-pane -k`, which kills the previous chafa, so no orphan processes are left behind. If the pane already shows the requested GIF, it does nothing, so the animation doesn't restart on every tool call.
- `celery-pane` only acts when Claude itself is running inside a celeryman session (it looks up `@celeryman_gif_pane` from `$TMUX_PANE`). Everywhere else, the hooks exit immediately and silently, and Claude Code behaves normally.
- The hooks run synchronously so states always apply in order. Each call is a couple of tmux commands that return in milliseconds; chafa itself runs inside tmux, not in the hook.

## Uninstall

```sh
./uninstall.sh
```
