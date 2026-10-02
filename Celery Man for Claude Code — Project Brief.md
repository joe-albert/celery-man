# Celery Man for Claude Code — Project Brief

Oct 2, 2026 · @Joe

## Overview

Build **celeryman**: a terminal setup that runs the real Claude Code with Tim and Eric "Celery Man" phrases as commands, and plays a GIF in a tmux side pane while Claude works.

Typing "Can I get a hat wobble?" should make Claude review the current branch. While it works, a "crunching" GIF plays; when it needs approval, a "waiting" GIF plays; when it finishes, an idle GIF returns.

Stack: bash, tmux, [chafa](https://hpjansson.org/chafa/) (terminal GIF player), jq, and Claude Code's built-in hooks, CLAUDE.md, and custom slash commands. No custom TUI, web UI, or Agent SDK in v1. Targets macOS and Linux.

## Architecture

One tmux session named `celeryman` with two panes: Claude Code on the left, a GIF pane (about 30% width) on the right. Claude Code hooks tell the GIF pane which animation to play.

Event flow:

1. User types a phrase or slash command into Claude Code.
2. `UserPromptSubmit` hook runs `celery-pane crunching`.
3. Claude interprets the phrase using the glossary in CLAUDE.md, or runs the matching slash command.
4. `Notification` hook (Claude needs permission or input) runs `celery-pane waiting`.
5. `Stop` hook (Claude finished its turn) runs `celery-pane idle`.

Pane switching: `celery-pane <state>` should replace the right pane's process with `tmux respawn-pane -k -t <pane> "chafa ..."` rather than typing into a shell with `send-keys`. This avoids orphaned chafa processes and stray keystrokes.

Phrase mapping has two layers, both native to Claude Code: a glossary section in the user-level CLAUDE.md (handles loose phrasing) and user-level slash commands (exact, reliable shortcuts).

## Components and file layout

The repo installs scripts onto the PATH and merges hooks, commands, and the glossary into `~/.claude/` so it works in every project.

```
celeryman/
  bin/celeryman              # launcher: create or attach tmux session, start claude + GIF pane
  bin/celery-pane            # hook target: celery-pane idle|crunching|waiting
  config.sh                  # GIF paths, pane width, chafa flags
  hooks/celeryman-hooks.json # hook definitions to merge into ~/.claude/settings.json
  claude/glossary.md         # phrase glossary, appended to ~/.claude/CLAUDE.md
  claude/commands/*.md       # slash commands, copied to ~/.claude/commands/
  gifs/                      # user-supplied GIFs (gitignored): idle.gif, crunching.gif, waiting.gif
  install.sh                 # copy files, back up and merge settings.json with jq (idempotent)
  uninstall.sh               # remove only celeryman's hooks, commands, and glossary block
  README.md
```

The glossary block in CLAUDE.md should be wrapped in start and end marker comments so uninstall.sh can remove it cleanly.

## Command mapping

Starter set; the user will edit these. Each row becomes one glossary entry and one slash command file whose body is the real prompt.

| Phrase | Slash command | Real prompt |
| --- | --- | --- |
| Can I get a hat wobble? | `/hatwobble` | Review the current branch against main. Summarize the changes and flag bugs, risks, and style issues. |
| Flarhgunnstow | `/flarhgunnstow` | Run the test suite and fix any failures. |
| Give me a printout of Oyster smiling | `/oyster` | Summarize what changed since main in plain language. |
| Nude Tayne | `/nudetayne` | Show the full git diff with no summarizing. |
| Engage 4d3d3d3 | `/4d3d3d3` | Run the linter and formatter and fix what they report. |
| Now Tayne I can get into | `/tayne` | Write a conventional commit message for the staged changes and commit them. |
| Computer, load up Celery Man | (shell alias) | Runs `celeryman` to start the session. |

The glossary should tell Claude to match these loosely (case, punctuation, small variations) and to treat everything else as a normal request.

## Requirements and gotchas

Dependencies: Claude Code, tmux 3.3 or newer, chafa, jq, bash. install.sh should check for each and print an install hint (Homebrew on macOS, apt on Debian/Ubuntu) if one is missing.

- **Verify hook details first.** Confirm current hook event names, the settings.json schema, and user-level command and CLAUDE.md locations against the Claude Code docs before writing code. Don't rely on memory.
- **Hooks must be fast and silent.** Run the pane switch in the background, exit 0, and send all output to /dev/null. Output from `UserPromptSubmit` can be added to Claude's context.
- **No-op outside celeryman.** `celery-pane` must exit quietly when the `celeryman` tmux session or its GIF pane doesn't exist, so Claude Code behaves normally everywhere else.
- **Never clobber settings.json.** Back it up, merge with jq, and make install and uninstall idempotent. Leave the user's existing hooks untouched.
- **Graphics inside tmux.** Real image output needs a graphics-capable terminal (Kitty, iTerm2, WezTerm) and likely `set -g allow-passthrough on` in tmux. If graphics fail, chafa's symbol mode is an acceptable fallback; make the mode configurable.
- **Test in a real terminal.** WebStorm's built-in terminal won't render the GIFs correctly.
- **No orphans.** Switching states or killing the session must leave no chafa processes running.
- **GIFs are user-supplied.** Ship no GIFs; gitignore `gifs/` and document the expected file names.

## Build milestones

Build in this order; each milestone should work on its own before moving on.

1. **Launcher.** `celeryman` creates the tmux session with Claude Code left and idle.gif right.
   - Done when: running it twice attaches to the existing session instead of creating a second one.
2. **GIF pane script.** `celery-pane idle|crunching|waiting` switches the animation.
   - Done when: switching is near-instant, leaves no orphan chafa processes, and does nothing outside the session.
3. **Hooks and installer.** install.sh merges the hooks; uninstall.sh removes only celeryman's.
   - Done when: sending a prompt shows crunching, a permission prompt shows waiting, finishing shows idle, and `claude` outside tmux is unaffected.
4. **Commands.** Install the glossary and slash commands from the mapping table.
   - Done when: "Can I get a hat wobble?" and `/hatwobble` both trigger a branch review.
5. **Polish.** README with setup steps and screenshots, config.sh options, and the "Computer, load up Celery Man" alias.

Out of scope for v1: a custom TUI (Ink or Textual), a web UI, and the Claude Agent SDK.

## Prior art and references

No existing Celery Man wrapper was found, but these projects use the same hooks-plus-side-pane pattern and are worth reading first.

- [ClaudeLab](https://pypi.org/project/claudelab/): animated scenes in a tmux pane driven by Claude Code hooks. Its installer that merges hooks into settings.json is the closest model for install.sh.
- [Claude Quest](https://github.com/Michaelliv/claude-quest): pixel-art character in a second terminal that maps each Claude action to an animation.
- [Claude Pet](https://github.com/IMMINJU/claude-pet) and [Claude Status Bar](https://github.com/m1ckc3s/claude-status-bar): desktop and menu bar versions; useful lists of hook events in practice.
- [Claude Code docs](https://docs.claude.com/en/docs/claude-code/overview): hooks, slash commands, and CLAUDE.md memory.
- [chafa](https://hpjansson.org/chafa/): GIF playback and output modes.
