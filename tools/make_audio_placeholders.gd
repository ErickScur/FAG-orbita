extends SceneTree

const MIX_RATE: int = 22050
const MUSIC_DIR: String = "res://assets/placeholder/audio/music/"
const SFX_DIR: String = "res://assets/placeholder/audio/sfx/"
const MUSIC_SECONDS: float = 4.0
const MUSIC_GAIN: float = 0.20
const SFX_GAIN: float = 0.22

const MUSIC_SPECS: Dictionary = {
	"menu": {"base": 55.0, "partial": 110.0, "noise": 0.35, "bell": 0.0},
	"core": {"base": 65.0, "partial": 97.5, "noise": 0.08, "bell": 0.0},
	"greenhouse": {"base": 73.0, "partial": 109.5, "noise": 0.05, "bell": 584.0},
	"chassis_lost": {
		"base": 49.0, "partial": 73.5, "noise": 0.22, "bell": 0.0,
		"seconds": 6.0, "pulse": 2.0, "loop": false,
	},
	"game_over": {
		"base": 41.0, "partial": 61.5, "noise": 0.30, "bell": 0.0,
		"seconds": 10.0, "pulse": 1.0, "loop": false,
	},
	"sector_restored": {
		"base": 87.0, "partial": 130.5, "noise": 0.03, "bell": 659.0,
		"seconds": 15.0, "pulse": 3.0, "loop": false,
	},
	"reactor_critical": {
		"base": 58.0, "partial": 116.0, "noise": 0.14, "bell": 466.0,
		"seconds": 20.0, "pulse": 20.0, "loop": true,
	},
}

const SFX_SPECS: Dictionary = {
	"step_metal_1": {"kind": "click", "freq": 180.0, "dur": 0.08},
	"step_metal_2": {"kind": "click", "freq": 196.0, "dur": 0.08},
	"step_metal_3": {"kind": "click", "freq": 165.0, "dur": 0.08},
	"step_soil": {"kind": "noise", "freq": 140.0, "dur": 0.09},
	"jump": {"kind": "sweep", "freq": 300.0, "freq_to": 620.0, "dur": 0.14},
	"land": {"kind": "sweep", "freq": 260.0, "freq_to": 110.0, "dur": 0.14},
	"interact": {"kind": "beep", "freq": 880.0, "dur": 0.10},
	"terminal_breaker": {"kind": "click", "freq": 240.0, "dur": 0.10},
	"power_on": {"kind": "sweep", "freq": 110.0, "freq_to": 330.0, "dur": 0.30},
	"power_off": {"kind": "sweep", "freq": 330.0, "freq_to": 90.0, "dur": 0.30},
	"log_pickup": {"kind": "beep", "freq": 1046.0, "dur": 0.12},
	"pickup": {"kind": "beep", "freq": 1318.0, "dur": 0.10},
	"damage": {"kind": "noise", "freq": 420.0, "dur": 0.18},
	"low_integrity": {"kind": "beep", "freq": 196.0, "dur": 0.16},
	"flashlight": {"kind": "click", "freq": 520.0, "dur": 0.06},
	"door_open": {"kind": "sweep", "freq": 160.0, "freq_to": 380.0, "dur": 0.26},
	"door_close": {"kind": "sweep", "freq": 380.0, "freq_to": 150.0, "dur": 0.26},
	"reactor_alarm": {"kind": "beep", "freq": 660.0, "dur": 0.30},
	"ui_move": {"kind": "beep", "freq": 740.0, "dur": 0.06},
	"ui_confirm": {"kind": "beep", "freq": 988.0, "dur": 0.10},
	"ui_back": {"kind": "beep", "freq": 494.0, "dur": 0.10},
	"ui_error": {"kind": "buzz", "freq": 233.0, "dur": 0.16},
	"sr3_shutdown": {"kind": "sweep", "freq": 540.0, "freq_to": 120.0, "dur": 0.30},
	"chassis_lost": {"kind": "sweep", "freq": 300.0, "freq_to": 70.0, "dur": 0.30},
	"respawn": {"kind": "sweep", "freq": 220.0, "freq_to": 660.0, "dur": 0.28},
	"dialogue_blip": {"kind": "beep", "freq": 1200.0, "dur": 0.04},
	"tape_hiss": {"kind": "noise", "freq": 2400.0, "dur": 0.30},
	"sector_restored": {"kind": "sweep", "freq": 330.0, "freq_to": 880.0, "dur": 0.30},
	"secret_found": {"kind": "beep", "freq": 1568.0, "dur": 0.18},
	"claw_grab": {"kind": "click", "freq": 300.0, "dur": 0.09},
	"dash": {"kind": "sweep", "freq": 600.0, "freq_to": 1400.0, "dur": 0.12},
	"beam": {"kind": "noise", "freq": 1500.0, "dur": 0.22},
	"steam_hiss": {"kind": "noise", "freq": 3000.0, "dur": 0.28},
	"electric_buzz": {"kind": "buzz", "freq": 120.0, "dur": 0.25},
	"spores": {"kind": "noise", "freq": 700.0, "dur": 0.28},
	"plant_grow": {"kind": "sweep", "freq": 180.0, "freq_to": 520.0, "dur": 0.26},
}

var _rng := RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 20260919
	_ensure_dir(MUSIC_DIR)
	_ensure_dir(SFX_DIR)
	var written: int = 0
	for id: String in MUSIC_SPECS:
		if _write_wav(MUSIC_DIR + id + ".wav", _build_music(MUSIC_SPECS[id])):
			written += 1
	for sfx_name: String in SFX_SPECS:
		if _write_wav(SFX_DIR + sfx_name + ".wav", _build_sfx(SFX_SPECS[sfx_name])):
			written += 1
	print("placeholders de áudio gerados: %d" % written)
	quit(0)


func _ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


func _write_wav(path: String, samples: PackedFloat32Array) -> bool:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = _to_pcm16(samples)
	if stream.save_to_wav(path) != OK:
		push_error("falha ao gravar %s" % path)
		return false
	return true


func _to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for index: int in range(samples.size()):
		var value: float = clampf(samples[index], -1.0, 1.0)
		bytes.encode_s16(index * 2, int(roundf(value * 32767.0)))
	return bytes


func _build_music(spec: Dictionary) -> PackedFloat32Array:
	var seconds: float = float(spec.get("seconds", MUSIC_SECONDS))
	var looping: bool = bool(spec.get("loop", true))
	var count: int = int(MIX_RATE * seconds)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var base: float = float(spec.get("base", 55.0))
	var partial: float = float(spec.get("partial", 110.0))
	var noise_amount: float = float(spec.get("noise", 0.0))
	var bell: float = float(spec.get("bell", 0.0))
	var breath_cycles: float = maxf(1.0, roundf(float(spec.get("pulse", 1.0))))
	var base_cycles: float = roundf(base * seconds)
	var partial_cycles: float = roundf(partial * seconds)
	var bell_cycles: float = roundf(bell * seconds)
	var chime_cycles: float = maxf(1.0, roundf(2.0 * seconds / MUSIC_SECONDS))
	var filtered: float = 0.0
	var cutoff: float = 0.04
	for index: int in range(count):
		var phase: float = float(index) / float(count)
		filtered += (_rng.randf_range(-1.0, 1.0) - filtered) * cutoff
		var breath: float = 0.5 + 0.5 * sin(TAU * breath_cycles * phase)
		var value: float = sin(TAU * base_cycles * phase)
		value += 0.45 * sin(TAU * partial_cycles * phase)
		value += noise_amount * filtered * 6.0 * breath
		if bell > 0.0:
			var pulse: float = maxf(0.0, sin(TAU * chime_cycles * phase))
			value += 0.18 * sin(TAU * bell_cycles * phase) * pow(pulse, 6.0)
		var shape: float = value * MUSIC_GAIN * (0.75 + 0.25 * breath)
		samples[index] = shape if looping else shape * _tail(phase, seconds)
	return samples


func _tail(phase: float, seconds: float) -> float:
	var edge: float = clampf(0.5 / maxf(seconds, 0.001), 0.01, 0.25)
	if phase < edge:
		return phase / edge
	if phase > 1.0 - edge:
		return (1.0 - phase) / edge
	return 1.0


func _build_sfx(spec: Dictionary) -> PackedFloat32Array:
	var duration: float = float(spec.get("dur", 0.1))
	var count: int = int(MIX_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var kind: String = String(spec.get("kind", "beep"))
	var freq: float = float(spec.get("freq", 440.0))
	var freq_to: float = float(spec.get("freq_to", freq))
	var phase_accumulator: float = 0.0
	var filtered: float = 0.0
	var cutoff: float = clampf(freq / (float(MIX_RATE) * 0.5), 0.02, 1.0)
	for index: int in range(count):
		var t: float = float(index) / float(count)
		var envelope: float = _envelope(kind, t)
		var value: float = 0.0
		match kind:
			"beep":
				phase_accumulator += freq / float(MIX_RATE)
				value = sin(TAU * phase_accumulator)
			"sweep":
				phase_accumulator += lerpf(freq, freq_to, t) / float(MIX_RATE)
				value = sin(TAU * phase_accumulator)
			"buzz":
				phase_accumulator += freq / float(MIX_RATE)
				value = signf(sin(TAU * phase_accumulator)) * 0.6
			"noise":
				filtered += (_rng.randf_range(-1.0, 1.0) - filtered) * cutoff
				value = filtered * 3.0
			"click":
				filtered += (_rng.randf_range(-1.0, 1.0) - filtered) * 0.6
				phase_accumulator += freq / float(MIX_RATE)
				value = 0.6 * sin(TAU * phase_accumulator) + 0.5 * filtered
		samples[index] = clampf(value, -1.0, 1.0) * envelope * SFX_GAIN
	return samples


func _envelope(kind: String, t: float) -> float:
	var attack: float = 0.15 if kind == "beep" or kind == "buzz" else 0.03
	if t < attack:
		return t / attack
	var decay: float = (t - attack) / maxf(0.0001, 1.0 - attack)
	if kind == "click":
		return pow(1.0 - decay, 3.0)
	return pow(1.0 - decay, 1.6)
