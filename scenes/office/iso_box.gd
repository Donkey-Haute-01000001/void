class_name IsoBox
extends Node2D
## A shaded box in the isometric room: furniture, props, anything solid.
## The node sits at its front corner on screen so the room can depth-sort it.

@export var origin := Vector3.ZERO
@export var size := Vector3.ONE
@export var color := Color("#3a3029")
## Horizontal drawer lines on the front (+y) face, for cabinets and desks.
@export var drawers := 0

var highlighted := false
var _faces: Array[PackedVector2Array] = []


func setup(at: Vector3, box_size: Vector3, box_color: Color) -> IsoBox:
	origin = at
	size = box_size
	color = box_color
	_build()
	return self


func _build() -> void:
	position = Iso.to_screen(Vector3(origin.x + size.x, origin.y + size.y, origin.z))
	var o := origin
	var s := size
	var c := func(x: float, y: float, z: float) -> Vector2:
		return Iso.to_screen(Vector3(o.x + x, o.y + y, o.z + z)) - position
	_faces = [
		PackedVector2Array([c.call(0, 0, s.z), c.call(s.x, 0, s.z), c.call(s.x, s.y, s.z), c.call(0, s.y, s.z)]),
		PackedVector2Array([c.call(s.x, 0, 0), c.call(s.x, s.y, 0), c.call(s.x, s.y, s.z), c.call(s.x, 0, s.z)]),
		PackedVector2Array([c.call(0, s.y, 0), c.call(s.x, s.y, 0), c.call(s.x, s.y, s.z), c.call(0, s.y, s.z)]),
	]
	queue_redraw()


## True when a screen point lands on any visible face.
func hit(point: Vector2) -> bool:
	var local := point - global_position
	for face in _faces:
		if Geometry2D.is_point_in_polygon(local, face):
			return true
	return false


## Where to float a label over the box.
func top_center() -> Vector2:
	return global_position + (_faces[0][0] + _faces[0][2]) * 0.5


func _draw() -> void:
	draw_colored_polygon(_faces[0], color.lightened(0.12))
	draw_colored_polygon(_faces[1], color)
	draw_colored_polygon(_faces[2], color.darkened(0.35))
	for i in range(1, drawers + 1):
		var t := float(i) / (drawers + 1)
		var f := _faces[2]
		draw_line(f[0].lerp(f[3], t), f[1].lerp(f[2], t), color.darkened(0.6), 2.0)
		var mid := f[0].lerp(f[3], t - 0.5 / (drawers + 1)).lerp(f[1].lerp(f[2], t - 0.5 / (drawers + 1)), 0.5)
		draw_line(mid - Vector2(8, -4), mid + Vector2(8, -4), Color("#b09060"), 3.0)
	if highlighted:
		for face in _faces:
			var outline := face.duplicate()
			outline.append(face[0])
			draw_polyline(outline, Color("#e0b060"), 2.5)
