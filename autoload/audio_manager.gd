extends Node

const MUSIC: Dictionary = {
	&"menu": "res://assets/audio/music/menu.ogg",
	&"core": "res://assets/audio/music/core.ogg",
	&"greenhouse": "res://assets/audio/music/greenhouse.ogg",
}
const SFX_DIR: String = "res://assets/audio/sfx/"
const PLACEHOLDER_MUSIC_DIR: String = "res://assets/placeholder/audio/music/"
const PLACEHOLDER_SFX_DIR: String = "res://assets/placeholder/audio/sfx/"
const EXTENSIONS: PackedStringArray = [".ogg", ".wav", ".mp3"]
const SFX_POOL_SIZE: int = 8
const SFX_VARIANTS: int = 8
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_VOICE: StringName = &"Voice"

var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _music_active: AudioStreamPlayer = null
var _voice: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _current_music: StringName = &""
var _sfx_cache: Dictionary = {}
var _warned: Dictionary = {}
var _fade_tween: Tween = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player("MusicA", BUS_MUSIC)
	_music_b = _make_player("MusicB", BUS_MUSIC)
	_music_active = _music_a
	_voice = _make_player("Voice", BUS_VOICE)
	for index: int in range(SFX_POOL_SIZE):
		_sfx_pool.append(_make_player("Sfx%d" % index, BUS_SFX))
	apply_volumes()


func _exit_tree() -> void:
	stop_all()
	_sfx_cache.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH:
		stop_all()


func stop_all() -> void:
	_kill_tween()
	_current_music = &""
	for player: AudioStreamPlayer in _all_players():
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func play_music(id: StringName, fade: float = -1.0) -> void:
	if id == _current_music and _music_active != null and _music_active.playing:
		return
	if not MUSIC.has(id):
		_warn_once("music:%s" % id, "AudioManager: trilha desconhecida '%s'" % id)
		return
	var path: String = _resolve_music_path(id)
	if path.is_empty():
		_warn_once("music:%s" % id, "AudioManager: arquivo ausente para a trilha '%s'" % id)
		return
	var stream: AudioStream = _prepare_loop(load(path))
	if stream == null:
		_warn_once("music:%s" % id, "AudioManager: trilha inválida '%s'" % id)
		return
	var duration: float = fade if fade >= 0.0 else Balance.MUSIC_FADE_TIME
	var outgoing: AudioStreamPlayer = _music_active
	var incoming: AudioStreamPlayer = _music_b if _music_active == _music_a else _music_a
	_current_music = id
	_music_active = incoming
	incoming.stream = stream
	incoming.volume_db = AudioMath.SILENT_DB if duration > 0.0 else 0.0
	incoming.play()
	_kill_tween()
	if duration <= 0.0:
		incoming.volume_db = 0.0
		outgoing.stop()
		return
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(incoming, "volume_db", 0.0, duration)
	if outgoing.playing:
		_fade_tween.tween_property(outgoing, "volume_db", AudioMath.SILENT_DB, duration)
		_fade_tween.chain().tween_callback(outgoing.stop)


func stop_music(fade: float = -1.0) -> void:
	_current_music = &""
	if _music_active == null or not _music_active.playing:
		return
	var duration: float = fade if fade >= 0.0 else Balance.MUSIC_FADE_TIME
	var player: AudioStreamPlayer = _music_active
	_kill_tween()
	if duration <= 0.0:
		player.stop()
		return
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.tween_property(player, "volume_db", AudioMath.SILENT_DB, duration)
	_fade_tween.tween_callback(player.stop)


func play_sfx(sfx_name: StringName) -> void:
	var streams: Array = _streams_for(sfx_name)
	if streams.is_empty():
		_warn_once("sfx:%s" % sfx_name, "AudioManager: efeito sonoro ausente '%s'" % sfx_name)
		return
	var stream: AudioStream = streams[0] if streams.size() == 1 else streams[randi() % streams.size()]
	var player: AudioStreamPlayer = _next_sfx_player()
	if player == null:
		return
	player.stream = stream
	player.volume_db = 0.0
	player.play()


func play_voice(stream: AudioStream) -> void:
	if _voice == null or stream == null:
		return
	_voice.stream = stream
	_voice.volume_db = 0.0
	_voice.play()


func stop_voice() -> void:
	if _voice != null:
		_voice.stop()


func set_bus_volume(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		_warn_once("bus:%s" % bus, "AudioManager: bus inexistente '%s'" % bus)
		return
	var value: float = clampf(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(index, AudioMath.linear_to_db_safe(value))
	AudioServer.set_bus_mute(index, AudioMath.is_silent(value))
	match bus:
		BUS_MASTER:
			Settings.master_volume = value
		BUS_MUSIC:
			Settings.music_volume = value
		BUS_SFX:
			Settings.sfx_volume = value
		BUS_VOICE:
			Settings.voice_volume = value


func get_bus_volume(bus: StringName) -> float:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return 0.0
	if AudioServer.is_bus_mute(index):
		return 0.0
	return AudioMath.db_to_linear_safe(AudioServer.get_bus_volume_db(index))


func apply_volumes() -> void:
	set_bus_volume(BUS_MASTER, Settings.master_volume)
	set_bus_volume(BUS_MUSIC, Settings.music_volume)
	set_bus_volume(BUS_SFX, Settings.sfx_volume)
	set_bus_volume(BUS_VOICE, Settings.voice_volume)


func current_music() -> StringName:
	return _current_music


func _make_player(player_name: String, bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus
	player.volume_db = 0.0
	add_child(player)
	return player


func _all_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = []
	for player: AudioStreamPlayer in [_music_a, _music_b, _voice]:
		if player != null:
			players.append(player)
	players.append_array(_sfx_pool)
	return players


func _next_sfx_player() -> AudioStreamPlayer:
	if _sfx_pool.is_empty():
		return null
	for player: AudioStreamPlayer in _sfx_pool:
		if not player.playing:
			return player
	var oldest: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx_pool.size()
	return oldest


func _streams_for(sfx_name: StringName) -> Array:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]
	var streams: Array = []
	var direct: String = _resolve_sfx_path(String(sfx_name))
	if not direct.is_empty():
		streams.append(load(direct))
	else:
		for index: int in range(1, SFX_VARIANTS + 1):
			var variant: String = _resolve_sfx_path("%s_%d" % [sfx_name, index])
			if variant.is_empty():
				break
			streams.append(load(variant))
	_sfx_cache[sfx_name] = streams
	return streams


func _resolve_sfx_path(base_name: String) -> String:
	for extension: String in EXTENSIONS:
		var final_path: String = SFX_DIR + base_name + extension
		if ResourceLoader.exists(final_path):
			return final_path
	for extension: String in EXTENSIONS:
		var placeholder: String = PLACEHOLDER_SFX_DIR + base_name + extension
		if ResourceLoader.exists(placeholder):
			return placeholder
	return ""


func _resolve_music_path(id: StringName) -> String:
	var final_path: String = String(MUSIC.get(id, ""))
	if not final_path.is_empty() and ResourceLoader.exists(final_path):
		return final_path
	var base_name: String = final_path.get_file().get_basename()
	for extension: String in EXTENSIONS:
		var placeholder: String = PLACEHOLDER_MUSIC_DIR + base_name + extension
		if ResourceLoader.exists(placeholder):
			return placeholder
	return ""


func _prepare_loop(stream: AudioStream) -> AudioStream:
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			var bytes_per_frame: int = 1
			if wav.format == AudioStreamWAV.FORMAT_16_BITS:
				bytes_per_frame = 2
			if wav.stereo:
				bytes_per_frame *= 2
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = wav.data.size() / bytes_per_frame
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	return stream


func _kill_tween() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _warn_once(key: String, message: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning(message)
