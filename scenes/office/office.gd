extends Node2D
## Case 1 opening: Adrian's office, in isometric. The player examines three of
## six objects, then Tom Garrity knocks with Wycliffe's job. All art is
## placeholder shapes; lighting, text and layout are the real thing.

const SCRIPT_PATH := "res://data/script/office.json"
const VOICE_DEMO_PATH := "res://data/script/voice_demo.json"
const ADRIAN_SHEET := preload("res://data/characters/adrian.tres")
const RoomArt := preload("res://scenes/office/room_art.gd")
const SCREEN_FX := preload("res://ui/screen_fx.gdshader")
const SIN_CITY := preload("res://ui/sin_city.gdshader")

const CELL := 0.25
const ADRIAN_START := Vector2(6.5, 1.4)
const DOOR_POINT := Vector2(0.35, 5.75)
const TOM_STAND := Vector2(2.0, 5.3)
const ADRIAN_TALK := Vector2(3.5, 4.5)

## The six things Adrian can look at before the knock. `stand` is where he
## walks to first, in floor tiles.
const HOTSPOTS := {
	"photo": {"label": "Sylvia's photograph", "stand": Vector2(4.4, 3.95)},
	"bills": {"label": "The unpaid bills", "stand": Vector2(4.9, 3.95)},
	"envelope": {"label": "Envelope for Worcester", "stand": Vector2(5.6, 3.95)},
	"pistol": {"label": "The bottom drawer", "stand": Vector2(5.4, 4.0)},
	"gin": {"label": "The filing cabinet", "stand": Vector2(1.2, 1.3)},
	"knife": {"label": "Coat on the rack", "stand": Vector2(0.9, 4.3)},
}
## Floor areas nothing can walk through: x, y, width, depth in tiles.
const BLOCKERS := [
	Rect2(3.4, 2.4, 2.6, 1.2),  # desk
	Rect2(4.35, 1.45, 0.7, 0.7),  # desk chair
	Rect2(2.0, 0.0, 1.4, 0.6),  # bookcase
	Rect2(7.0, 0.0, 1.9, 0.95),  # couch
	Rect2(6.55, 3.45, 0.28, 0.28),  # waste bin
	Rect2(4.2, 4.4, 0.7, 0.7),  # client chair
	Rect2(0.7, 0.0, 0.9, 0.85),  # filing cabinet
	Rect2(0.0, 3.85, 0.6, 0.55),  # coat rack
	Rect2(4.4, 0.0, 1.8, 0.3),  # radiator
]

var story: DialogueLayer
var hud: Hud
var dossier: Dossier
var adrian: Walker
var tom: Walker

var _busy := true
var _exploring := false
var _hover := ""
var _boxes := {}
var _stage: Node2D
var _world: Node2D
var _room: RoomArt
var _lamp: PointLight2D
var _window_light: PointLight2D
var _blinds: Node2D
var _grid := AStarGrid2D.new()
var _hover_label: Label
var _fade: ColorRect
var _bars: Array[ColorRect] = []
var _next_lightning := 6.0


func _ready() -> void:
	_build_stage()
	_build_grid()
	_build_screen_fx()

	story = DialogueLayer.new()
	add_child(story)
	story.load_script(SCRIPT_PATH)
	story.speakers = {"adrian": adrian, "tom": tom}
	story.sheet = ADRIAN_SHEET
	story.impact.connect(_shake)
	hud = Hud.new()
	add_child(hud)
	dossier = Dossier.new()
	add_child(dossier)

	Sfx.start_rain()
	match GameState.checkpoint:
		"voice_demo":
			hud.show_hud(false, true)
			_voice_demo()
		"knock":
			hud.show_hud(false, true)
			_knock_sequence()
		"office_done":
			hud.show_hud(false, true)
			_show_end_card()
		_:
			SaveSystem.autosave("start")
			_opening()


func _process(delta: float) -> void:
	if GameState.test_mode:
		return
	_blinds.queue_redraw()
	var t := Time.get_ticks_msec() * 0.001
	_lamp.energy = 1.35 + 0.05 * sin(t * 13.0) + 0.04 * sin(t * 3.1)
	_next_lightning -= delta
	if _next_lightning <= 0.0:
		_next_lightning = randf_range(9.0, 16.0)
		_lightning()


func _opening() -> void:
	hud.show_hud(false, true)
	_fade.color.a = 1.0
	_letterbox(true, true)
	adrian.place(ADRIAN_START)
	adrian.face_toward(Vector2(5.3, 0.0))
	await story.say("intro_1")
	await story.say("intro_2")
	if not GameState.test_mode:
		var t := create_tween()
		t.tween_property(_fade, "color:a", 0.0, 2.0)
		await t.finished
	await story.say("intro_3")
	await dossier.present(true)
	await story.say("intro_4")
	_letterbox(false)
	hud.show_hud(true)
	_update_objective()
	_exploring = true
	_busy = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hover(_hotspot_at(event.position) if _exploring and not _busy else "")
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_C and not _busy and not dossier.is_open:
		_busy = true
		await dossier.present()
		_busy = false
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _busy:
		return
	var hit := _hotspot_at(event.position) if _exploring else ""
	if hit != "":
		examine(hit)
	else:
		_walk(adrian, Iso.to_world(event.position))


## Walk to an object and look at it. Public so the test runner can drive it.
func examine(id: String) -> void:
	_busy = true
	_set_hover("")
	await _walk(adrian, HOTSPOTS[id]["stand"])
	adrian.face_toward(_box_floor(id))
	if GameState.has_examined(id):
		await story.say("already")
	elif GameState.examined.size() >= GameState.MAX_EXAMINE:
		await story.say("no_time")
	else:
		await _examine_lines(id)
		GameState.examined.append(id)
		_update_objective()
		_boxes[id].modulate = Color(0.75, 0.75, 0.75)
	if GameState.examined.size() >= GameState.MAX_EXAMINE:
		_exploring = false
		await _pause(0.8)
		await _knock_sequence()
	else:
		_busy = false


func _examine_lines(id: String) -> void:
	match id:
		"photo":
			await story.say("photo_1")
			await story.say("photo_2")
		"envelope":
			await story.say("envelope_1")
			await story.say("envelope_2")
		"pistol":
			await story.say("pistol_1")
			await story.say("pistol_2")
			var pick := await story.choose(["Take it.", "Leave it."], 1)
			if pick == 0:
				GameState.set_flag("has_pistol")
				hud.refresh()
				await story.say("pistol_take")
			else:
				await story.say("pistol_leave")
		"gin":
			await story.say("gin_1")
			await story.say("gin_2")
		"knife":
			await story.say("knife_1")
			GameState.set_flag("has_knife")
			hud.refresh()
			await story.say("knife_2")
		"bills":
			await story.say("bills_1")
			await story.say("bills_2")


func _knock_sequence() -> void:
	_busy = true
	_exploring = false
	SaveSystem.autosave("knock")
	hud.show_hud(false)
	_letterbox(true)
	await _pause(0.6)
	Sfx.play_knock()
	_shake(14.0)
	await story.say("knock_1")
	await story.say("knock_2")

	_room.door_open = true
	tom.place(DOOR_POINT)
	tom.visible = true
	_walk(adrian, ADRIAN_TALK)
	await _walk(tom, TOM_STAND)
	adrian.face_toward(tom.world)
	tom.face_toward(adrian.world)
	await story.say("tom_enter")
	if GameState.has_flag("has_pistol"):
		await story.say("tom_pistol")
	await story.say("tom_1")

	# Small talk. Looking at the gin earlier unlocks an extra line.
	var offered_drink := false
	while true:
		var options := ["What does Wycliffe want?"]
		if GameState.has_examined("gin") and not offered_drink:
			options.append("Drink?")
		var pick := await story.choose(options)
		if pick == 1:
			offered_drink = true
			await story.say("ask_drink")
			await story.say("tom_drink")
			await story.say("narr_drink")
			continue
		await story.say("ask_want")
		break

	await story.say("tom_2")
	await story.say("tom_rose")
	await story.say("tom_3")

	var asked_why := false
	while true:
		var options := ["Where do I start?"]
		if not asked_why:
			options.append("Why me?")
		var pick := await story.choose(options)
		if pick == 1:
			asked_why = true
			await story.say("ask_why")
			await story.say("tom_why")
			await story.say("narr_why")
			continue
		await story.say("ask_start")
		break
	await story.say("tom_4")

	await _fee()

	await story.say("tom_leave")
	await _walk(tom, DOOR_POINT)
	tom.visible = false
	_room.door_open = false
	await story.say("narr_close")
	await story.say("end_1")
	await story.say("end_2")
	SaveSystem.autosave("office_done")
	_show_end_card()


## A test scene for the inner voices, reached from the title screen. Not
## part of the story and never saved.
func _voice_demo() -> void:
	_busy = true
	story.load_script(VOICE_DEMO_PATH)
	_room.door_open = true
	adrian.place(ADRIAN_TALK)
	tom.place(TOM_STAND)
	tom.visible = true
	adrian.face_toward(tom.world)
	tom.face_toward(adrian.world)
	_letterbox(true, true)
	await story.say("demo_intro")
	await story.say("demo_tom_1")
	# A sure passive (for the demo) and a coin-flip one.
	await story.passive("psychology", -10, "demo_psy_passive")
	await story.passive("investigation", 3, "demo_inv_passive")
	var pick := await story.choose([
		DialogueLayer.skill_option("psychology", "\"You don't like this job either.\""),
		"\"Nothing. Go.\"",
	])
	if pick == 0:
		await story.say("demo_ask_like")
		await story.say("demo_tom_like")
	var side := await story.argue(["demo_elo_1", "demo_psy_1", "demo_elo_2", "demo_psy_2"], [
		"Side with ELOQUENCE: ask about the war.",
		"Side with PSYCHOLOGY: let him go.",
	])
	if side == 0:
		await story.say("demo_ask_war")
		await story.say("demo_tom_war")
		await story.say("demo_narr_war")
	else:
		await story.say("demo_tom_go")
		await story.say("demo_narr_go")
	await story.say("demo_end")
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/title/title.tscn")


## Pushing the fee is a visible Eloquence check. The bills add a die.
func _fee() -> void:
	await story.say("tom_fee")
	var skill := ADRIAN_SHEET.get_skill("eloquence")
	var dice := 4 if GameState.has_examined("bills") else 3
	var needed := 3
	var odds := roundi(Dice.odds(skill, dice, needed) * 100.0)
	var pick := await story.choose([
		"Done.",
		"For a diamond you can't report stolen? Thirty.\n    ELOQUENCE %d  ·  %d DICE  ·  NEED %d  ·  %d%%" % [skill, dice, needed, odds],
	], 1)
	if pick == 0:
		GameState.fee_per_day = 20
		await story.say("say_done")
		await story.say("tom_done")
		return
	await story.say("say_haggle")
	if GameState.has_examined("bills"):
		await story.say("bills_fee")
	var result := Dice.roll(skill, dice, needed)
	await story.show_check("Eloquence", result)
	if result.passed:
		GameState.fee_per_day = 30
		await story.say("tom_fee_win")
	else:
		GameState.fee_per_day = 20
		await story.say("tom_fee_lose")
		await story.say("narr_fee_lose")


func _show_end_card() -> void:
	_busy = true
	_letterbox(false)
	var layer := CanvasLayer.new()
	layer.layer = 35
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.94 if GameState.test_mode else 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	var box := VBoxContainer.new()
	box.position = Vector2(220, 330)
	box.add_theme_constant_override("separation", 10)
	layer.add_child(box)
	box.add_child(Noir.label("END OF THE OFFICE", Noir.DISPLAY_FONT, 100, Noir.PAPER))
	box.add_child(Noir.label("NEXT  ·  THE BOSTON CIVIC BALLET", Noir.TITLE_FONT, 44, Noir.ACCENT))
	box.add_child(Noir.label("Fee agreed: $%d a day and expenses." % GameState.fee_per_day, Noir.NARRATOR_FONT, 30, Noir.DIM))
	var back := Button.new()
	back.text = "RETURN TO TITLE"
	back.alignment = HORIZONTAL_ALIGNMENT_LEFT
	back.add_theme_font_override("font", Noir.TITLE_FONT)
	back.add_theme_font_size_override("font_size", 34)
	back.add_theme_color_override("font_color", Noir.PAPER)
	back.add_theme_color_override("font_hover_color", Noir.ACCENT)
	back.add_theme_stylebox_override("normal", Noir.box(Color(0, 0, 0, 0), Color(1, 1, 1, 0.3), 12))
	back.add_theme_stylebox_override("hover", Noir.box(Color(0, 0, 0, 0), Noir.ACCENT, 12))
	back.add_theme_stylebox_override("focus", Noir.box(Color(0, 0, 0, 0), Noir.ACCENT, 12))
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title/title.tscn"))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 40
	box.add_child(spacer)
	box.add_child(back)
	if not GameState.test_mode:
		box.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(shade, "color:a", 0.94, 1.5)
		t.tween_property(box, "modulate:a", 1.0, 0.8)


# --- Movement ---------------------------------------------------------------

func _walk(who: Walker, target: Vector2) -> void:
	await who.follow(_path(who.world, target))


func _path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := _open_cell(_cell(from))
	var goal := _open_cell(_cell(to))
	var ids := _grid.get_id_path(start, goal)
	var points := PackedVector2Array()
	for id in ids:
		points.append((Vector2(id) + Vector2(0.5, 0.5)) * CELL)
	if points.size() > 0 and _cell(to) == goal:
		points[points.size() - 1] = to
	return _simplify(points)


## Drop points that sit on a straight line, so walks are smooth.
func _simplify(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		var a := (points[i] - out[out.size() - 1]).normalized()
		var b := (points[i + 1] - points[i]).normalized()
		if a.dot(b) < 0.999:
			out.append(points[i])
	out.append(points[points.size() - 1])
	return out


func _cell(p: Vector2) -> Vector2i:
	var size := _grid.region.size
	return Vector2i(clampi(floori(p.x / CELL), 0, size.x - 1), clampi(floori(p.y / CELL), 0, size.y - 1))


func _open_cell(c: Vector2i) -> Vector2i:
	if not _grid.is_point_solid(c):
		return c
	for r in range(1, 12):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var n := c + Vector2i(dx, dy)
				if _grid.is_in_boundsv(n) and not _grid.is_point_solid(n):
					return n
	return c


func _build_grid() -> void:
	_grid.region = Rect2i(0, 0, int(RoomArt.W / CELL), int(RoomArt.D / CELL))
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for x in _grid.region.size.x:
		for y in _grid.region.size.y:
			var centre := (Vector2(x, y) + Vector2(0.5, 0.5)) * CELL
			var solid := centre.x < 0.3 and not (centre.y > RoomArt.DOOR_Y.x and centre.y < RoomArt.DOOR_Y.y)
			solid = solid or centre.y < 0.3
			for r in BLOCKERS:
				if (r as Rect2).grow(0.15).has_point(centre):
					solid = true
			_grid.set_point_solid(Vector2i(x, y), solid)


# --- Hotspots ---------------------------------------------------------------

func _hotspot_at(point: Vector2) -> String:
	# Small desk props first, so they win over the furniture behind them.
	for id in ["photo", "bills", "envelope", "pistol", "knife", "gin"]:
		var box: IsoBox = _boxes[id]
		if box.hit(point) or point.distance_to(box.top_center()) < 30.0:
			return id
	return ""


func _set_hover(id: String) -> void:
	if id == _hover:
		return
	if _hover != "":
		_boxes[_hover].highlighted = false
		_boxes[_hover].queue_redraw()
	_hover = id
	_hover_label.visible = id != ""
	if id == "":
		return
	var box: IsoBox = _boxes[id]
	box.highlighted = true
	box.queue_redraw()
	var done := GameState.has_examined(id)
	_hover_label.text = HOTSPOTS[id]["label"].to_upper() + ("   ·   SEEN" if done else "")
	_hover_label.add_theme_color_override("font_color", Noir.DIM if done else Noir.ACCENT)
	_hover_label.reset_size()
	_hover_label.position = box.top_center() - Vector2(_hover_label.size.x * 0.5, 70)


func _box_floor(id: String) -> Vector2:
	var box: IsoBox = _boxes[id]
	return Vector2(box.origin.x + box.size.x * 0.5, box.origin.y + box.size.y * 0.5)


func _update_objective() -> void:
	var left := GameState.MAX_EXAMINE - GameState.examined.size()
	hud.set_objective("THREE SMALL THINGS" if left > 0 else "", left, GameState.MAX_EXAMINE if left > 0 else 0)


# --- The room ---------------------------------------------------------------

func _box(parent: Node, at: Vector3, size: Vector3, color: Color, drawers := 0) -> IsoBox:
	var b := IsoBox.new()
	b.drawers = drawers
	b.setup(at, size, color)
	parent.add_child(b)
	if parent != _world:
		b.position -= (parent as Node2D).position
	return b


## A wooden chair on four legs. `back_far` puts the backrest on the side away
## from the camera (a chair facing us); otherwise it is nearest the camera.
func _chair(at: Vector2, back_far: bool) -> void:
	const S := 0.7
	const LEG := 0.06
	const SEAT := 0.42
	var wood := Color("#4a3a30")
	var holder := Node2D.new()
	holder.position = Iso.ground(at + Vector2(S, S))
	_world.add_child(holder)
	var back_y := at.y if back_far else at.y + S - 0.1
	# Far leg first, then the seat, then the legs and back in front of it.
	_box(holder, Vector3(at.x, at.y, 0), Vector3(LEG, LEG, SEAT), wood.darkened(0.3))
	if back_far:
		_box(holder, Vector3(at.x, back_y, SEAT), Vector3(S, 0.1, 0.62), wood.darkened(0.1))
	_box(holder, Vector3(at.x, at.y, SEAT), Vector3(S, S, 0.07), wood)
	for leg in [Vector2(S - LEG, 0), Vector2(0, S - LEG), Vector2(S - LEG, S - LEG)]:
		_box(holder, Vector3(at.x + leg.x, at.y + leg.y, 0), Vector3(LEG, LEG, SEAT), wood.darkened(0.3))
	if not back_far:
		_box(holder, Vector3(at.x, back_y, SEAT + 0.07), Vector3(S, 0.1, 0.6), wood.darkened(0.1))


func _prop(parent: Node, kind: String, anchor: Vector3) -> IsoProp:
	var p := IsoProp.new().setup(kind, anchor)
	parent.add_child(p)
	if parent != _world:
		p.position -= (parent as Node2D).position
	return p


func _build_stage() -> void:
	_stage = Node2D.new()
	add_child(_stage)
	_room = RoomArt.new()
	_stage.add_child(_room)

	_blinds = Node2D.new()
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	add.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_blinds.material = add
	_blinds.draw.connect(_draw_blind_light)
	_stage.add_child(_blinds)

	_world = Node2D.new()
	_world.y_sort_enabled = true
	_stage.add_child(_world)

	# Furniture.
	_boxes["gin"] = _box(_world, Vector3(0.7, 0.05, 0), Vector3(0.9, 0.7, 1.6), Color("#4e504c"), 3)
	var shelf := _box(_world, Vector3(2.0, 0.05, 0), Vector3(1.4, 0.55, 1.2), Color("#3e2a1c"))
	_prop(shelf, "books", Vector3(3.4, 0.6, 0))
	_prop(shelf, "radio", Vector3(3.4, 0.6, 0))
	_chair(Vector2(4.35, 1.45), true)
	var desk := _box(_world, Vector3(3.4, 2.4, 0), Vector3(2.6, 1.2, 0.75), Color("#7a5236"), 0)
	_chair(Vector2(4.2, 4.4), false)
	# The couch he slept on, under the clock.
	_box(_world, Vector3(7.0, 0.05, 0), Vector3(1.9, 0.9, 0.42), Color("#34302e"))
	_box(_world, Vector3(7.0, 0.05, 0.42), Vector3(1.9, 0.25, 0.5), Color("#2a2624"))
	_box(_world, Vector3(7.0, 0.3, 0.42), Vector3(0.18, 0.65, 0.18), Color("#2a2624"))
	_box(_world, Vector3(8.72, 0.3, 0.42), Vector3(0.18, 0.65, 0.18), Color("#2a2624"))
	_prop(_world, "blanket", Vector3(8.9, 1.0, 0))
	# Waste bin and the drafts that missed it.
	_box(_world, Vector3(6.55, 3.45, 0), Vector3(0.28, 0.28, 0.38), Color("#3a3a3a"))
	_prop(_world, "papers", Vector3(6.3, 3.3, 0))
	# Coat rack: the hit box is invisible, the coat and hat are drawn.
	_box(_world, Vector3(0.25, 4.05, 0), Vector3(0.1, 0.1, 1.9), Color("#3a2a1c"))
	_boxes["knife"] = _box(_world, Vector3(0.1, 3.9, 0.75), Vector3(0.42, 0.42, 1.05), Color(0, 0, 0, 0))
	_prop(_world, "coat", Vector3(0.6, 4.4, 0))

	# On and in the desk.
	_boxes["pistol"] = _box(desk, Vector3(5.1, 3.58, 0.12), Vector3(0.7, 0.04, 0.32), Color("#6a4a30"))
	_boxes["photo"] = _box(desk, Vector3(4.05, 2.55, 0.75), Vector3(0.3, 0.08, 0.38), Color("#a08a5c"))
	_boxes["bills"] = _box(desk, Vector3(4.6, 2.8, 0.75), Vector3(0.5, 0.36, 0.07), Color("#e2dccb"))
	_boxes["envelope"] = _box(desk, Vector3(5.3, 3.0, 0.75), Vector3(0.42, 0.26, 0.03), Color("#d8c89a"))
	_box(desk, Vector3(3.6, 2.6, 0.75), Vector3(0.22, 0.22, 0.04), Color("#a08040"))
	_box(desk, Vector3(3.68, 2.68, 0.79), Vector3(0.05, 0.05, 0.3), Color("#a08040"))
	_box(desk, Vector3(3.5, 2.55, 1.05), Vector3(0.42, 0.32, 0.12), Color("#2f6a46"))
	# Case files, the ashtray, the telephone, last night's bottle.
	_box(desk, Vector3(3.5, 3.0, 0.75), Vector3(0.5, 0.36, 0.05), Color("#c8a868"))
	_box(desk, Vector3(3.53, 2.98, 0.8), Vector3(0.5, 0.36, 0.05), Color("#b89858"))
	_box(desk, Vector3(3.5, 3.02, 0.85), Vector3(0.5, 0.36, 0.04), Color("#d0b070"))
	_prop(desk, "ashtray", Vector3(6.0, 3.6, 0.75))
	_prop(desk, "phone", Vector3(6.0, 3.6, 0.75))
	_prop(desk, "bottle", Vector3(6.0, 3.6, 0.75))

	adrian = Walker.new()
	_world.add_child(adrian)
	adrian.place(ADRIAN_START)
	tom = Walker.new()
	tom.body_color = Color("#2a2622")
	tom.height = 1.08
	tom.width = 1.3
	tom.hat = false
	adrian.coat = false
	adrian.hat = false
	tom.face_color = Color("#a08870")
	tom.visible = false
	_world.add_child(tom)
	tom.place(DOOR_POINT)

	var dark := CanvasModulate.new()
	dark.color = Color(0.44, 0.44, 0.46)
	_stage.add_child(dark)

	_lamp = _light(Iso.to_screen(Vector3(3.7, 2.7, 0.9)), Color(1.0, 0.96, 0.9), 1.45, 4.2)
	_window_light = _light(Iso.to_screen(Vector3(5.0, 2.4, 0.0)), Color(0.55, 0.68, 1.0), 0.55, 6.0)

	_hover_label = Noir.label("", Noir.TITLE_FONT, 34, Noir.ACCENT)
	_hover_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hover_label.add_theme_constant_override("outline_size", 10)
	_hover_label.visible = false
	var hover_layer := CanvasLayer.new()
	hover_layer.layer = 15
	hover_layer.add_child(_hover_label)
	add_child(hover_layer)


func _light(at: Vector2, color: Color, energy: float, scale_: float) -> PointLight2D:
	var tex := GradientTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(0, 0, 0, 1))
	g.add_point(0.4, Color(0.45, 0.45, 0.45, 1))
	tex.gradient = g
	var light := PointLight2D.new()
	light.texture = tex
	light.color = color
	light.energy = energy
	light.texture_scale = scale_
	light.position = at
	_stage.add_child(light)
	return light


## Venetian-blind light thrown across the floor from the window.
func _draw_blind_light() -> void:
	var dir := Vector3(-0.25, 1.0, -0.55)
	var slats := 7
	var z0 := RoomArt.WINDOW_Z.x
	var z1 := RoomArt.WINDOW_Z.y
	var strength: float = 0.07 + 0.5 * _room.flash
	for i in slats:
		var za := lerpf(z0, z1, (i + 0.35) / slats)
		var zb := lerpf(z0, z1, (i + 0.85) / slats)
		var quad := PackedVector2Array()
		for corner in [[RoomArt.WINDOW_X.x, za], [RoomArt.WINDOW_X.y, za], [RoomArt.WINDOW_X.y, zb], [RoomArt.WINDOW_X.x, zb]]:
			var t: float = corner[1] / -dir.z
			quad.append(Iso.ground(Vector2(corner[0] + dir.x * t, dir.y * t)))
		_blinds.draw_colored_polygon(quad, Color(0.55, 0.65, 0.85, strength))
	# Dust turning in the light.
	var t := Time.get_ticks_msec() * 0.001
	for i in 26:
		var u := fmod(i * 0.381 + t * 0.012 * (1 + i % 3), 1.0)
		var h := fmod(i * 0.677 + t * 0.03, 1.0)
		var pos := Iso.to_screen(Vector3(lerpf(3.6, 6.4, u), lerpf(0.6, 3.6, fmod(i * 0.29, 1.0)), h * 2.0))
		_blinds.draw_circle(pos, 1.6, Color(0.9, 0.9, 1.0, 0.25 * sin(h * PI)))


# --- Screen effects ---------------------------------------------------------

func _build_screen_fx() -> void:
	# Black and white over the room; only strong reds survive.
	var grade_layer := CanvasLayer.new()
	grade_layer.layer = 9
	add_child(grade_layer)
	var bw := ColorRect.new()
	bw.set_anchors_preset(Control.PRESET_FULL_RECT)
	bw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bw_mat := ShaderMaterial.new()
	bw_mat.shader = SIN_CITY
	bw.material = bw_mat
	grade_layer.add_child(bw)

	var fx := CanvasLayer.new()
	fx.layer = 10
	add_child(fx)
	var grade := ColorRect.new()
	grade.set_anchors_preset(Control.PRESET_FULL_RECT)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = SCREEN_FX
	grade.material = mat
	fx.add_child(grade)
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.size = Vector2(1920, 0)
		bar.position = Vector2(0, 0 if top else 1080)
		fx.add_child(bar)
		_bars.append(bar)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 25
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)


## Cinema bars for story beats; they slide away when the player has control.
func _letterbox(on: bool, instant := false) -> void:
	var h := 110.0 if on else 0.0
	if instant or GameState.test_mode:
		_bars[0].size.y = h
		_bars[1].size.y = h
		_bars[1].position.y = 1080 - h
		return
	var t := create_tween().set_parallel()
	t.tween_property(_bars[0], "size:y", h, 0.6)
	t.tween_property(_bars[1], "size:y", h, 0.6)
	t.tween_property(_bars[1], "position:y", 1080 - h, 0.6)


func _lightning() -> void:
	var t := create_tween()
	for strike in [0.9, 0.0, 1.0, 0.0]:
		t.tween_method(_set_flash, _room.flash, strike, 0.05)
		t.tween_interval(0.06)


func _set_flash(v: float) -> void:
	_room.flash = v
	_window_light.energy = 0.55 + v * 2.2
	_blinds.queue_redraw()


func _shake(amount: float) -> void:
	if GameState.test_mode:
		return
	var t := create_tween()
	for i in 8:
		t.tween_property(_stage, "position", Vector2(randf_range(-amount, amount), randf_range(-amount, amount) * 0.5), 0.035)
	t.tween_property(_stage, "position", Vector2.ZERO, 0.05)


func _pause(seconds: float) -> void:
	if GameState.test_mode:
		return
	await get_tree().create_timer(seconds).timeout
