class_name StoryPanel
extends CanvasLayer
## The Disco Elysium-style column on the right: narration, dialogue, choices
## and dice checks scroll down it like a log.

signal _advanced
signal _chosen(index: int)

const WIDTH := 600
const TEXT_SIZE := 23
const SECONDS_PER_CHAR := 0.018
const SPEAKERS := {
	"tom": {"name": "GARRITY", "color": "#c9a26b"},
	"adrian": {"name": "VALE", "color": "#9fb7c9"},
}

var lines: Dictionary = {}
var _scroll: ScrollContainer
var _log: VBoxContainer
var _choices: VBoxContainer
var _hint: Label
var _vo := AudioStreamPlayer.new()
var _typing: RichTextLabel
var _tween: Tween
var _waiting := false


func _ready() -> void:
	layer = 10
	add_child(_vo)
	_build()


func load_script(path: String) -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	lines = data["lines"]


## Show one scripted line and wait for the player to click on.
func say(id: String) -> void:
	if not lines.has(id):
		push_error("Missing script line: %s" % id)
		return
	var entry: Dictionary = lines[id]
	await say_text(str(entry.get("speaker", "narrator")), str(entry["text"]), id)


func say_text(speaker: String, text: String, vo_id := "") -> void:
	var label := _add_entry(_format(speaker, text))
	_play_vo(vo_id)
	if GameState.test_mode:
		return
	_typing = label
	label.visible_ratio = 0.0
	_tween = create_tween()
	_tween.tween_property(label, "visible_ratio", 1.0, text.length() * SECONDS_PER_CHAR)
	_waiting = true
	_hint.visible = true
	await _advanced
	_waiting = false
	_hint.visible = false
	_typing = null


## Offer numbered options and return the index the player picks.
## In test mode the first option is always taken unless `test_pick` says otherwise.
func choose(options: Array, test_pick := 0) -> int:
	_clear_choices()
	if GameState.test_mode:
		return test_pick
	for i in options.size():
		var button := Button.new()
		button.text = "%d. %s" % [i + 1, options[i]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.flat = true
		button.add_theme_font_size_override("font_size", TEXT_SIZE)
		button.add_theme_color_override("font_color", Color("#d9a441"))
		button.add_theme_color_override("font_hover_color", Color("#f3d08a"))
		button.pressed.connect(func(): _chosen.emit(i))
		_choices.add_child(button)
	_scroll_to_end()
	var picked: int = await _chosen
	_clear_choices()
	return picked


## Print a dice check: the odds, each die, and the outcome.
func show_check(skill_name: String, result: Dice.CheckResult) -> void:
	var faces := ""
	for face in result.rolls:
		var color := "#8fbf8f" if face <= result.skill else "#a05a52"
		faces += "[color=%s][%d][/color] " % [color, face]
	var outcome := "[color=#8fbf8f]SUCCESS[/color]" if result.passed else "[color=#a05a52]FAILURE[/color]"
	var odds := roundi(Dice.odds(result.skill, result.dice, result.needed) * 100.0)
	_add_entry("[color=#7d8a8f][%s %d · %d dice, need %d · %d%%][/color]\n%s %s" % [
		skill_name.to_upper(), result.skill, result.dice, result.needed, odds, faces, outcome])
	if not GameState.test_mode:
		await get_tree().create_timer(0.9).timeout


func _format(speaker: String, text: String) -> String:
	if SPEAKERS.has(speaker):
		var s: Dictionary = SPEAKERS[speaker]
		return "[color=%s]%s[/color] — %s" % [s["color"], s["name"], text]
	return "[color=#d8d2c4]%s[/color]" % text


func _add_entry(bbcode: String) -> RichTextLabel:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("normal_font_size", TEXT_SIZE)
	label.text = bbcode
	_log.add_child(label)
	_scroll_to_end()
	return label


func _play_vo(id: String) -> void:
	_vo.stop()
	if id == "":
		return
	var path := "res://audio/vo/%s.ogg" % id
	if ResourceLoader.exists(path):
		_vo.stream = load(path)
		_vo.play()


func _input(event: InputEvent) -> void:
	if not _waiting:
		return
	var clicked: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if clicked or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if _typing and _typing.visible_ratio < 1.0:
			_tween.kill()
			_typing.visible_ratio = 1.0
		else:
			_advanced.emit()


func _clear_choices() -> void:
	for child in _choices.get_children():
		child.queue_free()


func _scroll_to_end() -> void:
	await get_tree().process_frame
	if is_instance_valid(_scroll):
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)


func _build() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -WIDTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.035, 0.04, 0.96)
	style.border_color = Color("#2a2724")
	style.border_width_left = 2
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 40
	style.content_margin_bottom = 28
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)

	_log = VBoxContainer.new()
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.add_theme_constant_override("separation", 18)
	_scroll.add_child(_log)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 6)
	column.add_child(_choices)

	_hint = Label.new()
	_hint.text = "Click to continue"
	_hint.add_theme_color_override("font_color", Color("#5b5750"))
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.visible = false
	column.add_child(_hint)
