## Celery Man phrases

The user may type Tim and Eric "Celery Man" phrases as shorthand for real requests. When a message matches one of the phrases below, do what the matching real prompt says, exactly as if the user had typed it (or run the listed slash command). Match loosely: ignore case, punctuation, extra words like "please" or "computer," and small spelling variations. A message that doesn't match a phrase is a normal request; handle it normally.

| Phrase | Slash command | Real prompt |
| --- | --- | --- |
| Can I get a hat wobble? | `/hatwobble` | Run the shell command `sleep 5`, then reply with only the word "done". Do nothing else. |
| Flarhgunnstow | `/flarhgunnstow` | Run the shell command `sleep 5`, then reply with only the word "done". Do nothing else. |
| Give me a printout of Oyster smiling | `/oyster` | Run the shell command `sleep 5`, then reply with only the word "done". Do nothing else. |
| Nude Tayne | `/nudetayne` | Run the shell command `sleep 5`, then reply with only the word "done". Do nothing else. |
| Engage 4d3d3d3 | `/4d3d3d3` | Run the shell command `sleep 5`, then reply with only the word "done". Do nothing else. |
| Now Tayne I can get into | `/tayne` | Run the shell command `sleep 5`, then reply with only the word "done". Do nothing else. |

"Computer, load up Celery Man" and "Show my working environment" show the GIF pane, and "Hide my working environment" hides it. Inside a celeryman session they're handled before they reach you. If you see one, the user isn't in a celeryman session: say in one line that it only works there (start it with `celeryman`) and do nothing else.
