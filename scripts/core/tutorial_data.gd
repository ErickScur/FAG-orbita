class_name TutorialData
extends RefCounted

const PATH: String = "res://data/tutorial.json"
const ID_PREFIX: String = "tut_"


static func load_all(path: String = PATH) -> Dictionary:
	var table: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_warning("TutorialData: arquivo ausente %s" % path)
		return table
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("TutorialData: JSON inválido em %s" % path)
		return table
	for key: Variant in parsed as Dictionary:
		var raw: Variant = (parsed as Dictionary)[key]
		if not (raw is Dictionary):
			continue
		table[StringName(String(key))] = _entry(raw)
	return table


static func has(tutorial_id: StringName, table: Dictionary) -> bool:
	return table.has(tutorial_id)


static func entry(tutorial_id: StringName, table: Dictionary) -> Dictionary:
	var value: Variant = table.get(tutorial_id, {})
	return value if value is Dictionary else {}


static func headline(tutorial_id: StringName, table: Dictionary) -> String:
	var data: Dictionary = entry(tutorial_id, table)
	if data.is_empty():
		return ""
	return "%s  %s" % [String(data["key"]), String(data["text"])]


static func actions_of(tutorial_id: StringName, table: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	var data: Dictionary = entry(tutorial_id, table)
	if data.is_empty():
		return result
	result.assign(data["actions"])
	return result


static func flag_name(tutorial_id: StringName) -> String:
	return String(tutorial_id)


static func validate(table: Dictionary) -> PackedStringArray:
	var errors: PackedStringArray = []
	if table.is_empty():
		errors.append("catálogo de tutoriais vazio")
	for tutorial_id: StringName in table:
		var data: Dictionary = table[tutorial_id]
		if not String(tutorial_id).begins_with(ID_PREFIX):
			errors.append("tutorial '%s' fora do prefixo '%s'" % [tutorial_id, ID_PREFIX])
		if String(data["key"]).strip_edges().is_empty():
			errors.append("tutorial '%s' sem tecla" % tutorial_id)
		if String(data["text"]).strip_edges().is_empty():
			errors.append("tutorial '%s' sem ação" % tutorial_id)
		var actions: Array[StringName] = []
		actions.assign(data["actions"])
		if actions.is_empty():
			errors.append("tutorial '%s' sem input que o conclua" % tutorial_id)
		for action: StringName in actions:
			if not InputMap.has_action(action):
				errors.append("tutorial '%s': ação '%s' fora do Input Map" % [tutorial_id, action])
	return errors


static func _entry(raw: Dictionary) -> Dictionary:
	var actions: Array[StringName] = []
	for value: Variant in raw.get("actions", []) as Array:
		actions.append(StringName(String(value)))
	return {
		"key": String(raw.get("key", "")),
		"text": String(raw.get("text", "")),
		"hint": String(raw.get("hint", "")),
		"actions": actions,
	}
