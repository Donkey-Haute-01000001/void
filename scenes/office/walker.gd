class_name Walker
extends Node2D
## A placeholder figure that walks where it is told. Swap the drawing for a
## sprite when the character art exists.

const SPEED := 430.0

@export var body_color := Color("#1d1f24")
@export var face_color := Color("#c9b49a")
@export var height := 1.0

var _tween: Tween


func walk_to(target: Vector2) -> void:
	if _tween:
		_tween.kill()
	var distance := position.distance_to(target)
	if distance < 2.0:
		return
	if absf(target.x - position.x) > 4.0:
		scale.x = signf(target.x - position.x)
	if GameState.test_mode:
		position = target
		return
	_tween = create_tween()
	_tween.tween_property(self, "position", target, distance / SPEED)
	await _tween.finished


func _draw() -> void:
	var h := height
	draw_set_transform(Vector2(0, 0), 0.0, Vector2(1.0, 0.3))
	draw_circle(Vector2.ZERO, 34.0, Color(0, 0, 0, 0.35))
	draw_set_transform(Vector2.ZERO)
	# Coat, legs, head and hat.
	draw_rect(Rect2(-14, -70 * h, 11, 70 * h), body_color.darkened(0.3))
	draw_rect(Rect2(3, -70 * h, 11, 70 * h), body_color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-26, -160 * h), Vector2(26, -160 * h), Vector2(30, -62 * h), Vector2(-30, -62 * h)]), body_color)
	draw_circle(Vector2(0, -178 * h), 18.0, face_color)
	# Fedora: a wide brim and a low crown.
	draw_rect(Rect2(-28, -196 * h, 56, 6), body_color.darkened(0.4))
	draw_rect(Rect2(-16, -208 * h, 32, 13), body_color.darkened(0.4))
