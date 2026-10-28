extends Control
## Title screen: new game, continue from the autosave, or quit.

const OFFICE := "res://scenes/office/office.tscn"

@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.disabled = not SaveSystem.has_save()
	%NewGame.pressed.connect(_on_new_game)
	_continue.pressed.connect(_on_continue)
	%Quit.pressed.connect(func(): get_tree().quit())


func _on_new_game() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(OFFICE)


func _on_continue() -> void:
	if SaveSystem.load_save():
		get_tree().change_scene_to_file(OFFICE)
