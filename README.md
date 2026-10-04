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
| `idle` | Claude finishes its turn: the last prompt's GIF keeps playing (`celeryman.gif` until the first prompt) | `Stop`, `StopFailure` |

## Requirements

- [Claude Code](https://code.claude.com/docs/en/setup)
- tmux 3.3 or newer, [chafa](https://hpjansson.org/chafa/), jq, bash
- Optional: [mpg123](https://www.mpg123.de/), to play music alongside the GIFs
- macOS or Linux

```sh
brew install tmux chafa jq mpg123          # macOS (or Linux with Homebrew)
sudo apt install tmux chafa jq mpg123      # Debian/Ubuntu
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
gifs/celeryman.gif    # the default: plays at launch, before your first prompt
gifs/crunching.gif
gifs/waiting.gif
```

`celeryman.gif` is also the fallback: any state without its own GIF plays it instead. If `celeryman.gif` is missing too, the pane shows the state name in plain text.

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

To use a file with a different name, or a still image, map it in `config.sh` (or the `CELERYMAN_COMMAND_GIFS` environment variable), one `command = file` per line. By default, a printout of Oyster smiling shows a still:

```sh
CELERYMAN_COMMAND_GIFS="
oyster = oyster smiling.jpg
tayne = tayne-dancing-2.gif
"
```

A mapped file that's missing falls back to `<command>.gif`.

The command is detected from what you type: a slash command (`/hatwobble`), or a phrase from `claude/glossary.md`, matched loosely like Claude does. Any slash command works, not just celeryman's, so `gifs/review.gif` plays during `/review`. When Claude stops to ask for permission, `waiting.gif` plays, then the command's GIF resumes. A command without its own GIF falls back to `crunching.gif`.

## Add music

With [mpg123](https://www.mpg123.de/) installed, put a song in `music/`:

```
music/celery-man.mp3
```

Typing "Computer, load up Celery Man" into Claude starts it, and it loops until you quit Claude. It keeps playing as the GIFs change. "Hide my working environment" pauses it, and "Show my working environment" (or loading up Celery Man again) picks up where it left off.

If there are several MP3s, the first one alphabetically plays; set `CELERYMAN_SONG` to pick another. Set `CELERYMAN_VOLUME` (0-100, default 50) to change the volume, or `CELERYMAN_SOUND=off` to mute. Without mpg123, or without a song, celeryman is silent. `music/` is gitignored like `gifs/`.

## Run

```sh
celeryman              # or: celeryman --continue, etc. (args go to claude)
```

Claude opens with "Good morning Paul, what will your first sequence of the day be?", using `CELERYMAN_NAME`, or the first word of your git `user.name` if that's not set. It comes from a `SessionStart` hook that only celeryman sessions load (via `claude --settings`), so Claude Code prefixes it with "SessionStart:startup says:".

Each directory gets its own session (`celeryman-<directory name>`), and Claude starts in the directory you launched from. Running `celeryman` again from the same directory attaches to its existing session instead of creating a new one. When you quit Claude, the session closes.

To start it the proper way, add this to `~/.zshrc` or `~/.bashrc`:

```sh
source /path/to/celeryman/shell/celeryman-alias.sh
```

Then:

```
$ Computer, load up Celery Man
```

That starts Claude with the GIF pane hidden. Say it again to Claude to load up the pane.

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

### Show and hide the GIF pane

Claude opens on its own, with the GIF pane hidden. Type "Computer, load up Celery Man" into Claude to bring it out.

| Phrase | What happens |
| --- | --- |
| Computer, load up Celery Man | Shows the GIF pane, starts (or resumes) the music, and replies "Yes, Paul" (your name). |
| Show my working environment | Shows the GIF pane and resumes the music if it was playing. |
| Hide my working environment | Hides the GIF pane so Claude gets the full width, and pauses the music. |

These are handled by the hook and never reach Claude, so they cost no tokens. Claude Code shows them as a blocked prompt with a short message, e.g. "Hid your working environment." They only match the whole phrase (case, punctuation and a leading "Computer," are ignored), so a longer request that mentions your working environment goes to Claude as usual. While the pane is hidden it stops playing, but it keeps track of the current command, so it comes back showing that command's GIF (or `celeryman.gif` if nothing has run yet).

### Replies

Some commands get a reply from the hook when they start, shown under your prompt (Claude Code labels it "UserPromptSubmit says:"). The command still runs as usual. By default, Engage 4d3d3d3 replies "4d3d3d3 engaged." Add more in `config.sh` (or the `CELERYMAN_COMMAND_REPLIES` environment variable), one `command = reply` per line:

```sh
CELERYMAN_COMMAND_REPLIES="
4d3d3d3 = 4d3d3d3 engaged.
hatwobble = Hat wobble, coming right up.
"
```

To change them, edit `claude/glossary.md` and `claude/commands/*.md`, then re-run `./install.sh`. Each command file's body is the real prompt sent to Claude. Keep the `<!-- installed by celeryman -->` line so uninstall can find it.

## Configuration

Settings live in `config.sh`. Each can also be set as an environment variable.

| Variable | Default | Meaning |
| --- | --- | --- |
| `CELERYMAN_SESSION` | `celeryman` | Prefix for tmux session names (`<prefix>-<directory name>`) |
| `CELERYMAN_PANE_WIDTH` | `30` | GIF pane width, in percent |
| `CELERYMAN_GIF_DIR` | `<repo>/gifs` | Where the GIFs live |
| `CELERYMAN_COMMAND_GIFS` | `oyster = oyster smiling.jpg` | Per-command image overrides, one `command = file` per line |
| `CELERYMAN_SOUND` | `on` | `off` mutes the music |
| `CELERYMAN_MUSIC_DIR` | `<repo>/music` | Where the song lives |
| `CELERYMAN_SONG` | first `.mp3` in the music dir | The song to play (a file name there, or an absolute path) |
| `CELERYMAN_VOLUME` | `50` | Music volume, 0-100 |
| `CELERYMAN_CHAFA_FORMAT` | `symbols` | `symbols`, `kitty`, `iterm`, or `sixels` |
| `CELERYMAN_CHAFA_FLAGS` | (empty) | Extra chafa flags, e.g. `--symbols=block --colors=256` |
| `CELERYMAN_NAME` | first word of git `user.name` | Name in the "Good morning" greeting and the "Yes, <name>" reply |
| `CELERYMAN_COMMAND_REPLIES` | `4d3d3d3 = 4d3d3d3 engaged.` | Replies shown when a command starts, one `command = reply` per line |
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
- The GIF pane starts in a background window (`celeryman-hidden`). "Hide my working environment" moves it back there with `tmux break-pane` and stops chafa. "Computer, load up Celery Man" and "Show my working environment" bring it out with `tmux join-pane`. All three reply to the hook with `{"decision": "block"}`, so the prompt isn't sent to Claude.
- The song runs as `mpg123` in its own background window (`celeryman-music`), so GIF changes don't touch it. Hiding and showing the pane pause and resume it by sending mpg123's pause key (`s`) with `tmux send-keys`. Quitting Claude closes the session, which stops it.
- `celery-pane` only acts when Claude itself is running inside a celeryman session (it looks up `@celeryman_gif_pane` from `$TMUX_PANE`). Everywhere else, the hooks exit immediately and silently, and Claude Code behaves normally.
- The hooks run synchronously so states always apply in order. Each call is a couple of tmux commands that return in milliseconds; chafa itself runs inside tmux, not in the hook.

## Uninstall

```sh
./uninstall.sh
```
