extends Node
## Placeholder sound, synthesised in code so the slice needs no audio files.
## Swap any of these for recorded sounds later.

const MIX_RATE := 22050

var _knock_player := AudioStreamPlayer.new()
var _rain_player := AudioStreamPlayer.new()
## Dice sounds, each on its own player pool so rapid ticks can overlap.
var _sounds := {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	add_child(_knock_player)
	add_child(_rain_player)
	_knock_player.stream = _make_knocks(3)
	_rain_player.stream = _make_rain()
	_rain_player.volume_db = -22.0
	_sounds = {
		"tick": _make_tick(),
		"thud": _make_thud(),
		"hit": _make_hit(),
		"heart": _make_heartbeat(),
		"win": _make_chord([220.0, 277.2, 329.6, 440.0], 1.4),
		"lose": _make_boom(),
	}
	for i in 8:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


## Play a dice sound by name: tick, thud, hit, heart, win or lose.
func play(sound: String, pitch := 1.0, volume_db := 0.0) -> void:
	for player in _players:
		if not player.playing:
			player.stream = _sounds[sound]
			player.pitch_scale = pitch
			player.volume_db = volume_db
			player.play()
			return


func play_knock() -> void:
	_knock_player.play()


func start_rain() -> void:
	if not _rain_player.playing:
		_rain_player.play()


func stop_rain() -> void:
	_rain_player.stop()


## Three dull thumps on a wooden door.
func _make_knocks(count: int) -> AudioStreamWAV:
	var gap := int(MIX_RATE * 0.32)
	var length := gap * count + int(MIX_RATE * 0.3)
	var samples := PackedFloat32Array()
	samples.resize(length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in count:
		var start := k * gap
		for i in int(MIX_RATE * 0.12):
			var t := float(i) / MIX_RATE
			var env := exp(-t * 38.0)
			var tone := sin(TAU * 95.0 * t) * 0.8 + sin(TAU * 210.0 * t) * 0.25
			var noise := rng.randf_range(-1.0, 1.0) * exp(-t * 120.0) * 0.5
			samples[start + i] += (tone + noise) * env * 0.9
	return _to_wav(samples, false)


## A dry click, like a die skittering on wood.
func _make_tick() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 0.03))
	var rng := RandomNumberGenerator.new()
	for i in samples.size():
		var t := float(i) / MIX_RATE
		samples[i] = (rng.randf_range(-1.0, 1.0) * 0.6 + sin(TAU * 1800.0 * t) * 0.4) * exp(-t * 260.0) * 0.6
	return _to_wav(samples, false)


## A die landing: a short wooden knock.
func _make_thud() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 0.18))
	var rng := RandomNumberGenerator.new()
	for i in samples.size():
		var t := float(i) / MIX_RATE
		samples[i] = (sin(TAU * 140.0 * t) + rng.randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.6) * exp(-t * 30.0) * 0.8
	return _to_wav(samples, false)


## A success on one die: a bright ping.
func _make_hit() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 0.35))
	for i in samples.size():
		var t := float(i) / MIX_RATE
		samples[i] = (sin(TAU * 880.0 * t) * 0.6 + sin(TAU * 1320.0 * t) * 0.3) * exp(-t * 9.0) * 0.5
	return _to_wav(samples, false)


## One heartbeat: two low thumps.
func _make_heartbeat() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 0.5))
	for beat in [0.0, 0.17]:
		var start := int(beat * MIX_RATE)
		for i in int(MIX_RATE * 0.15):
			var t := float(i) / MIX_RATE
			samples[start + i] += sin(TAU * 55.0 * t) * exp(-t * 25.0) * (1.0 if beat == 0.0 else 0.7)
	return _to_wav(samples, false)


## A rising chord for a passed check.
func _make_chord(freqs: Array, seconds: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * seconds))
	for i in samples.size():
		var t := float(i) / MIX_RATE
		var v := 0.0
		for k in freqs.size():
			var on := clampf((t - k * 0.06) * 30.0, 0.0, 1.0)
			v += sin(TAU * freqs[k] * t) * on
		samples[i] = v / freqs.size() * exp(-t * 2.2) * 0.8
	return _to_wav(samples, false)


## A low boom for a failed check.
func _make_boom() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(MIX_RATE * 1.2))
	var rng := RandomNumberGenerator.new()
	var last := 0.0
	for i in samples.size():
		var t := float(i) / MIX_RATE
		last = lerpf(last, rng.randf_range(-1.0, 1.0), 0.08)
		samples[i] = (sin(TAU * (60.0 - t * 20.0) * t) * 0.8 + last * 0.6) * exp(-t * 3.0) * 0.9
	return _to_wav(samples, false)


## A soft, looping rain hiss: low-passed noise.
func _make_rain() -> AudioStreamWAV:
	var length := MIX_RATE * 3
	var samples := PackedFloat32Array()
	samples.resize(length)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var last := 0.0
	for i in length:
		last = lerpf(last, rng.randf_range(-1.0, 1.0), 0.18)
		samples[i] = last
	return _to_wav(samples, true)


func _to_wav(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
