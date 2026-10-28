class_name Iso
## Isometric projection for the room. World units are floor tiles on x and y,
## and heights on z. +x runs down-right on screen, +y runs down-left.

const HALF_W := 80.0
const HALF_H := 40.0
const Z_SCALE := 110.0
const ORIGIN := Vector2(880, 300)


static func to_screen(p: Vector3) -> Vector2:
	return ORIGIN + Vector2((p.x - p.y) * HALF_W, (p.x + p.y) * HALF_H - p.z * Z_SCALE)


static func ground(p: Vector2) -> Vector2:
	return to_screen(Vector3(p.x, p.y, 0.0))


## Screen point back to the floor (z = 0).
static func to_world(s: Vector2) -> Vector2:
	var d := s - ORIGIN
	var a := d.x / HALF_W
	var b := d.y / HALF_H
	return Vector2((a + b) * 0.5, (b - a) * 0.5)
