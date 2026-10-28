class_name Dossier
extends CanvasLayer
## The character card: a freeze-frame that introduces Adrian with his
## portrait, skills, perks and flaw. Opens once in the intro and on C.

const SHEET := preload("res://data/characters/adrian.tres")
const PORTRAIT := preload("res://art/portraits/adrian.png")
const PORTRAIT_SHADER := preload("res://ui/portrait.gdshader")
const TIERS := [["STRONG", 10], ["AVERAGE", 8], ["POOR", 6]]
## Names chosen by Vishnu; the effects are proposals until the perk rules exist.
const NOTES := {
	"Silver Tongue": "+1 die on Eloquence checks to calm or persuade someone.",
	"Fast Hands": "+1 die on lockpicking, pickpocketing and sleight of hand.",
	"Poor Self-Esteem": "Takes it to heart. Loses extra Sanity when belittled or blamed.",
}

signal _closed

var is_open := false
var _root: Control


func _ready() -> void:
	layer = 40
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	add_child(_root)
	_build()


## Show the card and wait for a click. `intro` plays the slam-in.
func present(intro := false) -> void:
	if GameState.test_mode:
		return
	is_open = true
	_root.visible = true
	_root.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_root, "modulate:a", 1.0, 0.5 if intro else 0.15)
	if intro:
		var title: Control = _root.get_node("Title")
		title.scale = Vector2(1.8, 1.8)
		title.modulate.a = 0.0
		t.tween_property(title, "scale", Vector2.ONE, 0.18).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(title, "modulate:a", 1.0, 0.1)
	await _closed
	var out := create_tween()
	out.tween_property(_root, "modulate:a", 0.0, 0.25)
	await out.finished
	_root.visible = false
	is_open = false


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	var key: bool = event is InputEventKey and event.pressed and not event.echo
	if click or key:
		get_viewport().set_input_as_handled()
		_closed.emit()


func _build() -> void:
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.0, 0.97)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)

	# A slash of red behind the photo: the one colour in a black and white world.
	var slash := Polygon2D.new()
	slash.color = Noir.BLOOD
	slash.polygon = PackedVector2Array([Vector2(0, 180), Vector2(760, 120), Vector2(700, 900), Vector2(0, 960)])
	_root.add_child(slash)

	var frame := ColorRect.new()
	frame.color = Noir.PAPER
	frame.position = Vector2(150, 190)
	frame.size = Vector2(460, 570)
	frame.rotation = deg_to_rad(-3)
	_root.add_child(frame)
	var photo := TextureRect.new()
	photo.texture = PORTRAIT
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.position = Vector2(14, 14)
	photo.size = Vector2(432, 500)
	var mat := ShaderMaterial.new()
	mat.shader = PORTRAIT_SHADER
	photo.material = mat
	frame.add_child(photo)
	var caption := Noir.label("A. VALE  ·  FEB. 1939", Noir.NARRATOR_FONT, 24, Noir.INK)
	caption.position = Vector2(20, 522)
	frame.add_child(caption)

	var title := Noir.label("ADRIAN VALE", Noir.DISPLAY_FONT, 110, Noir.PAPER)
	title.name = "Title"
	title.position = Vector2(820, 90)
	title.pivot_offset = Vector2(300, 80)
	_root.add_child(title)
	var sub := Noir.label("PRIVATE INVESTIGATOR   ·   AGE 24   ·   WORCESTER, MASS.", Noir.TITLE_FONT, 40, Noir.SANITY)
	sub.position = Vector2(826, 228)
	_root.add_child(sub)

	# Skills in three tiers, highest first. Pips show the value; the outline
	# shows how high the tier lets that skill grow.
	var names: Array = SHEET.skills.keys()
	names.sort_custom(func(a, b): return SHEET.skills[a] > SHEET.skills[b])
	for tier in 3:
		var col := VBoxContainer.new()
		col.position = Vector2(826 + tier * 360, 310)
		col.add_theme_constant_override("separation", 4)
		_root.add_child(col)
		col.add_child(Noir.label(TIERS[tier][0], Noir.TITLE_FONT, 32, Noir.BLOOD))
		for i in 3:
			var skill: String = names[tier * 3 + i]
			var value: int = SHEET.skills[skill]
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 10)
			var lbl := Noir.label(skill.to_upper(), Noir.TITLE_FONT, 40, Noir.PAPER)
			lbl.custom_minimum_size.x = 210
			row.add_child(lbl)
			row.add_child(Noir.label(str(value), Noir.TITLE_FONT, 40, Noir.ACCENT))
			col.add_child(row)
			col.add_child(_pips(value, TIERS[tier][1]))
			var spacer := Control.new()
			spacer.custom_minimum_size.y = 8
			col.add_child(spacer)

	var traits := VBoxContainer.new()
	traits.position = Vector2(826, 712)
	traits.add_theme_constant_override("separation", 14)
	_root.add_child(traits)
	for perk in SHEET.perks:
		traits.add_child(_trait("PERK", perk, Noir.ACCENT))
	traits.add_child(_trait("FLAW", SHEET.flaw, Noir.BLOOD))

	var hint := Noir.label("CLICK TO CONTINUE", Noir.TITLE_FONT, 30, Noir.DIM)
	hint.position = Vector2(1680, 1010)
	_root.add_child(hint)


func _pips(value: int, cap: int) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	for i in 10:
		var pip := Panel.new()
		pip.custom_minimum_size = Vector2(24, 12)
		var style := StyleBoxFlat.new()
		if i < value:
			style.bg_color = Noir.ACCENT
		elif i < cap:
			style.bg_color = Color(0, 0, 0, 0)
			style.border_color = Color(1, 1, 1, 0.55)
			style.set_border_width_all(1)
		else:
			style.bg_color = Color(1, 1, 1, 0.08)
		pip.add_theme_stylebox_override("panel", style)
		row.add_child(pip)
	return row


## A perk or flaw: tag and name on one line, what it does underneath.
func _trait(kind: String, title: String, color: Color) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 0)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var tag := Noir.label(kind, Noir.TITLE_FONT, 28, Noir.INK)
	var tag_box := PanelContainer.new()
	var style := Noir.box(color, color, 2)
	style.content_margin_left = 10
	style.content_margin_right = 10
	tag_box.add_theme_stylebox_override("panel", style)
	tag_box.add_child(tag)
	row.add_child(tag_box)
	row.add_child(Noir.label(title.to_upper(), Noir.TITLE_FONT, 38, Noir.PAPER))
	block.add_child(row)
	var note := Noir.label(NOTES.get(title, ""), Noir.BODY_FONT, 24, Noir.SANITY)
	note.position.x = 0
	block.add_child(note)
	return block
