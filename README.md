# Case 1: The Winter Rose (vertical slice)

A 1939 Boston occult-investigation RPG built in Godot. This branch holds the
first playable piece of the Case 1 proof of concept: **Adrian's office**,
seen from an isometric camera, in Sin City black and white (red is the only
colour left) with art deco type. The room and figures are
placeholder shapes, the portraits are placeholder crops, and all sound is
generated in code.

## Play it

1. Install [Godot 4.4](https://godotengine.org/download) or newer (the standard
   version, not .NET).
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5** (or the Play button in the top right).

Click the floor to walk. Click an object to examine it. You get three of the six
before Tom Garrity knocks. Click (or press Enter) to move the text on; the first
click finishes the line, the second moves on. Press **1**, **2** … to pick a
choice. Press **C** to open Adrian's dossier.

## What's in the slice

- The opening: black-screen captions, the room fades in, then Adrian's dossier
  card (portrait, skills by tier, perks and flaw). Narration and sound only,
  no inner voices.
- A HUD with Adrian's portrait, Health, Sanity and what he is carrying.
- Katana Zero-style text: narration types out as captions, characters speak in
  boxes over their heads, and dice checks stamp SUCCESS or FAILURE.
- Six objects, three examined. Each choice is remembered for later payoffs.
  Two pay off already: the gin adds a line with Tom, and the bills add a die
  to the fee check. If Adrian takes the pistol, Tom notices it.
- Tom's knock, the job, and a visible Eloquence dice check to push the fee.
  The fee choice is timed: if the bar runs out, Adrian takes the twenty.
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
| `scenes/office/` | The office scene, the room art, furniture boxes and figures. |
| `core/iso.gd` | Converts floor tiles to screen positions for the isometric camera. |
| `ui/dialogue_layer.gd` | Captions, speech boxes, choices (with optional timer) and dice checks. |
| `ui/hud.gd`, `ui/dossier.gd` | Adrian's HUD card and the full character card. |
| `art/portraits/` | Placeholder portraits cropped from the character cards. |
| `art/fonts/` | Limelight, Playfair Display and Courier Prime (free fonts, licences included). |

## Tests

```
godot --headless res://tests/run_tests.tscn
```

This checks the dice odds over 10,000 rolls, the character sheets, the
autosave, plays the whole office from the first object to the end card,
checks that Adrian walks round the desk, and that the coat gives him the knife.
