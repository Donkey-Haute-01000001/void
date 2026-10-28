class_name Hud
extends CanvasLayer
## Adrian's on-screen card: portrait, Health, Sanity and what he carries,
## plus the objective in the corner. Hidden during cinematics.

const PORTRAIT := preload("res://art/portraits/adrian.png")
const PORTRAIT_SHADER := preload("res://ui/portrait.gdshader")

var _root: Control
var _health_fill: ColorRect
var _health_text: Label
var _sanity_fill: ColorRect
var _sanity_text: Label
var _items: HBoxContainer
var _objective: Label
var _pips: HBoxContainer

const BAR_WIDTH := 300.0


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_build_card()
	_build_objective()
	var key := Noir.label("C  ·  DOSSIER", Noir.TITLE_FONT, 26, Noir.DIM)
	key.position = Vector2(1740, 34)
	_root.add_child(key)
	refresh()


func show_hud(on: bool, instant := false) -> void:
	var target := 1.0 if on else 0.0
	if instant or GameState.test_mode:
		_root.modulate.a = target
		return
	create_tween().tween_property(_root, "modulate:a", target, 0.4)


func set_objective(text: String, left: int, total: int) -> void:
	_objective.text = text
	_objective.visible = text != ""
	for c in _pips.get_children():
		c.queue_free()
	for i in total:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(18, 18)
		pip.color = Noir.AMBER if i < left else Color(1, 1, 1, 0.15)
		_pips.add_child(pip)


func refresh() -> void:
	var h := float(GameState.health) / GameState.max_health()
	var s := float(GameState.sanity) / GameState.max_sanity()
	_health_fill.size.x = BAR_WIDTH * h
	_sanity_fill.size.x = BAR_WIDTH * s
	_health_text.text = "HEALTH  %d / %d" % [GameState.health, GameState.max_health()]
	_sanity_text.text = "SANITY  %d / %d" % [GameState.sanity, GameState.max_sanity()]
	for c in _items.get_children():
		c.queue_free()
	for item in GameState.items():
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", Noir.box(Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.25), 6))
		tag.add_child(Noir.label(item.to_upper(), Noir.TITLE_FONT, 22, Noir.PAPER))
		_items.add_child(tag)


func _build_card() -> void:
	var card := Control.new()
	card.position = Vector2(36, 836)
	_root.add_child(card)

	var frame := ColorRect.new()
	frame.color = Color(1, 1, 1, 0.8)
	frame.size = Vector2(170, 210)
	frame.position = Vector2(-4, -4)
	card.add_child(frame)
	var photo := TextureRect.new()
	photo.texture = PORTRAIT
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	photo.size = Vector2(162, 202)
	var mat := ShaderMaterial.new()
	mat.shader = PORTRAIT_SHADER
	photo.material = mat
	card.add_child(photo)
	frame.rotation = deg_to_rad(-2)
	photo.rotation = deg_to_rad(-2)

	var title := Noir.label("ADRIAN VALE", Noir.TITLE_FONT, 54, Noir.PAPER)
	title.position = Vector2(190, 0)
	card.add_child(title)
	var role := Noir.label("PRIVATE INVESTIGATOR", Noir.BODY_FONT, 18, Noir.DIM)
	role.position = Vector2(192, 56)
	card.add_child(role)

	var bars := [
		[Vector2(192, 92), Noir.BLOOD],
		[Vector2(192, 132), Noir.SANITY],
	]
	for i in 2:
		var back := ColorRect.new()
		back.color = Color(1, 1, 1, 0.1)
		back.position = bars[i][0] + Vector2(0, 26)
		back.size = Vector2(BAR_WIDTH, 8)
		card.add_child(back)
		var fill := ColorRect.new()
		fill.color = bars[i][1]
		fill.position = back.position
		fill.size = Vector2(BAR_WIDTH, 8)
		card.add_child(fill)
		var text := Noir.label("", Noir.TITLE_FONT, 24, bars[i][1].lightened(0.3))
		text.position = bars[i][0] - Vector2(0, 4)
		card.add_child(text)
		if i == 0:
			_health_fill = fill
			_health_text = text
		else:
			_sanity_fill = fill
			_sanity_text = text

	_items = HBoxContainer.new()
	_items.position = Vector2(192, 172)
	_items.add_theme_constant_override("separation", 8)
	card.add_child(_items)


func _build_objective() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(40, 30)
	box.add_theme_constant_override("separation", 8)
	_root.add_child(box)
	_objective = Noir.label("", Noir.TITLE_FONT, 34, Noir.AMBER)
	box.add_child(_objective)
	_pips = HBoxContainer.new()
	_pips.add_theme_constant_override("separation", 8)
	box.add_child(_pips)
