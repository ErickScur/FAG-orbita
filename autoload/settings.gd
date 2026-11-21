extends Node

signal accessibility_changed()
signal bindings_changed()

const PATH: String = "user://settings.cfg"
const SECTION_AUDIO: String = "audio"
const SECTION_GAME: String = "game"
const SECTION_DISPLAY: String = "display"
const SECTION_ACCESSIBILITY: String = "accessibility"
const SECTION_CONTROLS: String = "controls"
const QA_FLAG: String = "--qa"

var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var voice_volume: float = 0.8
var difficulty: StringName = &"normal"
var no_timer: bool = false
var fullscreen: bool = false
var subtitle_size: StringName = Accessibility.SUBTITLE_NORMAL
var colorblind: bool = false
var key_overrides: Dictionary = {}


func _ready() -> void:
	load_settings()
	apply_display()
	apply_bindings()


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
	subtitle_size = Accessibility.valid_subtitle(StringName(
		config.get_value(SECTION_ACCESSIBILITY, "subtitle_size", String(subtitle_size))
	))
	colorblind = bool(config.get_value(SECTION_ACCESSIBILITY, "colorblind", colorblind))
	var saved: Dictionary = {}
	if config.has_section(SECTION_CONTROLS):
		for key: String in config.get_section_keys(SECTION_CONTROLS):
			saved[key] = config.get_value(SECTION_CONTROLS, key)
	key_overrides = KeyBindings.sanitize(saved)
	return true


func save_settings(path: String = PATH) -> bool:
	if path == PATH and is_qa_run():
		return true
	var config := ConfigFile.new()
	config.set_value(SECTION_AUDIO, "master_volume", master_volume)
	config.set_value(SECTION_AUDIO, "music_volume", music_volume)
	config.set_value(SECTION_AUDIO, "sfx_volume", sfx_volume)
	config.set_value(SECTION_AUDIO, "voice_volume", voice_volume)
	config.set_value(SECTION_GAME, "difficulty", String(difficulty))
	config.set_value(SECTION_GAME, "no_timer", no_timer)
	config.set_value(SECTION_DISPLAY, "fullscreen", fullscreen)
	config.set_value(SECTION_ACCESSIBILITY, "subtitle_size", String(subtitle_size))
	config.set_value(SECTION_ACCESSIBILITY, "colorblind", colorblind)
	for key: String in key_overrides:
		config.set_value(SECTION_CONTROLS, key, int(key_overrides[key]))
	return config.save(path) == OK


func damage_multiplier() -> float:
	return Balance.difficulty_damage_multiplier(difficulty)


func reactor_decay_multiplier() -> float:
	if no_timer:
		return 0.0
	return Balance.difficulty_reactor_multiplier(difficulty)


func apply_display() -> void:
	if fullscreen and not is_qa_run():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func is_qa_run() -> bool:
	return OS.get_cmdline_user_args().has(QA_FLAG)


func subtitle_font_size() -> int:
	return Accessibility.subtitle_font_size(subtitle_size)


func set_subtitle_size(size_id: StringName) -> void:
	var valid: StringName = Accessibility.valid_subtitle(size_id)
	if valid == subtitle_size:
		return
	subtitle_size = valid
	accessibility_changed.emit()


func set_colorblind(on: bool) -> void:
	if on == colorblind:
		return
	colorblind = on
	accessibility_changed.emit()


func signal_color(role: StringName) -> Color:
	return Accessibility.color(role, colorblind)


func apply_bindings() -> void:
	var defaults: Dictionary = KeyBindings.default_layout()
	var layout: Dictionary = KeyBindings.apply_overrides(defaults, key_overrides)
	KeyBindings.write_layout(layout)
	key_overrides = KeyBindings.overrides(layout, defaults)
	bindings_changed.emit()


func rebind(action: StringName, keycode: int) -> Dictionary:
	var outcome: Dictionary = KeyBindings.assign(KeyBindings.read_layout(), action, keycode)
	var result: StringName = outcome["result"]
	if result == KeyBindings.RESULT_ASSIGNED or result == KeyBindings.RESULT_SWAPPED:
		KeyBindings.write_layout(outcome["layout"])
		key_overrides = KeyBindings.overrides(outcome["layout"], KeyBindings.default_layout())
		bindings_changed.emit()
	return outcome


func restore_default_bindings() -> void:
	key_overrides = {}
	KeyBindings.write_layout(KeyBindings.default_layout())
	bindings_changed.emit()


func binding_label(action: String) -> String:
	return KeyBindings.action_label(StringName(action))
