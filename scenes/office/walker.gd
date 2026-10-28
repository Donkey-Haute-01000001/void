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
## Adrian wears a fedora; Garrity goes bareheaded.
@export var hat := true

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
	# Legs, long coat, collar, head, then fedora or hair.
	draw_rect(Rect2(-12 * w, -64 * h, 10 * w, 64 * h), body_color.darkened(0.3))
	draw_rect(Rect2(2 * w, -64 * h, 10 * w, 64 * h), body_color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22 * w, -150 * h), Vector2(22 * w, -150 * h), Vector2(28 * w, -52 * h), Vector2(-28 * w, -52 * h)]), body_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-12 * w, -152 * h), Vector2(12 * w, -152 * h), Vector2(0, -128 * h)]), face_color.darkened(0.35))
	draw_line(Vector2(0, -128 * h), Vector2(3, -60 * h), body_color.lightened(0.15), 2.0)
	draw_circle(Vector2(0, -166 * h), 15.0, face_color)
	if hat:
		draw_rect(Rect2(-25, -180 * h, 50, 6), body_color.darkened(0.5))
		draw_rect(Rect2(-14, -192 * h, 28, 13), body_color.darkened(0.5))
		draw_rect(Rect2(-14, -182 * h, 28, 3), Color("#5a2a26"))
	else:
		draw_rect(Rect2(-15, -183 * h, 30, 9), Color("#1c1a18"))
