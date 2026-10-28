class_name CharacterSheet
extends Resource
## One character's skills, perks and flaw. Skills are rated out of 10;
## each die in a check succeeds with a 10% chance per point.

@export var display_name := ""
@export var skills: Dictionary = {}
@export var perks: Array[String] = []
@export var flaw := ""


func get_skill(skill: String) -> int:
	return int(skills.get(skill, 0))
