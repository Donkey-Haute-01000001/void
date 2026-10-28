class_name IsoProp
extends Node2D
## Set dressing that is more than a box: the coat and hat on the rack, the
## bottle and glass, the telephone, the ashtray's smoke, the bookcase spines,
## the radio and the blanket on the couch. Placeholder art drawn in code.
## All coordinates are room tiles (x, y, z), like IsoBox.

var kind := ""
var _time := 0.0
var _anchor := Vector2.ZERO  # screen point of the anchor, before any parent offset


## `anchor` is the floor point the room depth-sorts this prop by.
func setup(prop_kind: String, anchor: Vector3) -> IsoProp:
	kind = prop_kind
	_anchor = Iso.to_screen(anchor)
	position = _anchor
	set_process(kind in ["ashtray"])
	return self


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## A room point in this node's drawing space.
func _p(x: float, y: float, z: float) -> Vector2:
	return Iso.to_screen(Vector3(x, y, z)) - _anchor


func _draw() -> void:
	match kind:
		"coat":
			_draw_coat()
		"bottle":
			_draw_bottle()
		"phone":
			_draw_phone()
		"ashtray":
			_draw_ashtray()
		"books":
			_draw_books()
		"radio":
			_draw_radio()
		"blanket":
			_draw_blanket()
		"papers":
			_draw_papers()


func _draw_coat() -> void:
	# Fedora on the top hook, overcoat hanging from the side hook.
	var top := _p(0.3, 4.1, 1.9)
	draw_rect(Rect2(top + Vector2(-26, -4), Vector2(52, 7)), Color("#1d1b1c"))
	draw_rect(Rect2(top + Vector2(-15, -18), Vector2(30, 15)), Color("#1d1b1c"))
	draw_rect(Rect2(top + Vector2(-15, -7), Vector2(30, 3)), Color("#5a2a26"))
	var hook := _p(0.3, 4.1, 1.75)
	var coat := Color("#2c2e34")
	draw_colored_polygon(PackedVector2Array([
		hook + Vector2(-6, 0), hook + Vector2(6, 0), hook + Vector2(24, 14), hook + Vector2(30, 118),
		hook + Vector2(4, 124), hook + Vector2(-22, 116), hook + Vector2(-20, 14)]), coat)
	draw_line(hook + Vector2(0, 2), hook + Vector2(4, 120), coat.darkened(0.4), 2.0)
	draw_line(hook + Vector2(-6, 4), hook + Vector2(-2, 44), coat.lightened(0.18), 2.0)
	draw_line(hook + Vector2(6, 4), hook + Vector2(10, 44), coat.lightened(0.18), 2.0)
	draw_line(hook + Vector2(22, 20), hook + Vector2(28, 100), coat.darkened(0.3), 3.0)


func _draw_bottle() -> void:
	# Last night's rye, empty, and the glass beside it.
	var b := _p(5.72, 2.62, 0.75)
	var glass := Color(0.32, 0.42, 0.3, 0.9)
	draw_colored_polygon(PackedVector2Array([
		b + Vector2(-8, 0), b + Vector2(8, 0), b + Vector2(8, -34), b + Vector2(4, -42),
		b + Vector2(3, -56), b + Vector2(-3, -56), b + Vector2(-4, -42), b + Vector2(-8, -34)]), glass)
	draw_line(b + Vector2(-4, -4), b + Vector2(-4, -32), Color(1, 1, 1, 0.35), 2.0)
	draw_rect(Rect2(b + Vector2(-8, -28), Vector2(16, 12)), Color("#c8b48a"))
	var g := _p(5.92, 2.86, 0.75)
	draw_colored_polygon(PackedVector2Array([
		g + Vector2(-7, 0), g + Vector2(7, 0), g + Vector2(9, -18), g + Vector2(-9, -18)]), Color(0.8, 0.85, 0.9, 0.35))
	draw_colored_polygon(PackedVector2Array([
		g + Vector2(-7, 0), g + Vector2(7, 0), g + Vector2(7.5, -4), g + Vector2(-7.5, -4)]), Color(0.75, 0.5, 0.2, 0.8))


func _draw_phone() -> void:
	# Candlestick telephone, receiver on its hook.
	var b := _p(5.75, 3.3, 0.75)
	var black := Color("#141416")
	draw_set_transform(b, 0.0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 12.0, black)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(b + Vector2(-3, -46), Vector2(6, 46)), black)
	draw_circle(b + Vector2(0, -50), 7.0, black)
	draw_line(b + Vector2(4, -36), b + Vector2(12, -40), black, 3.0)
	draw_rect(Rect2(b + Vector2(10, -48), Vector2(6, 22)), black)
	draw_line(b + Vector2(-2, -46), b + Vector2(-2, -10), Color(1, 1, 1, 0.12), 1.0)


func _draw_ashtray() -> void:
	var a := _p(3.95, 3.3, 0.75)
	draw_set_transform(a, 0.0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, 14.0, Color("#3a3a3c"))
	draw_circle(Vector2.ZERO, 9.0, Color("#1a1a1a"))
	draw_set_transform(Vector2.ZERO)
	draw_line(a + Vector2(-2, -2), a + Vector2(14, -6), Color("#d8d0c0"), 3.0)
	draw_circle(a + Vector2(14, -6), 2.0, Color(1.0, 0.45, 0.15))
	# A curl of smoke from the cigarette he forgot about.
	for i in 14:
		var t := fmod(_time * 0.35 + i / 14.0, 1.0)
		var rise := t * 120.0
		var x := 14.0 + sin(t * 7.0 + _time * 0.8) * (4.0 + t * 14.0)
		draw_circle(a + Vector2(x, -8 - rise), 2.0 + t * 7.0, Color(0.8, 0.82, 0.88, 0.16 * (1.0 - t)))


func _draw_books() -> void:
	# Spines on the bookcase front (the +y face at y = 0.6), three shelves.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1939
	var colors := [Color("#5a2a26"), Color("#2a3a4a"), Color("#3a4a2a"), Color("#6a5a3a"), Color("#2a2a2a"), Color("#7a6a4a")]
	for shelf in 3:
		var z0 := 0.08 + shelf * 0.38
		var x := 2.05
		while x < 3.3:
			var w := rng.randf_range(0.04, 0.09)
			var h := rng.randf_range(0.22, 0.32)
			if rng.randf() < 0.12:
				x += 0.1
				continue
			var c: Color = colors[rng.randi() % colors.size()]
			draw_colored_polygon(PackedVector2Array([
				_p(x, 0.6, z0), _p(x + w, 0.6, z0), _p(x + w, 0.6, z0 + h), _p(x, 0.6, z0 + h)]), c)
			x += w + 0.01


func _draw_radio() -> void:
	# Cathedral radio on the bookcase, dial glowing.
	var b := _p(2.75, 0.4, 1.2)
	draw_colored_polygon(PackedVector2Array([
		b + Vector2(-20, 0), b + Vector2(20, 0), b + Vector2(20, -30), b + Vector2(12, -44),
		b + Vector2(-12, -44), b + Vector2(-20, -30)]), Color("#5a3a22"))
	for i in 4:
		draw_line(b + Vector2(-10 + i * 7, -36), b + Vector2(-10 + i * 7, -14), Color("#2a1a10"), 2.0)
	draw_circle(b + Vector2(0, -8), 4.0, Color(1.0, 0.75, 0.35))


func _draw_blanket() -> void:
	# A blanket thrown over the couch: he slept here.
	draw_colored_polygon(PackedVector2Array([
		_p(7.3, 0.35, 0.52), _p(8.3, 0.35, 0.52), _p(8.4, 0.95, 0.5), _p(8.2, 1.02, 0.2), _p(7.6, 1.02, 0.25), _p(7.2, 0.95, 0.5)]),
		Color("#4a5a6a"))
	draw_line(_p(7.35, 0.6, 0.53), _p(8.25, 0.7, 0.53), Color("#3a4858"), 3.0)
	draw_colored_polygon(PackedVector2Array([
		_p(8.35, 0.3, 0.55), _p(8.75, 0.3, 0.55), _p(8.75, 0.8, 0.6), _p(8.35, 0.8, 0.6)]), Color("#cfc8b8"))


func _draw_papers() -> void:
	# Crumpled drafts that missed the bin.
	for spot in [Vector2(6.55, 3.85), Vector2(6.85, 3.3), Vector2(6.3, 4.2), Vector2(7.05, 4.0)]:
		var c := _p(spot.x, spot.y, 0.0)
		draw_circle(c + Vector2(0, -6), 7.0, Color("#d8d2c4"))
		draw_line(c + Vector2(-4, -8), c + Vector2(3, -4), Color("#a8a294"), 1.5)
