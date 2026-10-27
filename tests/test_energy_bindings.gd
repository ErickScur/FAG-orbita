extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const ENERGY_DIR: String = "res://data/energy/"


func test_inverted_nodes_are_not_also_bound_to_the_same_system() -> void:
	for level_path: String in _level_metas():
		var meta: Dictionary = _read(level_path)
		var entities: Dictionary = meta.get("entities", {})
		for key: Variant in entities:
			var params: Dictionary = entities[key]
			var terminal_id: String = String(params.get("terminal_id", ""))
			var system_id: String = String(params.get("system_id", ""))
			if terminal_id.is_empty() or system_id.is_empty():
				continue
			for target: String in _inverted_targets(terminal_id, system_id):
				assert_false(
					_matches(target, params),
					"%s %s: vinculado a %s/%s e invertido por '%s' no mesmo sistema" % [
						level_path.get_file(), key, terminal_id, system_id, target
					]
				)


func _level_metas() -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(LEVELS_DIR):
		if file.ends_with(".json"):
			paths.append(LEVELS_DIR + file)
	return paths


func _inverted_targets(terminal_id: String, system_id: String) -> Array[String]:
	var targets: Array[String] = []
	var energy: Dictionary = _read(ENERGY_DIR + terminal_id + ".json")
	for value: Variant in energy.get("systems", []) as Array:
		var entry: Dictionary = value
		if String(entry.get("id", "")) != system_id:
			continue
		for effect_value: Variant in entry.get("effects", []) as Array:
			var effect: Dictionary = effect_value
			if StringName(String(effect.get("action", ""))) == EnergyGrid.ACTION_INVERT:
				targets.append(String(effect.get("target", "")))
	return targets


func _matches(target: String, params: Dictionary) -> bool:
	if target.begins_with(EnergyGrid.TARGET_ID):
		return target.substr(EnergyGrid.TARGET_ID.length()) == String(params.get("id", ""))
	if target.begins_with(EnergyGrid.TARGET_GROUP):
		return target.substr(EnergyGrid.TARGET_GROUP.length()) == String(params.get("group", ""))
	return false


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	return {}
