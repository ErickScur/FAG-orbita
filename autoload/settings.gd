extends Node

const PATH: String = "user://settings.cfg"
const SECTION_AUDIO: String = "audio"
const SECTION_GAME: String = "game"
const SECTION_DISPLAY: String = "display"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var voice_volume: float = 0.8
var difficulty: StringName = &"normal"
var no_timer: bool = false
var fullscreen: bool = false


func _ready() -> void:
	load_settings()
	apply_display()


func load_settings(path: String = PATH) -> bool:
	var config := ConfigFile.new()
	if config.load(path) != OK:
		return false
	master_volume = float(config.get_value(SECTION_AUDIO, "master_volume", master_volume))
	music_volume = float(config.get_value(SECTION_AUDIO, "music_volume", music_volume))
	sfx_volume = float(config.get_value(SECTION_AUDIO, "sfx_volume", sfx_volume))
	voice_volume = float(config.get_value(SECTION_AUDIO, "voice_volume", voice_volume))
	difficulty = StringName(config.get_value(SECTION_GAME, "difficulty", String(difficulty)))
	no_timer = bool(config.get_value(SECTION_GAME, "no_timer", no_timer))
	fullscreen = bool(config.get_value(SECTION_DISPLAY, "fullscreen", fullscreen))
	return true


func save_settings(path: String = PATH) -> bool:
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, "master_volume", master_volume)
	config.set_value(SECTION_AUDIO, "music_volume", music_volume)
	config.set_value(SECTION_AUDIO, "sfx_volume", sfx_volume)
	config.set_value(SECTION_AUDIO, "voice_volume", voice_volume)
	config.set_value(SECTION_GAME, "difficulty", String(difficulty))
	config.set_value(SECTION_GAME, "no_timer", no_timer)
	config.set_value(SECTION_DISPLAY, "fullscreen", fullscreen)
	return config.save(path) == OK


func damage_multiplier() -> float:
	return Balance.difficulty_damage_multiplier(difficulty)


func reactor_decay_multiplier() -> float:
	if no_timer:
		return 0.0
	return Balance.difficulty_reactor_multiplier(difficulty)


func apply_display() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
