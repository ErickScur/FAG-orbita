class_name SectorCatalog
extends RefCounted

const PATH: String = "res://data/sectors.json"
const HUB_ID: StringName = &"core"
const ICON_SIZE: int = 7
const ICON_ON: String = "#"
const FALLBACK_COLOR: Color = Color("8fe3b0")
const KEY_NAME: String = "name"
const KEY_PROMPT: String = "prompt"
const KEY_SCENE: String = "scene"
const KEY_COLOR: String = "color"
const KEY_ICON: String = "icon"
const KEY_HUB: String = "hub"


static func load_all(path: String = PATH) -> Dictionary:
	var table: Dictionary = {}
	if not FileAccess.file_exists(path):
		push_warning("SectorCatalog: arquivo ausente %s" % path)
		return table
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		push_warning("SectorCatalog: JSON inválido em %s" % path)
		return table
	for key: Variant in parsed as Dictionary:
		var value: Variant = (parsed as Dictionary)[key]
		if value is Dictionary:
			table[StringName(String(key))] = value
	return table


static func entry(sector_id: StringName, table: Dictionary) -> Dictionary:
	var value: Variant = table.get(sector_id, {})
	return value if value is Dictionary else {}


static func has(sector_id: StringName, table: Dictionary) -> bool:
	return not entry(sector_id, table).is_empty()


static func display_name(sector_id: StringName, table: Dictionary) -> String:
	return String(entry(sector_id, table).get(KEY_NAME, ""))


static func prompt(sector_id: StringName, table: Dictionary) -> String:
	return String(entry(sector_id, table).get(KEY_PROMPT, ""))


static func scene(sector_id: StringName, table: Dictionary) -> String:
	return String(entry(sector_id, table).get(KEY_SCENE, ""))


static func color(sector_id: StringName, table: Dictionary) -> Color:
	var text: String = String(entry(sector_id, table).get(KEY_COLOR, ""))
	if text.is_empty() or not Color.html_is_valid(text):
		return FALLBACK_COLOR
	return Color(text)


static func is_hub(sector_id: StringName, table: Dictionary) -> bool:
	return bool(entry(sector_id, table).get(KEY_HUB, false))


static func icon(sector_id: StringName, table: Dictionary) -> PackedStringArray:
	var rows := PackedStringArray()
	var raw: Variant = entry(sector_id, table).get(KEY_ICON, [])
	if raw is Array:
		for row: Variant in raw as Array:
			rows.append(String(row))
	return rows


static func icon_cells(rows: PackedStringArray) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] == ICON_ON:
				cells.append(Vector2i(x, y))
	return cells


static func sector_for_scene(scene_path: String, table: Dictionary) -> StringName:
	for key: Variant in table:
		if scene(StringName(key), table) == scene_path:
			return StringName(key)
	return &""
