class_name Walker
extends Node2D
## A placeholder figure that walks a path across the floor. Positions are in
## world (tile) units; the node itself sits at the figure's feet on screen.
## Swap the drawing for a sprite when the character art exists.

const SPEED := 2.6  # tiles per second

@export var body_color := Color("#15161a")
@export var face_color := Color("#b8a58c")
@export var height := 1.0
@export var width := 1.0
@export var hat := true
## Without the coat: shirtsleeves, waistcoat and tie.
@export var coat := true
@export var hair_color := Color("#16120f")

var world := Vector2.ZERO:
	set(value):
		world = value
		position = Iso.ground(value)

var _tween: Tween


func place(at: Vector2) -> void:
	world = at


## Follow a list of world points. Await it to know when the figure arrives.
func follow(path: PackedVector2Array) -> void:
	if _tween:
		_tween.kill()
	if path.is_empty():
		return
	if GameState.test_mode:
		world = path[path.size() - 1]
		return
	_tween = create_tween()
	var from := world
	for point in path:
		var seconds := from.distance_to(point) / SPEED
		_tween.tween_callback(_face.bind(Iso.ground(point).x - Iso.ground(from).x))
		_tween.tween_property(self, "world", point, seconds)
		from = point
	await _tween.finished


## Turn to look at a floor point.
func face_toward(point: Vector2) -> void:
	_face(Iso.ground(point).x - Iso.ground(world).x)


func _face(dx: float) -> void:
	if absf(dx) > 2.0:
		scale.x = signf(dx)


func _draw() -> void:
	var h := 1.25 * height
	var w := width
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 30.0 * w, Color(0, 0, 0, 0.45))
	draw_set_transform(Vector2.ZERO)
	if coat:
		_draw_coated(h, w)
	else:
		_draw_shirtsleeves(h, w)
	# Head, then fedora or hair.
	if not hat:
		draw_circle(Vector2(0, -169 * h), 15.5, hair_color)
	draw_circle(Vector2(0, -164 * h), 14.0, face_color)
	if hat:
		draw_rect(Rect2(-25, -178 * h, 50, 6), body_color.darkened(0.5))
		draw_rect(Rect2(-14, -190 * h, 28, 13), body_color.darkened(0.5))
		draw_rect(Rect2(-14, -180 * h, 28, 3), Color("#5a2a26"))
	else:
		# A loose curl falling over the forehead.
		draw_colored_polygon(PackedVector2Array([
			Vector2(-13, -172 * h), Vector2(13, -172 * h), Vector2(4, -169 * h), Vector2(-6, -167.5 * h)]), hair_color)


func _draw_coated(h: float, w: float) -> void:
	draw_rect(Rect2(-12 * w, -64 * h, 10 * w, 64 * h), body_color.darkened(0.3))
	draw_rect(Rect2(2 * w, -64 * h, 10 * w, 64 * h), body_color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22 * w, -150 * h), Vector2(22 * w, -150 * h), Vector2(28 * w, -52 * h), Vector2(-28 * w, -52 * h)]), body_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12 * w, -152 * h), Vector2(12 * w, -152 * h), Vector2(0, -128 * h)]), face_color.darkened(0.35))
	draw_line(Vector2(0, -128 * h), Vector2(3, -60 * h), body_color.lightened(0.15), 2.0)
	for side in [-1, 1]:
		draw_line(Vector2(side * 22 * w, -146 * h), Vector2(side * 27 * w, -88 * h), body_color.darkened(0.15), 9.0 * w)
		draw_circle(Vector2(side * 27 * w, -84 * h), 4.5, face_color.darkened(0.2))


func _draw_shirtsleeves(h: float, w: float) -> void:
	var shirt := Color("#cfc8b8")
	var vest := Color("#2e2a30")
	var trousers := Color("#26262c")
	draw_rect(Rect2(-12 * w, -72 * h, 10 * w, 72 * h), trousers)
	draw_rect(Rect2(2 * w, -72 * h, 10 * w, 72 * h), trousers)
	draw_rect(Rect2(-13 * w, -4, 12 * w, 4), Color("#120f0c"))
	draw_rect(Rect2(1 * w, -4, 12 * w, 4), Color("#120f0c"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-19 * w, -150 * h), Vector2(19 * w, -150 * h), Vector2(16 * w, -72 * h), Vector2(-16 * w, -72 * h)]), shirt)
	draw_line(Vector2(0, -150 * h), Vector2(0, -116 * h), Color("#7a2a26"), 4.0)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-18 * w, -138 * h), Vector2(-6 * w, -138 * h), Vector2(0, -116 * h), Vector2(6 * w, -138 * h),
		Vector2(18 * w, -138 * h), Vector2(16 * w, -70 * h), Vector2(-16 * w, -70 * h)]), vest)
	for i in 3:
		draw_circle(Vector2(1, (-108 + i * 12) * h), 1.5, Color("#8a7a5a"))
	# Sleeves rolled to the elbow.
	for side in [-1, 1]:
		var shoulder := Vector2(side * 19 * w, -146 * h)
		var elbow := Vector2(side * 23 * w, -112 * h)
		var hand := Vector2(side * 22 * w, -84 * h)
		draw_line(shoulder, elbow, shirt, 9.0)
		draw_line(elbow, hand, face_color.darkened(0.1), 6.0)
		draw_circle(hand, 4.0, face_color.darkened(0.1))
