class_name DiceRoll
extends CanvasLayer
## The dice check as a show. The dice rattle in your hand until you click to
## throw, tumble with clicking ticks, land one by one with a thud, and every
## success fills a slot with a ping that climbs in pitch. When everything
## rides on the last die, the room drains away, a heartbeat starts and the die
## spins longer. Then the verdict slams down with a flash and a shake.

## Asks the room to shake by this many pixels.
signal impact(strength: float)
signal _clicked

const DIE := 128.0
const GAP := 26.0

var _result
var _skill_name := ""
var _root: Control
var _shade: ColorRect
var _flash: ColorRect
var _dice: Array[PanelContainer] = []
var _numbers: Array[Label] = []
var _slots: Array[Panel] = []
var _prompt: Label
var _banner: Label
var _holding := false
var _waiting := false
var _time := 0.0


func play(skill_name: String, result) -> void:
	_skill_name = skill_name
	_result = result
	layer = 32
	_build()

	# Fade in, then rattle the dice until the player throws.
	create_tween().tween_property(_shade, "color:a", 0.82, 0.25)
	_root.modulate.a = 0.0
	await create_tween().tween_property(_root, "modulate:a", 1.0, 0.2).finished
	_holding = true
	_prompt.text = "CLICK TO THROW"
	await _wait_click()
	_holding = false
	_prompt.text = ""
	for d in _dice:
		d.rotation = 0.0

	var hits := 0
	for i in _dice.size():
		var remaining: int = _dice.size() - i
		var still_needed: int = _result.needed - hits
		# The last die with the check still open gets the full slow-motion;
		# earlier dice that must all hit just get a warning.
		var deciding := still_needed > 0 and remaining == 1
		if still_needed > 1 and still_needed == remaining:
			_banner.text = "NO ROOM FOR A MISS"
			_banner.modulate.a = 1.0
		elif not deciding:
			_banner.modulate.a = 0.0
		var roll: int = _result.rolls[i]
		var hit: bool = roll <= _result.skill
		await _tumble(i, roll, deciding)
		if hit:
			hits += 1
			_land_hit(i, hits)
		else:
			_land_miss(i)
		await get_tree().create_timer(0.28).timeout

	await _verdict(hits)
	_prompt.text = "CLICK TO CONTINUE"
	await _wait_click()
	var out := create_tween().set_parallel()
	out.tween_property(_root, "modulate:a", 0.0, 0.2)
	out.tween_property(_shade, "color:a", 0.0, 0.25)
	await out.finished


func _process(delta: float) -> void:
	_time += delta
	if _holding:
		# Dice shaking in a closed fist.
		for d in _dice:
			d.rotation = randf_range(-0.12, 0.12)
			d.position.y = d.get_meta("home_y") + randf_range(-5, 5)
		_prompt.modulate.a = 0.55 + 0.45 * sin(_time * 6.0)
		if randf() < 0.18:
			Sfx.play("tick", randf_range(0.7, 1.0), -12.0)
	elif _prompt.text != "":
		_prompt.modulate.a = 0.55 + 0.45 * sin(_time * 6.0)


func _input(event: InputEvent) -> void:
	if not _waiting:
		return
	var click: bool = event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if click or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		_clicked.emit()


func _wait_click() -> void:
	_waiting = true
	await _clicked
	_waiting = false


## Spin one die through random faces, slowing down until it shows `roll`.
## The deciding die gets the full treatment.
func _tumble(i: int, roll: int, deciding: bool) -> void:
	var die := _dice[i]
	var number := _numbers[i]
	var spins := 18
	if deciding:
		_banner.text = "EVERYTHING ON THIS ONE"
		_banner.modulate.a = 1.0
		for d in _dice.size():
			if d != i:
				create_tween().tween_property(_dice[d], "modulate:a", 0.25, 0.3)
		create_tween().tween_property(_shade, "color:a", 0.95, 0.4)
		create_tween().tween_property(die, "scale", Vector2(1.35, 1.35), 0.4).set_trans(Tween.TRANS_BACK)
		for beat in 2:
			Sfx.play("heart", 1.0, -2.0)
			_jolt(3.0)
			await get_tree().create_timer(0.55 - beat * 0.08).timeout
		spins = 24
	for s in spins:
		var t := float(s) / spins
		number.text = str(randi_range(1, 10))
		die.rotation = randf_range(-0.6, 0.6) * (1.0 - t)
		Sfx.play("tick", randf_range(0.9, 1.3), -6.0)
		# Ease out: fast flicker first, crawling at the end.
		await get_tree().create_timer(lerpf(0.025, 0.16 if deciding else 0.07, t * t)).timeout
	number.text = str(roll)
	die.rotation = 0.0
	if deciding:
		await get_tree().create_timer(0.35).timeout
		_banner.modulate.a = 0.0
		for d in _dice.size():
			create_tween().tween_property(_dice[d], "modulate:a", 1.0, 0.2)
		create_tween().tween_property(_shade, "color:a", 0.82, 0.3)


func _land_hit(i: int, hits: int) -> void:
	var die := _dice[i]
	die.add_theme_stylebox_override("panel", Noir.box(Noir.PAPER, Noir.PAPER, 0))
	_numbers[i].add_theme_color_override("font_color", Noir.INK)
	_punch(die, 1.5)
	Sfx.play("thud")
	Sfx.play("hit", 1.0 + 0.15 * (hits - 1))
	_jolt(6.0)
	_burst(die.position + die.size * 0.5, Noir.PAPER, 18)
	if hits <= _slots.size():
		var slot := _slots[hits - 1]
		slot.add_theme_stylebox_override("panel", Noir.box(Noir.PAPER, Noir.PAPER, 0))
		_punch(slot, 1.8)


func _land_miss(i: int) -> void:
	var die := _dice[i]
	die.add_theme_stylebox_override("panel", Noir.box(Color(0.06, 0.06, 0.06), Color(1, 1, 1, 0.15), 0))
	_numbers[i].add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	_punch(die, 1.15)
	Sfx.play("thud", 0.8)


func _verdict(hits: int) -> void:
	var passed: bool = _result.passed
	var odds := Dice.odds(_result.skill, _result.dice, _result.needed)
	var stamp := Noir.label("SUCCESS" if passed else "FAILURE", Noir.DISPLAY_FONT, 150,
		Noir.PAPER if passed else Noir.BLOOD)
	stamp.add_theme_color_override("font_outline_color", Color.BLACK)
	stamp.add_theme_constant_override("outline_size", 18)
	_root.add_child(stamp)
	await get_tree().process_frame
	stamp.position = Vector2((1920 - stamp.size.x) * 0.5, 640)
	stamp.pivot_offset = stamp.size * 0.5
	stamp.rotation = deg_to_rad(-7)
	stamp.scale = Vector2(4, 4)
	stamp.modulate.a = 0.0
	var t := create_tween().set_parallel()
	t.tween_property(stamp, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	t.tween_property(stamp, "modulate:a", 1.0, 0.1)
	await t.finished

	_flash.color = Color(1, 1, 1, 0.75) if passed else Color(Noir.BLOOD, 0.7)
	create_tween().tween_property(_flash, "color:a", 0.0, 0.5)
	Sfx.play("win" if passed else "lose")
	_jolt(22.0)
	_burst(stamp.position + stamp.size * 0.5, Noir.PAPER if passed else Noir.BLOOD, 60)

	var tag := ""
	if passed and hits == _result.dice:
		tag = "FLAWLESS"
	elif passed and odds < 0.5:
		tag = "AGAINST THE ODDS"
	elif not passed and odds > 0.75:
		tag = "THE ODDS WERE %d%%. IT HAPPENS." % roundi(odds * 100)
	if tag != "":
		_banner.text = tag
		_banner.modulate.a = 0.0
		create_tween().tween_property(_banner, "modulate:a", 1.0, 0.3).set_delay(0.3)


## Shake the dice table and ask the room behind it to shake too.
func _jolt(strength: float) -> void:
	impact.emit(strength)
	var t := create_tween()
	for i in 6:
		t.tween_property(_root, "position", Vector2(randf_range(-strength, strength), randf_range(-strength, strength) * 0.6), 0.03)
	t.tween_property(_root, "position", Vector2.ZERO, 0.04)


func _punch(node: Control, amount: float) -> void:
	node.pivot_offset = node.size * 0.5
	node.scale = Vector2(amount, amount)
	create_tween().tween_property(node, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _burst(at: Vector2, color: Color, amount: int) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.8
	p.spread = 180.0
	p.initial_velocity_min = 250.0
	p.initial_velocity_max = 650.0
	p.gravity = Vector2(0, 1100)
	p.scale_amount_min = 3.0
	p.scale_amount_max = 8.0
	p.color = color
	_root.add_child(p)
	p.emitting = true
	get_tree().create_timer(1.2).timeout.connect(p.queue_free)


func _build() -> void:
	_shade = ColorRect.new()
	_shade.color = Color(0, 0, 0, 0)
	_shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shade)
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var title := Noir.label(_skill_name.to_upper(), Noir.DISPLAY_FONT, 96, Noir.PAPER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(1920, 110)
	title.position = Vector2(0, 150)
	_root.add_child(title)
	var odds := roundi(Dice.odds(_result.skill, _result.dice, _result.needed) * 100)
	var rule := Noir.label("EACH DIE NEEDS %d OR UNDER   ·   %d%% CHANCE" % [_result.skill, odds],
		Noir.TITLE_FONT, 34, Noir.DIM)
	rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rule.size = Vector2(1920, 40)
	rule.position = Vector2(0, 270)
	_root.add_child(rule)

	# One slot per success needed; they fill as dice hit.
	var slot_w := 46.0
	var slots_x: float = (1920 - (_result.needed * (slot_w + 12) - 12)) * 0.5
	var need := Noir.label("NEED", Noir.TITLE_FONT, 30, Noir.DIM)
	need.position = Vector2(slots_x - 80, 332)
	_root.add_child(need)
	for s in _result.needed:
		var slot := Panel.new()
		slot.add_theme_stylebox_override("panel", Noir.box(Color(0, 0, 0, 0), Color(1, 1, 1, 0.5), 0))
		slot.position = Vector2(slots_x + s * (slot_w + 12), 330)
		slot.size = Vector2(slot_w, 30)
		_root.add_child(slot)
		_slots.append(slot)

	var count: int = _result.dice
	var row_x: float = (1920 - (count * DIE + (count - 1) * GAP)) * 0.5
	for i in count:
		var die := PanelContainer.new()
		die.add_theme_stylebox_override("panel", Noir.box(Color(0.02, 0.02, 0.02), Noir.PAPER, 0))
		die.position = Vector2(row_x + i * (DIE + GAP), 420)
		die.size = Vector2(DIE, DIE)
		die.custom_minimum_size = Vector2(DIE, DIE)
		die.pivot_offset = Vector2(DIE, DIE) * 0.5
		die.set_meta("home_y", 420.0)
		var n := Noir.label("?", Noir.DISPLAY_FONT, 84, Noir.PAPER)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		die.add_child(n)
		_root.add_child(die)
		_dice.append(die)
		_numbers.append(n)

	_banner = Noir.label("", Noir.TITLE_FONT, 44, Noir.BLOOD)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.size = Vector2(1920, 50)
	_banner.position = Vector2(0, 580)
	_root.add_child(_banner)
	_prompt = Noir.label("", Noir.TITLE_FONT, 36, Noir.PAPER)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.size = Vector2(1920, 40)
	_prompt.position = Vector2(0, 880)
	_root.add_child(_prompt)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_flash)
