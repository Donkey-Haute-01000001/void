# Case 1: The Winter Rose (vertical slice)

A 1939 Boston occult-investigation RPG built in Godot. This branch holds the
first playable piece of the Case 1 proof of concept: **Adrian's office**.
All art is placeholder shapes, and all sound is generated in code.

## Play it

1. Install [Godot 4.4](https://godotengine.org/download) or newer (the standard
   version, not .NET).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5** (or the Play button in the top right).

Click the floor to walk. Click an object to examine it. You get three of the six
before Tom Garrity knocks. Click (or press Enter) to move the narration on.

## What's in the slice

- The opening: narration and sound only, no inner voices.
- Six objects, three examined. Each choice is remembered for later payoffs.
  Two pay off already: the gin adds a line with Tom, and the bills add a die
  to the fee check. If Adrian takes the pistol, Tom notices it.
- Tom's knock, the job, and a visible Eloquence dice check to push the fee.
- Autosave at the start, at the knock and at the end. **Continue** on the
  title screen resumes from the last one.

## Where things live

| Path | What it is |
| --- | --- |
| `data/script/office.json` | Every line of narration and dialogue, keyed by id. Edit text here. |
| `audio/vo/` | Narrator recordings, named `<line id>.ogg`, played automatically. |
| `data/characters/` | Adrian's and Tom's skill sheets (the agreed draft). |
| `autoload/dice.gd` | Dice pools: d10s, success on a roll at or under the skill. |
| `autoload/game_state.gd` | What the run remembers: examined objects, flags, fee. |
| `scenes/office/` | The office scene and the placeholder figures. |
| `ui/story_panel.gd` | The right-hand narration column, choices and dice checks. |

## Tests

```
godot --headless res://tests/run_tests.tscn
```

This checks the dice odds over 10,000 rolls, the character sheets, the
autosave, and plays the whole office from the first object to the end card.
