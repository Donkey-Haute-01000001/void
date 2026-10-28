extends Node2D
## The office shell in isometric: floor, two cut-away walls, the rain-streaked
## window with blinds, and the frosted door. Placeholder art drawn in code.

const W := 9.0  # room width along x, in tiles
const D := 7.0  # room depth along y
const H := 2.6  # wall height

const WINDOW_X := Vector2(4.0, 6.6)
const WINDOW_Z := Vector2(1.0, 2.3)
const DOOR_Y := Vector2(5.2, 6.3)
const DOOR_Z := 2.1

var door_open := false:
	set(v):
		door_open = v
		queue_redraw()
## 0..1, brightens the window during lightning.
var flash := 0.0

var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _p(x: float, y: float, z: float) -> Vector2:
	return Iso.to_screen(Vector3(x, y, z))


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c, d]), color)


func _draw() -> void:
	# Floor: dark boards and a worn rug.
	_quad(_p(0, 0, 0), _p(W, 0, 0), _p(W, D, 0), _p(0, D, 0), Color("#5a4030"))
	for i in range(1, 20):
		var y := i * D / 20.0
		draw_line(_p(0, y, 0), _p(W, y, 0), Color("#46311f"), 2.0)
	_quad(_p(2.6, 1.6, 0), _p(7.4, 1.6, 0), _p(7.4, 5.8, 0), _p(2.6, 5.8, 0), Color("#3a3634"))
	var rug := PackedVector2Array([_p(2.8, 1.8, 0), _p(7.2, 1.8, 0), _p(7.2, 5.6, 0), _p(2.8, 5.6, 0), _p(2.8, 1.8, 0)])
	draw_polyline(rug, Color("#6a6460"), 2.0)

	# Back walls: wallpaper over dark wood wainscot.
	_quad(_p(0, 0, 0), _p(W, 0, 0), _p(W, 0, H), _p(0, 0, H), Color("#4a5244"))
	_quad(_p(0, 0, 0), _p(0, D, 0), _p(0, D, H), _p(0, 0, H), Color("#3c4338"))
	for i in range(1, 18):
		var x := i * W / 18.0
		draw_line(_p(x, 0, 0.9), _p(x, 0, H), Color(0, 0, 0, 0.12), 3.0)
	for i in range(1, 14):
		var y := i * D / 14.0
		draw_line(_p(0, y, 0.9), _p(0, y, H), Color(0, 0, 0, 0.12), 3.0)
	_quad(_p(0, 0, 0), _p(W, 0, 0), _p(W, 0, 0.9), _p(0, 0, 0.9), Color("#3b2a1f"))
	_quad(_p(0, 0, 0), _p(0, D, 0), _p(0, D, 0.9), _p(0, 0, 0.9), Color("#30231a"))
	draw_line(_p(0, 0, 0.9), _p(W, 0, 0.9), Color("#6b5038"), 4.0)
	draw_line(_p(0, 0, 0.9), _p(0, D, 0.9), Color("#5a4230"), 4.0)
	draw_line(_p(0, 0, 0), _p(0, 0, H), Color(0, 0, 0, 0.35), 3.0)
	# Cut-away wall tops, Disco Elysium style.
	draw_line(_p(0, 0, H), _p(W, 0, H), Color("#15130f"), 10.0)
	draw_line(_p(0, 0, H), _p(0, D, H), Color("#15130f"), 10.0)

	_draw_window()
	_draw_radiator()
	_draw_door()
	_draw_wall_things()


func _draw_window() -> void:
	var x0 := WINDOW_X.x
	var x1 := WINDOW_X.y
	var z0 := WINDOW_Z.x
	var z1 := WINDOW_Z.y
	var night := Color("#16202e").lerp(Color("#c8d8ff"), flash)
	_quad(_p(x0, 0, z0), _p(x1, 0, z0), _p(x1, 0, z1), _p(x0, 0, z1), night)
	# Lit windows across the street.
	var lit := [Vector2(0.15, 0.3), Vector2(0.55, 0.2), Vector2(0.62, 0.55), Vector2(0.85, 0.35)]
	for l in lit:
		var x := lerpf(x0, x1, l.x)
		var z := lerpf(z0, z1, l.y)
		_quad(_p(x, 0, z), _p(x + 0.12, 0, z), _p(x + 0.12, 0, z + 0.1), _p(x, 0, z + 0.1), Color(0.95, 0.75, 0.4, 0.55))
	# Rain on the glass.
	for i in 40:
		var u := fmod(i * 0.137 + _time * 0.01, 1.0)
		var v := 1.0 - fmod(i * 0.311 + _time * 1.6, 1.0)
		var x := lerpf(x0, x1, u)
		var z := lerpf(z0, z1, v)
		draw_line(_p(x, 0, z), _p(x - 0.02, 0, maxf(z - 0.14, z0)), Color(0.7, 0.8, 0.95, 0.35), 1.5)
	# Blinds, half open.
	for i in 12:
		var z := lerpf(z0, z1, (i + 0.5) / 12.0)
		draw_line(_p(x0, 0, z), _p(x1, 0, z), Color("#2a2620"), 5.0)
	var frame := PackedVector2Array([_p(x0, 0, z0), _p(x1, 0, z0), _p(x1, 0, z1), _p(x0, 0, z1), _p(x0, 0, z0)])
	draw_polyline(frame, Color("#2b2119"), 10.0)
	draw_line(_p((x0 + x1) * 0.5, 0, z0), _p((x0 + x1) * 0.5, 0, z1), Color("#2b2119"), 6.0)
	_quad(_p(x0 - 0.1, 0, z0 - 0.05), _p(x1 + 0.1, 0, z0 - 0.05), _p(x1 + 0.1, 0.12, z0 - 0.05), _p(x0 - 0.1, 0.12, z0 - 0.05), Color("#6b5038"))


## Cast-iron radiator under the window, flat against the wall, so nothing
## in the room can sort in front of or behind it wrongly.
func _draw_radiator() -> void:
	var x0 := 4.4
	var x1 := 6.2
	var y := 0.28
	var top := 0.55
	_quad(_p(x0, 0.02, top), _p(x1, 0.02, top), _p(x1, y, top), _p(x0, y, top), Color("#6a6a68"))
	_quad(_p(x0, y, 0.06), _p(x1, y, 0.06), _p(x1, y, top), _p(x0, y, top), Color("#4a4a48"))
	_quad(_p(x1, 0.02, 0.06), _p(x1, y, 0.06), _p(x1, y, top), _p(x1, 0.02, top), Color("#5a5a58"))
	var fins := 14
	for i in range(1, fins):
		var x := lerpf(x0, x1, float(i) / fins)
		draw_line(_p(x, y, 0.1), _p(x, y, top - 0.04), Color("#2e2e2c"), 3.0)
	# Feet.
	for x in [x0 + 0.08, x1 - 0.12]:
		_quad(_p(x, y - 0.05, 0), _p(x + 0.05, y - 0.05, 0), _p(x + 0.05, y - 0.05, 0.06), _p(x, y - 0.05, 0.06), Color("#2e2e2c"))


func _draw_door() -> void:
	var y0 := DOOR_Y.x
	var y1 := DOOR_Y.y
	if door_open:
		_quad(_p(0, y0, 0), _p(0, y1, 0), _p(0, y1, DOOR_Z), _p(0, y0, DOOR_Z), Color("#c9b98f"))
		# The door swung into the room.
		_quad(_p(0, y0, 0), _p(0.9, y0 - 0.25, 0), _p(0.9, y0 - 0.25, DOOR_Z), _p(0, y0, DOOR_Z), Color("#4a3626"))
	else:
		_quad(_p(0, y0, 0), _p(0, y1, 0), _p(0, y1, DOOR_Z), _p(0, y0, DOOR_Z), Color("#4a3626"))
		_quad(_p(0, y0 + 0.12, 1.15), _p(0, y1 - 0.12, 1.15), _p(0, y1 - 0.12, 1.9), _p(0, y0 + 0.12, 1.9), Color("#a7b0aa"))
		# His name on the glass, backward from inside.
		var along := (_p(0, y0, 0) - _p(0, y1, 0)).normalized()
		draw_set_transform_matrix(Transform2D(-along, Vector2(0, 1), _p(0, y0 + 0.16, 1.6)))
		draw_string(Noir.TITLE_FONT, Vector2(0, 0), "A. VALE", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#2a2a26"))
		draw_string(Noir.TITLE_FONT, Vector2(0, 18), "INVESTIGATIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#2a2a26"))
		draw_set_transform_matrix(Transform2D.IDENTITY)
	var frame := PackedVector2Array([_p(0, y0, 0), _p(0, y0, DOOR_Z), _p(0, y1, DOOR_Z), _p(0, y1, 0)])
	draw_polyline(frame, Color("#241a12"), 8.0)


func _draw_wall_things() -> void:
	# Framed licence on the left wall.
	_quad(_p(0, 2.6, 1.3), _p(0, 3.3, 1.3), _p(0, 3.3, 1.85), _p(0, 2.6, 1.85), Color("#2a2119"))
	_quad(_p(0, 2.66, 1.36), _p(0, 3.24, 1.36), _p(0, 3.24, 1.79), _p(0, 2.66, 1.79), Color("#cfc6b0"))
	# Calendar, February 1939.
	_quad(_p(0, 1.5, 1.2), _p(0, 1.95, 1.2), _p(0, 1.95, 1.8), _p(0, 1.5, 1.8), Color("#d8d0bc"))
	_quad(_p(0, 1.5, 1.62), _p(0, 1.95, 1.62), _p(0, 1.95, 1.8), _p(0, 1.5, 1.8), Color("#7a2a2a"))
	# Cork board over the bookcase: clippings, a photo, red string.
	_quad(_p(2.0, 0, 1.4), _p(3.4, 0, 1.4), _p(3.4, 0, 2.15), _p(2.0, 0, 2.15), Color("#7a5a3a"))
	var notes := [Vector3(2.1, 0, 1.95), Vector3(2.55, 0, 2.0), Vector3(2.95, 0, 1.9), Vector3(2.3, 0, 1.6), Vector3(2.85, 0, 1.55)]
	for n in notes:
		_quad(_p(n.x, 0, n.z - 0.16), _p(n.x + 0.3, 0, n.z - 0.16), _p(n.x + 0.3, 0, n.z + 0.05), _p(n.x, 0, n.z + 0.05), Color("#d8d0bc"))
	var pins := PackedVector2Array()
	for n in notes:
		pins.append(_p(n.x + 0.15, 0, n.z))
	draw_polyline(PackedVector2Array([pins[0], pins[3], pins[1], pins[4], pins[2]]), Color("#a02a2a"), 2.0)
	for pin in pins:
		draw_circle(pin, 3.0, Color("#c03030"))
	# Wall clock over the couch, running ten minutes slow.
	var c := _p(7.95, 0, 2.0)
	var x_axis := (_p(8.95, 0, 2.0) - c) * 0.22
	var up := (_p(7.95, 0, 3.0) - c) * 0.22
	var rim := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		rim.append(c + x_axis * cos(a) + up * sin(a))
	draw_colored_polygon(rim, Color("#2a2119"))
	var face := PackedVector2Array()
	for v in rim:
		face.append(c + (v - c) * 0.82)
	draw_colored_polygon(face, Color("#d8d0bc"))
	var minutes := fmod(_time / 60.0, 1.0)
	var m := TAU * (0.25 - minutes)
	var hr := TAU * (0.25 - (9.0 + minutes) / 12.0)
	draw_line(c, c + (x_axis * cos(m) + up * sin(m)) * 0.7, Color("#141414"), 2.0)
	draw_line(c, c + (x_axis * cos(hr) + up * sin(hr)) * 0.45, Color("#141414"), 3.0)
	var sec := TAU * (0.25 - fmod(floorf(_time), 60.0) / 60.0)
	draw_line(c, c + (x_axis * cos(sec) + up * sin(sec)) * 0.75, Color("#a02a2a"), 1.0)
