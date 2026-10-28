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
	# Crumpled drafts that missed the bin: jagged balls with creases, lit from
	# the top, plus one sheet that was only half screwed up.
	var rng := RandomNumberGenerator.new()
	rng.seed = 39
	var balls := [[Vector2(6.5, 3.95), 14.0], [Vector2(6.9, 3.3), 11.0], [Vector2(6.25, 4.25), 12.0],
		[Vector2(7.1, 4.05), 15.0], [Vector2(6.75, 4.45), 10.0]]
	for b in balls:
		var r: float = b[1]
		var c: Vector2 = _p(b[0].x, b[0].y, 0.0) + Vector2(0, -r * 0.75)
		draw_set_transform(_p(b[0].x, b[0].y, 0.0), 0.0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, r * 1.1, Color(0, 0, 0, 0.5))
		draw_set_transform(Vector2.ZERO)
		var outline := PackedVector2Array()
		for i in 14:
			var a := TAU * i / 14.0
			outline.append(c + Vector2(cos(a), sin(a) * 0.85) * r * rng.randf_range(0.72, 1.12))
		# Facets: each wedge catches the light differently, brighter on top.
		var core := c + Vector2(rng.randf_range(-2, 2), rng.randf_range(-2, 1))
		for i in outline.size():
			var p1 := outline[i]
			var p2 := outline[(i + 1) % outline.size()]
			var up := -((p1 + p2) * 0.5 - c).normalized().y
			var shade := clampf(0.5 + up * 0.25 + rng.randf_range(-0.18, 0.18), 0.2, 0.85)
			draw_colored_polygon(PackedVector2Array([core, p1, p2]), Color(shade, shade, shade * 0.97))
		for i in 5:
			var from := c + Vector2(rng.randf_range(-r, r), rng.randf_range(-r, r)) * 0.55
			var mid := from + Vector2(rng.randf_range(-r, r), rng.randf_range(-r, r)) * 0.45
			draw_polyline(PackedVector2Array([from, mid, mid + Vector2(rng.randf_range(-5, 5), rng.randf_range(-5, 5))]),
				Color(0.15, 0.15, 0.15, 0.8), 1.2)
	# The half-crumpled sheet, flat on the floor with its corners folded up.
	var s := [_p(6.0, 3.75, 0), _p(6.32, 3.7, 0.02), _p(6.38, 3.98, 0), _p(6.1, 4.08, 0.03), _p(5.98, 3.95, 0.05)]
	draw_colored_polygon(PackedVector2Array(s), Color("#9e9a92"))
	draw_colored_polygon(PackedVector2Array([s[0], s[1], s[1].lerp(s[3], 0.5)]), Color("#c4c0b8"))
	draw_colored_polygon(PackedVector2Array([s[3], s[4], s[1].lerp(s[3], 0.5)]), Color("#6e6a64"))
	draw_polyline(PackedVector2Array([s[0].lerp(s[2], 0.2), s[1].lerp(s[3], 0.5), s[4].lerp(s[2], 0.7)]), Color("#2a2a2a"), 1.2)
	for line in 4:
		var t := 0.25 + line * 0.15
		draw_line(s[0].lerp(s[4], t) + Vector2(4, 0), s[1].lerp(s[2], t) - Vector2(4, 0), Color(0.3, 0.3, 0.35, 0.5), 1.0)
