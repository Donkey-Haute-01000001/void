class_name DialogueLayer
extends CanvasLayer
## Katana Zero-style text. The narrator types out as a caption in the lower
## third; characters speak in black boxes over their heads. Lines support
## BBCode such as [shake], [wave] and [color]. Choices can carry a timer.
## In test mode nothing waits and choices return the test pick.

signal _advanced
signal _picked(index: int)

const TYPE_SPEED := 55.0  # characters per second
const BUBBLE_WIDTH := 560.0
const HEAD_OFFSET := Vector2(0, -250)

## Speaker id -> the Node2D their bubble floats over.
var speakers: Dictionary = {}
var lines: Dictionary = {}

var _vo := AudioStreamPlayer.new()
var _mode := ""  # "", "typing" or "wait"
var _type_tween: Tween
var _current: RichTextLabel
var _caption: PanelContainer
var _caption_text: RichTextLabel
var _bubble: PanelContainer
var _bubble_name: Label
var _bubble_text: RichTextLabel
var _tail: Polygon2D
var _bubble_owner: Node2D
var _hint: Label


func _ready() -> void:
	layer = 30
	add_child(_vo)
	_build_caption()
	_build_bubble()
	_hint = Noir.label("▸", Noir.TITLE_FONT, 34, Noir.AMBER)
	_hint.visible = false
	add_child(_hint)


func load_script(path: String) -> void:
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	lines = data["lines"] if data is Dictionary else {}


## Show a scripted line by id and wait for the player to move on.
func say(id: String) -> void:
	var line: Dictionary = lines.get(id, {"speaker": "narrator", "text": "[missing line: %s]" % id})
	await say_text(line["speaker"], line["text"], id)


func say_text(speaker: String, text: String, vo_id := "") -> void:
	_play_vo(vo_id)
	if GameState.test_mode:
		return
	if speaker == "narrator" or not speakers.has(speaker):
		await _show_caption(text)
	else:
		await _show_bubble(speaker, text)


## Offer choices. A timeout above zero runs a shrinking bar; when it empties
## the default option is taken.
func choose(options: Array, test_pick := 0, timeout := 0.0, default_pick := 0) -> int:
	if GameState.test_mode:
		return test_pick
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	root.position = Vector2(560, 0)
	root.custom_minimum_size.x = 800
	add_child(root)

	var bar := ColorRect.new()
	bar.color = Noir.BLOOD
	bar.custom_minimum_size = Vector2(800, 6)
	bar.visible = timeout > 0.0
	root.add_child(bar)

	for i in options.size():
		var b := Button.new()
		b.text = "%d   %s" % [i + 1, options[i]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", Noir.SPEECH_FONT)
		b.add_theme_font_size_override("font_size", 28)
		b.add_theme_color_override("font_color", Noir.PAPER)
		b.add_theme_color_override("font_hover_color", Noir.AMBER)
		b.add_theme_color_override("font_focus_color", Noir.AMBER)
		b.add_theme_stylebox_override("normal", Noir.box(Color(0.02, 0.02, 0.03, 0.9), Color(1, 1, 1, 0.12), 14))
		b.add_theme_stylebox_override("hover", Noir.box(Color(0.06, 0.05, 0.03, 0.95), Noir.AMBER, 14))
		b.add_theme_stylebox_override("focus", Noir.box(Color(0.06, 0.05, 0.03, 0.95), Noir.AMBER, 14))
		b.add_theme_stylebox_override("pressed", Noir.box(Color(0.1, 0.08, 0.04, 0.95), Noir.AMBER, 14))
		b.pressed.connect(func(): _picked.emit(i))
		root.add_child(b)
		b.modulate.a = 0.0
		var t := create_tween()
		t.tween_interval(0.06 * i)
		t.tween_property(b, "modulate:a", 1.0, 0.15)

	await get_tree().process_frame
	root.position.y = 950 - root.size.y

	var timer: Tween
	if timeout > 0.0:
		timer = create_tween()
		timer.tween_property(bar, "custom_minimum_size:x", 0.0, timeout)
		timer.tween_callback(func(): _picked.emit(default_pick))
	_mode = "choose"
	var pick: int = await _picked
	_mode = ""
	if timer:
		timer.kill()
	root.queue_free()
	return pick


## A dice check made visible: each die lands, then the verdict stamps down.
func show_check(skill_name: String, result) -> void:
	if GameState.test_mode:
		return
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Noir.box(Color(0.01, 0.01, 0.015, 0.95), Noir.AMBER, 34))
	add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	var title := Noir.label(skill_name.to_upper(), Noir.TITLE_FONT, 64, Noir.AMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var rule := Noir.label("%d dice · each lands on %d or under · need %d" % [result.dice, result.skill, result.needed],
		Noir.BODY_FONT, 22, Noir.DIM)
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(rule)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	col.add_child(row)
	var stamp := Noir.label("SUCCESS" if result.passed else "FAILURE", Noir.TITLE_FONT, 110,
		Noir.AMBER if result.passed else Noir.BLOOD)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.modulate.a = 0.0
	col.add_child(stamp)

	await get_tree().process_frame
	panel.position = (Vector2(1920, 1080) - panel.size) * 0.5 - Vector2(0, 80)

	for r in result.rolls:
		var hit: bool = r <= result.skill
		var die := PanelContainer.new()
		die.custom_minimum_size = Vector2(96, 96)
		die.add_theme_stylebox_override("panel", Noir.box(
			Noir.AMBER if hit else Color(0.08, 0.08, 0.09), Noir.AMBER if hit else Color(1, 1, 1, 0.2), 0))
		var n := Noir.label(str(r), Noir.TITLE_FONT, 64, Noir.INK if hit else Noir.DIM)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		die.add_child(n)
		row.add_child(die)
		die.pivot_offset = Vector2(48, 48)
		die.scale = Vector2(1.6, 1.6)
		var t := create_tween()
		t.tween_property(die, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(0.35).timeout

	await get_tree().process_frame
	stamp.pivot_offset = stamp.size * 0.5
	stamp.rotation = deg_to_rad(-6)
	stamp.scale = Vector2(2.4, 2.4)
	var s := create_tween().set_parallel()
	s.tween_property(stamp, "scale", Vector2.ONE, 0.16).set_ease(Tween.EASE_IN)
	s.tween_property(stamp, "modulate:a", 1.0, 0.12)
	await s.finished
	_shake(panel)
	await _wait_for_advance()
	panel.queue_free()


# --- Captions and bubbles ---------------------------------------------------

func _show_caption(text: String) -> void:
	_caption_text.text = "[center]%s[/center]" % text
	_caption.size = Vector2.ZERO
	_caption.visible = true
	await get_tree().process_frame
	# Bottom centre, clear of the cinema bars and of the HUD card on the left.
	_caption.position = Vector2(1060 - _caption.size.x * 0.5, 950 - _caption.size.y)
	await _type(_caption_text)
	_caption.visible = false


func _show_bubble(speaker: String, text: String) -> void:
	_bubble_owner = speakers[speaker]
	_bubble_name.text = Noir.SPEAKER_NAMES.get(speaker, speaker.to_upper())
	_bubble_name.add_theme_color_override("font_color", Noir.SPEAKER_COLORS.get(speaker, Noir.PAPER))
	_bubble_text.text = text
	_bubble.size = Vector2.ZERO
	_bubble.visible = true
	_tail.visible = true
	_bubble.modulate.a = 0.0
	await get_tree().process_frame
	_place_bubble()
	create_tween().tween_property(_bubble, "modulate:a", 1.0, 0.1)
	await _type(_bubble_text)
	_bubble.visible = false
	_tail.visible = false
	_bubble_owner = null


func _process(_delta: float) -> void:
	if _bubble_owner and _bubble.visible:
		_place_bubble()
	_hint.visible = _mode == "wait" and (_bubble.visible or _caption.visible)
	if _hint.visible:
		var target: Control = _bubble if _bubble.visible else _caption
		_hint.position = target.position + target.size - Vector2(30, 46)
		_hint.modulate.a = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.008)


func _place_bubble() -> void:
	var head := _bubble_owner.get_global_transform_with_canvas().origin + HEAD_OFFSET
	var pos := head - Vector2(_bubble.size.x * 0.5, _bubble.size.y)
	pos.x = clampf(pos.x, 24, 1920 - 24 - _bubble.size.x)
	pos.y = clampf(pos.y, 24, 1080 - 24 - _bubble.size.y)
	_bubble.position = pos
	var tip_x := clampf(head.x, pos.x + 24, pos.x + _bubble.size.x - 24)
	var base_y := pos.y + _bubble.size.y - 2
	_tail.polygon = PackedVector2Array([
		Vector2(tip_x - 14, base_y), Vector2(tip_x + 14, base_y), Vector2(tip_x, base_y + 26)])


func _type(label: RichTextLabel) -> void:
	_current = label
	label.visible_characters = 0
	var total := label.get_total_character_count()
	_mode = "typing"
	_type_tween = create_tween()
	_type_tween.tween_property(label, "visible_characters", total, total / TYPE_SPEED)
	_type_tween.tween_callback(func(): if _mode == "typing": _mode = "wait")
	await _wait_for_advance()


func _wait_for_advance() -> void:
	if _mode != "typing":
		_mode = "wait"
	await _advanced
	_mode = ""


func _input(event: InputEvent) -> void:
	if _mode != "typing" and _mode != "wait":
		if _mode == "choose" and event is InputEventKey and event.pressed:
			var n: int = event.keycode - KEY_1
			if n >= 0 and n < 9:
				_picked.emit(n)
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not (click or event.is_action_pressed("ui_accept")):
		return
	get_viewport().set_input_as_handled()
	if _mode == "typing":
		_type_tween.kill()
		_current.visible_characters = -1
		_mode = "wait"
	else:
		_advanced.emit()


func _play_vo(vo_id: String) -> void:
	var path := "res://audio/vo/%s.ogg" % vo_id
	if vo_id != "" and ResourceLoader.exists(path):
		_vo.stream = load(path)
		_vo.play()


func _shake(node: Control) -> void:
	var home := node.position
	var t := create_tween()
	for i in 6:
		t.tween_property(node, "position", home + Vector2(randf_range(-10, 10), randf_range(-6, 6)), 0.03)
	t.tween_property(node, "position", home, 0.03)


func _build_caption() -> void:
	_caption = PanelContainer.new()
	var style := Noir.box(Color(0, 0, 0, 0.78), Color(0, 0, 0, 0), 26)
	style.content_margin_left = 60
	style.content_margin_right = 60
	_caption.add_theme_stylebox_override("panel", style)
	_caption.custom_minimum_size.x = 1040
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.visible = false
	_caption_text = Noir.rich(Noir.NARRATOR_FONT, 34, Noir.PAPER)
	_caption_text.custom_minimum_size.x = 920
	_caption.add_child(_caption_text)
	add_child(_caption)


func _build_bubble() -> void:
	_tail = Polygon2D.new()
	_tail.color = Color(0.01, 0.01, 0.015)
	_tail.visible = false
	add_child(_tail)
	_bubble = PanelContainer.new()
	_bubble.add_theme_stylebox_override("panel", Noir.box(Color(0.01, 0.01, 0.015, 1.0), Color(1, 1, 1, 0.85), 20))
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bubble.visible = false
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	_bubble.add_child(col)
	_bubble_name = Noir.label("", Noir.TITLE_FONT, 30, Noir.AMBER)
	col.add_child(_bubble_name)
	_bubble_text = Noir.rich(Noir.SPEECH_FONT, 30, Noir.PAPER)
	_bubble_text.custom_minimum_size.x = BUBBLE_WIDTH
	col.add_child(_bubble_text)
	add_child(_bubble)
