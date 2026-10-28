extends Node
## Placeholder sound, synthesised in code so the slice needs no audio files.
## Swap any of these for recorded sounds later.

const MIX_RATE := 22050

var _knock_player := AudioStreamPlayer.new()
var _rain_player := AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_knock_player)
	add_child(_rain_player)
	_knock_player.stream = _make_knocks(3)
	_rain_player.stream = _make_rain()
	_rain_player.volume_db = -22.0


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
