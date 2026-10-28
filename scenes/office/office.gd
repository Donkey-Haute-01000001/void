extends Node2D
## Case 1 opening: Adrian's office. The player examines three of six objects,
## then Tom Garrity knocks with Wycliffe's job. All art is placeholder shapes.

const SCRIPT_PATH := "res://data/script/office.json"
const ADRIAN_SHEET := preload("res://data/characters/adrian.tres")
const ROOM_RIGHT := 1320.0
var floor_points := PackedVector2Array([
	Vector2(150, 600), Vector2(1170, 600), Vector2(1300, 1050), Vector2(20, 1050)])
const DOOR_POINT := Vector2(1215, 690)

## The six things Adrian can look at before the knock. `stand` is where he
## walks to first; `rect` is the clickable area.
const HOTSPOTS := {
	"photo": {"label": "Sylvia's photograph", "rect": Rect2(565, 486, 44, 36), "stand": Vector2(600, 720)},
	"bills": {"label": "The unpaid bills", "rect": Rect2(660, 500, 96, 26), "stand": Vector2(710, 720)},
	"envelope": {"label": "Envelope for Worcester", "rect": Rect2(800, 500, 66, 26), "stand": Vector2(830, 720)},
	"pistol": {"label": "The bottom drawer", "rect": Rect2(842, 586, 70, 46), "stand": Vector2(890, 730)},
	"gin": {"label": "The filing cabinet", "rect": Rect2(222, 380, 110, 220), "stand": Vector2(300, 720)},
	"knife": {"label": "Coat on the rack", "rect": Rect2(1082, 330, 70, 180), "stand": Vector2(1060, 730)},
}

var story: StoryPanel
var adrian: Walker
var tom: Walker
var _busy := true
var _exploring := false
var _hover := ""
var _time := 0.0
var _counter: Label
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	story = StoryPanel.new()
	add_child(story)
	story.load_script(SCRIPT_PATH)

	adrian = Walker.new()
	adrian.position = Vector2(470, 820)
	add_child(adrian)
	tom = Walker.new()
	tom.body_color = Color("#3a3128")
	tom.height = 1.06
	tom.position = DOOR_POINT
	tom.visible = false
	add_child(tom)

	_build_counter()
	Sfx.start_rain()

	match GameState.checkpoint:
		"knock":
			_update_counter()
			_knock_sequence()
		"office_done":
			_show_end_card()
		_:
			SaveSystem.autosave("start")
			_opening()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _opening() -> void:
	await story.say("intro_1")
	await story.say("intro_2")
	await story.say("intro_3")
	_update_counter()
	_exploring = true
	_busy = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_hover = _hotspot_at(get_global_mouse_position()) if _exploring else ""
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if _busy:
		return
	var point := get_global_mouse_position()
	if point.x > ROOM_RIGHT:
		return
	var hit := _hotspot_at(point) if _exploring else ""
	if hit != "":
		examine(hit)
	else:
		adrian.walk_to(_clamp_to_floor(point))


## Walk to an object and look at it. Public so the test runner can drive it.
func examine(id: String) -> void:
	_busy = true
	_hover = ""
	await adrian.walk_to(HOTSPOTS[id]["stand"])
	if GameState.has_examined(id):
		await story.say("already")
	elif GameState.examined.size() >= GameState.MAX_EXAMINE:
		await story.say("no_time")
	else:
		await _examine_lines(id)
		GameState.examined.append(id)
		_update_counter()
	if GameState.examined.size() >= GameState.MAX_EXAMINE:
		_exploring = false
		_hover = ""
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
				await story.say("pistol_take")
			else:
				await story.say("pistol_leave")
		"gin":
			await story.say("gin_1")
			await story.say("gin_2")
		"knife":
			await story.say("knife_1")
			await story.say("knife_2")
		"bills":
			await story.say("bills_1")
			await story.say("bills_2")


func _knock_sequence() -> void:
	_busy = true
	_exploring = false
	SaveSystem.autosave("knock")
	await _pause(0.6)
	Sfx.play_knock()
	await _pause(1.3)
	await story.say("knock_1")
	await story.say("knock_2")

	tom.position = DOOR_POINT
	tom.visible = true
	await tom.walk_to(Vector2(1010, 780))
	adrian.walk_to(Vector2(640, 800))
	await story.say("tom_enter")
	if GameState.has_flag("has_pistol"):
		await story.say("tom_pistol")
	await story.say("tom_1")

	# Small talk. Looking at the gin earlier unlocks an extra line.
	var offered_drink := false
	while true:
		var options := ["What does Mr. Wycliffe want?"]
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
	await tom.walk_to(DOOR_POINT)
	tom.visible = false
	await story.say("narr_close")
	await story.say("end_1")
	SaveSystem.autosave("office_done")
	_show_end_card()


## Pushing the fee is a visible Eloquence check. The bills add a die.
func _fee() -> void:
	await story.say("tom_fee")
	var skill := ADRIAN_SHEET.get_skill("eloquence")
	var dice := 4 if GameState.has_examined("bills") else 3
	var needed := 2
	var odds := roundi(Dice.odds(skill, dice, needed) * 100.0)
	var pick := await story.choose([
		"Done.",
		"\"For a diamond you can't report stolen? Thirty.\"  [Eloquence %d · %d dice, need %d · %d%%]" % [skill, dice, needed, odds],
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
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	box.position = Vector2(760, 420)
	layer.add_child(box)
	var title := Label.new()
	title.text = "End of the office.\nNext: the Boston Civic Ballet."
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color("#d8d2c4"))
	box.add_child(title)
	var fee := Label.new()
	fee.text = "Fee agreed: $%d a day and expenses" % GameState.fee_per_day
	fee.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fee.add_theme_color_override("font_color", Color("#7d8a8f"))
	box.add_child(fee)
	var back := Button.new()
	back.text = "Return to title"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/title/title.tscn"))
	box.add_child(back)
	if not GameState.test_mode:
		create_tween().tween_property(shade, "color", Color(0, 0, 0, 0.92), 1.5)


func _pause(seconds: float) -> void:
	if GameState.test_mode:
		return
	await get_tree().create_timer(seconds).timeout


func _hotspot_at(point: Vector2) -> String:
	for id in HOTSPOTS:
		if (HOTSPOTS[id]["rect"] as Rect2).has_point(point):
			return id
	return ""


func _clamp_to_floor(point: Vector2) -> Vector2:
	if Geometry2D.is_point_in_polygon(point, floor_points):
		return point
	var best: Vector2 = floor_points[0]
	for i in floor_points.size():
		var p := Geometry2D.get_closest_point_to_segment(point, floor_points[i], floor_points[(i + 1) % floor_points.size()])
		if p.distance_to(point) < best.distance_to(point):
			best = p
	return best


func _build_counter() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_counter = Label.new()
	_counter.position = Vector2(40, 30)
	_counter.add_theme_font_size_override("font_size", 22)
	_counter.add_theme_color_override("font_color", Color("#8b857a"))
	layer.add_child(_counter)


func _update_counter() -> void:
	var left := GameState.MAX_EXAMINE - GameState.examined.size()
	_counter.text = "Three small things · %d left" % left if left > 0 else ""


# --- Placeholder room, drawn with plain shapes -----------------------------

func _draw() -> void:
	# Walls and floor.
	draw_colored_polygon(PackedVector2Array([Vector2(20, 40), Vector2(150, 120), Vector2(150, 600), Vector2(20, 1050)]), Color("#1e1d1a"))
	draw_colored_polygon(PackedVector2Array([Vector2(1170, 120), Vector2(1300, 40), Vector2(1300, 1050), Vector2(1170, 600)]), Color("#1b1a18"))
	draw_rect(Rect2(150, 120, 1020, 480), Color("#2b2925"))
	draw_rect(Rect2(150, 470, 1020, 130), Color("#221f1b"))
	draw_colored_polygon(floor_points, Color("#33291f"))
	for i in range(1, 9):
		var t := i / 9.0
		draw_line(floor_points[0].lerp(floor_points[1], t), floor_points[3].lerp(floor_points[2], t), Color("#2b2219"), 2.0)

	# Window with rain.
	var window := Rect2(500, 190, 300, 230)
	draw_rect(window, Color("#141c27"))
	for i in 26:
		var x := window.position.x + fmod(i * 37.0 + _time * 15.0, window.size.x)
		var y := window.position.y + fmod(i * 53.0 + _time * 420.0, window.size.y)
		draw_line(Vector2(x, y), Vector2(x - 3, minf(y + 22, window.end.y)), Color(0.55, 0.65, 0.75, 0.35), 1.5)
	draw_rect(window, Color("#4a4237"), false, 10.0)
	draw_line(Vector2(window.get_center().x, window.position.y), Vector2(window.get_center().x, window.end.y), Color("#4a4237"), 6.0)

	# Door with frosted glass.
	draw_colored_polygon(PackedVector2Array([Vector2(1192, 300), Vector2(1272, 262), Vector2(1272, 712), Vector2(1192, 660)]), Color("#3f3226"))
	draw_colored_polygon(PackedVector2Array([Vector2(1202, 330), Vector2(1262, 302), Vector2(1262, 470), Vector2(1202, 490)]), Color(0.62, 0.66, 0.66, 0.55))

	# Desk, chair, filing cabinet, coat rack.
	draw_rect(Rect2(690, 440, 90, 70), Color("#2a221b"))
	draw_rect(Rect2(520, 520, 420, 46), Color("#6b5440"))
	draw_rect(Rect2(540, 566, 380, 96), Color("#4f3d2d"))
	draw_rect(Rect2(222, 380, 110, 220), Color("#45443e"))
	for i in 3:
		draw_rect(Rect2(234, 396 + i * 70, 86, 56), Color("#3a3934"), false, 3.0)
	draw_line(Vector2(1110, 320), Vector2(1110, 610), Color("#2c241c"), 8.0)
	draw_colored_polygon(PackedVector2Array([Vector2(1090, 340), Vector2(1135, 340), Vector2(1148, 505), Vector2(1080, 505)]), Color("#24262b"))

	# Props on the desk.
	draw_rect(Rect2(570, 490, 34, 30), Color("#8a7a5c"))
	draw_rect(Rect2(576, 495, 22, 20), Color("#c8c1b0"))
	draw_rect(Rect2(664, 506, 88, 14), Color("#d6d0bf"))
	draw_rect(Rect2(806, 506, 56, 14), Color("#cbbf9a"))
	draw_rect(Rect2(866, 604, 24, 8), Color("#8f7a52"))

	# Highlights.
	if _exploring:
		for id in HOTSPOTS:
			var rect: Rect2 = HOTSPOTS[id]["rect"]
			if GameState.has_examined(id):
				draw_rect(rect.grow(4), Color(1, 1, 1, 0.08), false, 2.0)
			elif id == _hover:
				draw_rect(rect.grow(6), Color("#d9a441"), false, 3.0)
				draw_string(_font, rect.position + Vector2(0, -14), HOTSPOTS[id]["label"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#f3d08a"))
