class_name DialogueLayer
extends CanvasLayer
## All text lives in one panel at the bottom centre, always in the same spot:
## narration, speech and inner voices (Adrian's skills talking). When a line
## ends in a choice, the options replace the text inside that same panel.
## Lines support BBCode such as [shake], [wave] and [color]. Script lines
## with speaker "voice:<skill>" are inner voices.
## In test mode nothing waits and choices return the test pick.

## Asks the room to shake by this many pixels (dice landings, verdicts).
signal impact(strength: float)
signal _advanced
signal _picked(index: int)

const TYPE_SPEED := 55.0  # characters per second
## The panel sits centred here, clear of the HUD card on the left, with its
## bottom edge just above the cinema bars.
const PANEL_CENTER_X := 1060.0
const PANEL_BOTTOM := 950.0
const PANEL_WIDTH := 1160.0
const TEXT_SIZE := 36
const VOICE_COLOR := Color("#c8c8c8")

## Speaker id -> their Node2D in the room. Anyone listed here talks as a
## character; everyone else reads as narration.
var speakers: Dictionary = {}
var lines: Dictionary = {}
## Whose skills the inner voices speak for.
var sheet: CharacterSheet

var _vo := AudioStreamPlayer.new()
var _mode := ""  # "", "typing", "wait" or "choose"
var _type_tween: Tween
var _panel: PanelContainer
var _tag: Label
var _body: RichTextLabel
var _choices: VBoxContainer
var _hint: Label


func _ready() -> void:
	layer = 30
	add_child(_vo)
	_build_panel()
	_hint = Noir.label("▸", Noir.TITLE_FONT, 34, Noir.ACCENT)
	_hint.visible = false
	add_child(_hint)


## Load a script file's lines. Later files add to (and override) earlier ones.
func load_script(path: String) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		lines.merge(data["lines"], true)


## Show a scripted line by id and wait for the player to move on. `note`
## is added to an inner voice's tag, such as "NOTICED".
func say(id: String, note := "") -> void:
	var line: Dictionary = lines.get(id, {"speaker": "narrator", "text": "[missing line: %s]" % id})
	await say_text(line["speaker"], line["text"], id, note)


func say_text(speaker: String, text: String, vo_id := "", note := "") -> void:
	_play_vo(vo_id)
	if GameState.test_mode:
		return
	if speaker.begins_with("voice:"):
		var skill := speaker.trim_prefix("voice:")
		var tag := "%s · %d" % [skill.to_upper(), _skill(skill)] + ("   ·   " + note if note != "" else "")
		_style(tag, Noir.BLOOD, Noir.VOICE_FONT, VOICE_COLOR)
		_body.text = "[i]%s[/i]" % text
	elif speakers.has(speaker):
		_style(Noir.SPEAKER_NAMES.get(speaker, speaker.to_upper()), Noir.SPEAKER_COLORS.get(speaker, Noir.PAPER), Noir.SPEECH_FONT, Noir.PAPER)
		_body.text = text
	else:
		_style("", Noir.PAPER, Noir.NARRATOR_FONT, Noir.PAPER)
		_body.text = text
	_body.visible = true
	await _open_panel()
	await _type()
	_panel.visible = false


## A notice roll: a hidden one-die roll on the skill, made harder by
## `difficulty`. If it lands, the voice says line `id` and the scene can
## unlock that skill's choice. Returns whether it spoke.
func passive(skill: String, difficulty: int, id: String) -> bool:
	var result = Dice.roll(maxi(_skill(skill) - difficulty, 0), 1, 1)
	if result.passed:
		await say(id, "NOTICED")
	return result.passed


## A choice a skill unlocked. Picking it means trying it: see `attempt`.
func skill_option(skill: String, text: String, dice := 2, needed := 1) -> Dictionary:
	return {"text": text, "skill": skill, "dice": dice, "needed": needed}


## The odds of a skill option passing, 0 to 100.
func odds(option: Dictionary) -> int:
	return roundi(Dice.odds(_skill(option["skill"]), option["dice"], option["needed"]) * 100.0)


## Try a skill option: the visible dice roll. Returns whether it passed.
func attempt(option: Dictionary) -> bool:
	var result = Dice.roll(_skill(option["skill"]), option["dice"], option["needed"])
	await show_check(String(option["skill"]).capitalize(), result)
	return result.passed


## Offer choices in the panel. Each option is plain text or a skill option
## (a Dictionary from `skill_option`), which shows its skill and odds.
func choose(options: Array, test_pick := 0) -> int:
	if GameState.test_mode:
		return test_pick
	_style("", Noir.PAPER, Noir.SPEECH_FONT, Noir.PAPER)
	_body.visible = false
	for i in options.size():
		var row := _option_row(i, options[i])
		_choices.add_child(row)
		row.modulate.a = 0.0
		var t := create_tween()
		t.tween_interval(0.06 * i)
		t.tween_property(row, "modulate:a", 1.0, 0.15)
	_choices.visible = true
	await _open_panel()
	_mode = "choose"
	var pick: int = await _picked
	_mode = ""
	_panel.visible = false
	_choices.visible = false
	for row in _choices.get_children():
		_choices.remove_child(row)
		row.queue_free()
	return pick


## A dice check made visible: see DiceRoll. `impact` asks the room to shake.
func show_check(skill_name: String, result) -> void:
	if GameState.test_mode:
		return
	var roll := DiceRoll.new()
	add_child(roll)
	roll.impact.connect(func(strength: float): impact.emit(strength))
	await roll.play(skill_name, result)
	roll.queue_free()


# --- The panel ---------------------------------------------------------------

func _skill(skill: String) -> int:
	return sheet.get_skill(skill) if sheet else 0


func _style(tag: String, tag_color: Color, font: Font, color: Color) -> void:
	_tag.text = tag
	_tag.visible = tag != ""
	_tag.add_theme_color_override("font_color", tag_color)
	_body.add_theme_font_override("normal_font", font)
	_body.add_theme_color_override("default_color", color)


## Size the panel to its contents, pin it to the bottom centre, fade it in.
func _open_panel() -> void:
	_panel.size = Vector2.ZERO
	_panel.modulate.a = 0.0
	_panel.visible = true
	await get_tree().process_frame
	_panel.position = Vector2(PANEL_CENTER_X - _panel.size.x * 0.5, PANEL_BOTTOM - _panel.size.y)
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.12)


func _option_row(index: int, option: Variant) -> PanelContainer:
	var row := PanelContainer.new()
	var normal := Noir.box(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 10)
	var hover := Noir.box(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 10)
	row.add_theme_stylebox_override("panel", normal)
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.mouse_entered.connect(func(): row.add_theme_stylebox_override("panel", hover))
	row.mouse_exited.connect(func(): row.add_theme_stylebox_override("panel", normal))
	row.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_picked.emit(index))
	var line := Noir.rich(Noir.SPEECH_FONT, TEXT_SIZE, Noir.PAPER)
	line.add_theme_font_size_override("bold_font_size", TEXT_SIZE + 4)
	var red := Noir.BLOOD.to_html(false)
	var text := "[color=#%s][b]%d[/b][/color]    " % [red, index + 1]
	if option is Dictionary:
		text += "[color=#%s][b][lb]%s %d%%[rb][/b][/color]  %s" % [red, String(option["skill"]).to_upper(), odds(option), option["text"]]
	else:
		text += str(option)
	line.text = text
	line.custom_minimum_size.x = PANEL_WIDTH - 100
	row.add_child(line)
	return row


func _process(_delta: float) -> void:
	_hint.visible = _mode == "wait" and _panel.visible
	if _hint.visible:
		_hint.position = _panel.position + _panel.size - Vector2(34, 50)
		_hint.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)


func _type() -> void:
	_body.visible_characters = 0
	var total := _body.get_total_character_count()
	_mode = "typing"
	_type_tween = create_tween()
	_type_tween.tween_property(_body, "visible_characters", total, total / TYPE_SPEED)
	_type_tween.tween_callback(func(): if _mode == "typing": _mode = "wait")
	await _advanced
	_mode = ""


func _input(event: InputEvent) -> void:
	if _mode == "choose":
		if event is InputEventKey and event.pressed:
			var n: int = event.keycode - KEY_1
			if n >= 0 and n < _choices.get_child_count():
				_picked.emit(n)
		return
	if _mode != "typing" and _mode != "wait":
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not (click or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _mode == "typing":
		_type_tween.kill()
		_body.visible_characters = -1
		_mode = "wait"
	else:
		_advanced.emit()


func _play_vo(vo_id: String) -> void:
	var path := "res://audio/vo/%s.ogg" % vo_id
	if vo_id != "" and ResourceLoader.exists(path):
		_vo.stream = load(path)
		_vo.play()


func _build_panel() -> void:
	_panel = PanelContainer.new()
	var style := Noir.box(Color(0, 0, 0, 0.86), Color(1, 1, 1, 0.12), 26)
	style.content_margin_left = 40
	style.content_margin_right = 40
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size.x = PANEL_WIDTH
	_panel.visible = false
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	_panel.add_child(col)
	_tag = Noir.label("", Noir.TITLE_FONT, 34, Noir.PAPER)
	col.add_child(_tag)
	_body = Noir.rich(Noir.NARRATOR_FONT, TEXT_SIZE, Noir.PAPER)
	_body.add_theme_font_override("italics_font", Noir.VOICE_FONT)
	_body.add_theme_font_size_override("italics_font_size", TEXT_SIZE)
	_body.custom_minimum_size.x = PANEL_WIDTH - 80
	col.add_child(_body)
	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 2)
	_choices.visible = false
	col.add_child(_choices)
	add_child(_panel)
