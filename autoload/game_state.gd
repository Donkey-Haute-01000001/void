extends Node
## Everything the run remembers. Saved to disk by SaveSystem.

const MAX_EXAMINE := 3
const ADRIAN := preload("res://data/characters/adrian.tres")

## Where the office scene resumes: "start", "knock" or "office_done".
var checkpoint := "start"
## Objects examined in the opening, in order.
var examined: Array[String] = []
## Story flags, such as "has_pistol". Later scenes read these for payoffs.
var flags: Dictionary = {}
var fee_per_day := 0
## Health and Sanity are separate tracks. [Proposal] Max health is 8 + Strength,
## max sanity is 6 + 2 x Willpower.
var health := 0
var sanity := 0
## Skips waiting and animation. Only the test runner turns this on.
var test_mode := false


func _ready() -> void:
	reset()


func reset() -> void:
	checkpoint = "start"
	examined.clear()
	flags.clear()
	fee_per_day = 0
	health = max_health()
	sanity = max_sanity()


func max_health() -> int:
	return 8 + ADRIAN.get_skill("strength")


func max_sanity() -> int:
	return 6 + 2 * ADRIAN.get_skill("willpower")


## What Adrian is carrying, for the HUD.
func items() -> Array[String]:
	var list: Array[String] = []
	if has_flag("has_knife"):
		list.append("Folding knife")
	if has_flag("has_pistol"):
		list.append("Pistol")
	return list


func has_examined(id: String) -> bool:
	return examined.has(id)


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func to_dict() -> Dictionary:
	return {
		"checkpoint": checkpoint,
		"examined": examined.duplicate(),
		"flags": flags.duplicate(),
		"fee_per_day": fee_per_day,
		"health": health,
		"sanity": sanity,
	}


func from_dict(data: Dictionary) -> void:
	reset()
	checkpoint = str(data.get("checkpoint", "start"))
	for id in data.get("examined", []):
		examined.append(str(id))
	flags = data.get("flags", {}).duplicate()
	fee_per_day = int(data.get("fee_per_day", 0))
	health = int(data.get("health", max_health()))
	sanity = int(data.get("sanity", max_sanity()))
