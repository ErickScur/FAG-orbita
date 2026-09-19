extends TestCase

const LAYOUT_PATH: String = "res://default_bus_layout.tres"
const BUSES: PackedStringArray = ["Master", "Music", "SFX", "Voice"]

var _saved: Dictionary = {}


func before_each() -> void:
	_saved = {
		"master": Settings.master_volume,
		"music": Settings.music_volume,
		"sfx": Settings.sfx_volume,
		"voice": Settings.voice_volume,
	}


func after_each() -> void:
	Settings.master_volume = float(_saved.get("master", 1.0))
	Settings.music_volume = float(_saved.get("music", 0.8))
	Settings.sfx_volume = float(_saved.get("sfx", 0.8))
	Settings.voice_volume = float(_saved.get("voice", 0.8))
	AudioManager.apply_volumes()


func test_layout_resource_is_registered() -> void:
	assert_eq(
		String(ProjectSettings.get_setting("audio/buses/default_bus_layout", "")),
		LAYOUT_PATH,
		"project.godot"
	)
	assert_true(ResourceLoader.exists(LAYOUT_PATH), "recurso existe")


func test_four_buses_are_available() -> void:
	assert_eq(AudioServer.bus_count, 4, "quantidade de buses")
	for index: int in range(BUSES.size()):
		assert_eq(AudioServer.get_bus_name(index), BUSES[index], "bus %d" % index)


func test_sub_buses_send_to_master() -> void:
	for bus_name: String in ["Music", "SFX", "Voice"]:
		var index: int = AudioServer.get_bus_index(bus_name)
		assert_true(index >= 1, "índice de %s" % bus_name)
		assert_eq(AudioServer.get_bus_send(index), &"Master", "envio de %s" % bus_name)


func test_set_bus_volume_mutes_and_writes_settings() -> void:
	AudioManager.set_bus_volume(&"SFX", 0.0)
	var index: int = AudioServer.get_bus_index(&"SFX")
	assert_true(AudioServer.is_bus_mute(index), "bus mudo")
	assert_almost_eq(AudioServer.get_bus_volume_db(index), AudioMath.SILENT_DB, 0.001, "dB")
	assert_almost_eq(Settings.sfx_volume, 0.0, 0.0001, "Settings.sfx_volume")


func test_set_bus_volume_half_is_minus_six_db() -> void:
	AudioManager.set_bus_volume(&"Music", 0.5)
	var index: int = AudioServer.get_bus_index(&"Music")
	assert_false(AudioServer.is_bus_mute(index), "não mudo")
	assert_almost_eq(AudioServer.get_bus_volume_db(index), -6.0206, 0.05, "dB")
	assert_almost_eq(Settings.music_volume, 0.5, 0.0001, "Settings.music_volume")


func test_apply_volumes_reads_settings() -> void:
	Settings.master_volume = 0.25
	Settings.voice_volume = 1.0
	AudioManager.apply_volumes()
	assert_almost_eq(AudioManager.get_bus_volume(&"Master"), 0.25, 0.001, "Master")
	assert_almost_eq(AudioManager.get_bus_volume(&"Voice"), 1.0, 0.001, "Voice")


func test_unknown_bus_is_ignored() -> void:
	AudioManager.set_bus_volume(&"Inexistente", 0.5)
	assert_almost_eq(AudioManager.get_bus_volume(&"Inexistente"), 0.0, 0.0001, "bus ausente")


func test_process_mode_always() -> void:
	assert_eq(AudioManager.process_mode, Node.PROCESS_MODE_ALWAYS, "process_mode")
