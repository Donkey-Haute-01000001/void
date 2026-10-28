extends Control
## Title screen: new game, continue from the autosave, or quit.

const OFFICE := "res://scenes/office/office.tscn"

@onready var _continue: Button = %Continue


func _ready() -> void:
	_continue.disabled = not SaveSystem.has_save()
	%NewGame.pressed.connect(_on_new_game)
	_continue.pressed.connect(_on_continue)
	%Quit.pressed.connect(func(): get_tree().quit())
	# Test scene for the inner voices, until they appear in the story.
	var demo := Button.new()
	demo.text = "Voice demo (test)"
	demo.pressed.connect(_on_voice_demo)
	%Quit.get_parent().add_child(demo)
	%Quit.get_parent().move_child(demo, %Quit.get_index())


func _on_new_game() -> void:
	GameState.reset()
	get_tree().change_scene_to_file(OFFICE)


func _on_continue() -> void:
	if SaveSystem.load_save():
		get_tree().change_scene_to_file(OFFICE)


func _on_voice_demo() -> void:
	GameState.reset()
	GameState.checkpoint = "voice_demo"
	get_tree().change_scene_to_file(OFFICE)
