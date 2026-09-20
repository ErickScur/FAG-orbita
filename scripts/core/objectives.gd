class_name Objectives
extends RefCounted

const PATH: String = "res://data/objectives.json"


static func load_all(path: String = PATH) -> Dictionary:
	var table: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_warning("Objectives: arquivo ausente %s" % path)
		return table
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("Objectives: JSON inválido em %s" % path)
		return table
	var raw: Dictionary = parsed
	for key: Variant in raw:
		var value: Variant = raw[key]
		if value is String and not String(value).is_empty():
			table[StringName(key)] = String(value)
	return table


static func text_for(id: StringName, table: Dictionary) -> String:
	return String(table.get(id, ""))


static func has(id: StringName, table: Dictionary) -> bool:
	return not text_for(id, table).is_empty()
