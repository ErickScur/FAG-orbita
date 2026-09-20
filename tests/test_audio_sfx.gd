extends TestCase

const PLAYED: Array[StringName] = [
	&"chassis_lost", &"claw_grab", &"damage", &"dialogue_blip", &"door_close", &"door_open",
	&"flashlight", &"interact", &"jump", &"land", &"log_pickup", &"low_integrity", &"pickup",
	&"plant_grow", &"power_off", &"power_on", &"reactor_alarm", &"respawn", &"sector_restored",
	&"secret_found", &"sr3_shutdown", &"step_metal", &"step_soil", &"tape_hiss",
	&"terminal_breaker", &"ui_back", &"ui_confirm", &"ui_error", &"ui_move",
]
const INTEGRATED: Array[StringName] = [
	&"chassis_lost", &"claw_grab", &"damage", &"door_close", &"door_open", &"interact",
	&"jump", &"land", &"log_pickup", &"pickup", &"plant_grow", &"power_off", &"power_on",
	&"respawn", &"sector_restored", &"secret_found", &"sr3_shutdown", &"step_metal",
	&"terminal_breaker", &"ui_back", &"ui_confirm", &"ui_error", &"ui_move",
]
const PENDING: Array[StringName] = [
	&"dialogue_blip", &"flashlight", &"low_integrity", &"reactor_alarm", &"step_soil",
	&"tape_hiss",
]
const VARIANT_GROUPS: Dictionary = {
	&"step_metal": 3,
	&"door_open": 3,
	&"door_close": 3,
	&"pickup": 2,
}
const SPORES_PATH: String = "res://assets/audio/sfx/spores.wav"
const FINAL_DIR: String = "res://assets/audio/sfx/"
const PLACEHOLDER_DIR: String = "res://assets/placeholder/audio/sfx/"


func test_every_sfx_the_game_plays_has_sound() -> void:
	for sfx_name: StringName in PLAYED:
		var streams: Array = AudioManager._streams_for(sfx_name)
		assert_false(streams.is_empty(), "efeito '%s' sem arquivo" % sfx_name)


func test_integrated_sfx_use_the_final_file_not_the_placeholder() -> void:
	for sfx_name: StringName in INTEGRATED:
		var streams: Array = AudioManager._streams_for(sfx_name)
		assert_false(streams.is_empty(), "efeito '%s' sem arquivo" % sfx_name)
		for stream: AudioStream in streams:
			assert_true(
				stream.resource_path.begins_with(FINAL_DIR),
				"efeito '%s' precisa do som definitivo, veio '%s'" % [sfx_name, stream.resource_path]
			)


func test_pending_sfx_still_fall_back_to_the_placeholder() -> void:
	for sfx_name: StringName in PENDING:
		var streams: Array = AudioManager._streams_for(sfx_name)
		assert_false(streams.is_empty(), "efeito '%s' sem arquivo" % sfx_name)
		for stream: AudioStream in streams:
			assert_true(
				stream.resource_path.begins_with(PLACEHOLDER_DIR),
				"efeito '%s' ainda é placeholder, veio '%s'" % [sfx_name, stream.resource_path]
			)


func test_integrated_and_pending_cover_everything_the_game_plays() -> void:
	for sfx_name: StringName in PLAYED:
		assert_true(
			INTEGRATED.has(sfx_name) or PENDING.has(sfx_name),
			"efeito '%s' fora das duas listas" % sfx_name
		)
	assert_eq(INTEGRATED.size() + PENDING.size(), PLAYED.size(), "listas sem sobreposição")


func test_variant_groups_are_sorted_out() -> void:
	for sfx_name: StringName in VARIANT_GROUPS:
		var streams: Array = AudioManager._streams_for(sfx_name)
		assert_eq(streams.size(), int(VARIANT_GROUPS[sfx_name]), "variações de '%s'" % sfx_name)


func test_every_sfx_stream_is_audible() -> void:
	for sfx_name: StringName in PLAYED:
		for stream: AudioStream in AudioManager._streams_for(sfx_name):
			assert_true(stream.get_length() > 0.0, "efeito '%s' com duração zero" % sfx_name)


func test_pickup_rules_names_have_sound() -> void:
	for kind: StringName in PickupRules.KINDS:
		var sfx_name: StringName = PickupRules.sfx_for(kind)
		assert_false(
			AudioManager._streams_for(sfx_name).is_empty(),
			"coleta '%s' sem som '%s'" % [kind, sfx_name]
		)


func test_dialogue_data_sfx_have_sound() -> void:
	for path: String in ["res://data/dialogue/core_hub.json", "res://data/dialogue/greenhouse.json"]:
		for sfx_name: StringName in _dialogue_sfx(path):
			assert_false(
				AudioManager._streams_for(sfx_name).is_empty(),
				"fala pede o som '%s', que não existe" % sfx_name
			)


func test_level_floor_sfx_have_sound() -> void:
	for path: String in ["res://data/levels/core_hub.json", "res://data/levels/greenhouse.json"]:
		var floor_sfx: StringName = StringName(String(_json(path).get("floor_sfx", "")))
		assert_ne(floor_sfx, &"", "fase '%s' sem passo declarado" % path)
		assert_false(
			AudioManager._streams_for(floor_sfx).is_empty(),
			"passo '%s' sem som" % floor_sfx
		)


func test_swarm_loop_resolves_to_a_looping_wav() -> void:
	var stream: AudioStream = AssetResolver.audio(SPORES_PATH)
	assert_not_null(stream, "chiado dos esporos")
	assert_true(stream is AudioStreamWAV, "o enxame precisa de um WAV para entrar em loop")
	assert_eq(AssetResolver.resolve_audio(SPORES_PATH), SPORES_PATH, "arquivo definitivo")


func _json(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _dialogue_sfx(path: String) -> Array[StringName]:
	var names: Array[StringName] = []
	var sequences: Variant = _json(path).get("sequences", {})
	if not sequences is Dictionary:
		return names
	for key: Variant in sequences:
		var sequence: Variant = (sequences as Dictionary)[key]
		if not sequence is Dictionary:
			continue
		for line: Variant in (sequence as Dictionary).get("lines", []):
			if not line is Dictionary:
				continue
			var sfx_name: String = String((line as Dictionary).get("sfx", ""))
			if not sfx_name.is_empty() and not names.has(StringName(sfx_name)):
				names.append(StringName(sfx_name))
	return names
