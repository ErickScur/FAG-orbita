extends TestCase

const SETTINGS_SCRIPT: String = "res://autoload/settings.gd"
const TEST_PATH: String = "user://test_settings.cfg"

var _settings: Node = null


func before_each() -> void:
	_settings = load(SETTINGS_SCRIPT).new()


func after_each() -> void:
	if _settings != null:
		_settings.free()
		_settings = null
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_defaults_without_file() -> void:
	assert_false(_settings.load_settings("user://inexistente_settings.cfg"), "arquivo ausente")
	assert_almost_eq(_settings.master_volume, 1.0, 0.0001, "master_volume")
	assert_almost_eq(_settings.music_volume, 0.8, 0.0001, "music_volume")
	assert_almost_eq(_settings.sfx_volume, 0.8, 0.0001, "sfx_volume")
	assert_almost_eq(_settings.voice_volume, 0.8, 0.0001, "voice_volume")
	assert_eq(_settings.difficulty, &"normal", "difficulty")
	assert_false(_settings.no_timer, "no_timer")
	assert_false(_settings.fullscreen, "fullscreen")


func test_save_and_load_round_trip() -> void:
	_settings.master_volume = 0.55
	_settings.music_volume = 0.25
	_settings.sfx_volume = 0.35
	_settings.voice_volume = 0.45
	_settings.difficulty = &"hard"
	_settings.no_timer = true
	_settings.fullscreen = true
	assert_true(_settings.save_settings(TEST_PATH), "save_settings")
	var loaded: Node = load(SETTINGS_SCRIPT).new()
	assert_true(loaded.load_settings(TEST_PATH), "load_settings")
	assert_almost_eq(loaded.master_volume, 0.55, 0.0001, "master_volume")
	assert_almost_eq(loaded.music_volume, 0.25, 0.0001, "music_volume")
	assert_almost_eq(loaded.sfx_volume, 0.35, 0.0001, "sfx_volume")
	assert_almost_eq(loaded.voice_volume, 0.45, 0.0001, "voice_volume")
	assert_eq(loaded.difficulty, &"hard", "difficulty")
	assert_true(loaded.no_timer, "no_timer")
	assert_true(loaded.fullscreen, "fullscreen")
	loaded.free()


func test_damage_multiplier_follows_difficulty() -> void:
	_settings.difficulty = &"hard"
	assert_almost_eq(_settings.damage_multiplier(), 1.5, 0.0001, "difícil")
	_settings.difficulty = &"easy"
	assert_almost_eq(_settings.damage_multiplier(), 0.5, 0.0001, "fácil")


func test_reactor_decay_multiplier_with_no_timer() -> void:
	_settings.difficulty = &"hard"
	_settings.no_timer = true
	assert_almost_eq(_settings.reactor_decay_multiplier(), 0.0, 0.0001, "sem timer")
	_settings.no_timer = false
	assert_almost_eq(_settings.reactor_decay_multiplier(), 1.5, 0.0001, "com timer")
