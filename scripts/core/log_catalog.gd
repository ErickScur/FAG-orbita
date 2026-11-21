class_name LogCatalog
extends RefCounted

const KEY_ID: String = "id"
const KEY_SECTOR: String = "sector"
const KEY_AUTHOR: String = "author"
const KEY_TITLE: String = "title"
const KEY_SUBTITLE: String = "subtitle"
const KEY_VOICE: String = "voice"
const KEY_LINES: String = "lines"
const KEY_COLLECTED: String = "collected"
const KEY_LABEL: String = "label"
const KEY_ENTRIES: String = "entries"
const KEY_NAME: String = "name"
const UNKNOWN_GROUP: StringName = &""
const GROUP_BY_SECTOR: StringName = &"sector"
const GROUP_BY_AUTHOR: StringName = &"author"


static func entries(logs: Dictionary, collected: Array) -> Array[Dictionary]:
	var found: Dictionary = _as_set(collected)
	var result: Array[Dictionary] = []
	for key: Variant in logs:
		var data: Variant = logs[key]
		if not (data is Dictionary):
			continue
		var raw: Dictionary = data
		var log_id: StringName = StringName(String(raw.get(KEY_ID, String(key))))
		result.append({
			KEY_ID: log_id,
			KEY_SECTOR: StringName(String(raw.get(KEY_SECTOR, ""))),
			KEY_AUTHOR: StringName(String(raw.get(KEY_AUTHOR, ""))),
			KEY_TITLE: String(raw.get(KEY_TITLE, "")),
			KEY_SUBTITLE: String(raw.get(KEY_SUBTITLE, "")),
			KEY_VOICE: String(raw.get(KEY_VOICE, "")),
			KEY_LINES: lines_of(raw),
			KEY_COLLECTED: found.has(log_id),
		})
	return result


static func lines_of(raw: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	for value: Variant in raw.get(KEY_LINES, []) as Array:
		var text: String = DialogueData.log_line_text(value)
		if not text.is_empty():
			lines.append(text)
	return lines


static func ids_for_sector(logs: Dictionary, sector_keys: Array) -> Array[StringName]:
	var keys: Dictionary = _as_set(sector_keys)
	var result: Array[StringName] = []
	for entry: Dictionary in entries(logs, []):
		if keys.has(entry[KEY_SECTOR]):
			result.append(entry[KEY_ID])
	return result


static func found_count(ids: Array, collected: Array) -> int:
	var found: Dictionary = _as_set(collected)
	var total: int = 0
	for value: Variant in ids:
		if found.has(StringName(String(value))):
			total += 1
	return total


static func collected_count(logs: Dictionary, collected: Array) -> int:
	return found_count(logs.keys(), collected)


static func group_by_sector(items: Array[Dictionary], sectors: Array) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var placed: Dictionary = {}
	for value: Variant in sectors:
		if not (value is Dictionary):
			continue
		var sector: Dictionary = value
		var keys: Dictionary = _as_set([sector.get(KEY_ID, ""), sector.get("level", "")])
		var members: Array[Dictionary] = []
		for entry: Dictionary in items:
			if keys.has(entry[KEY_SECTOR]) and not placed.has(entry[KEY_ID]):
				members.append(entry)
				placed[entry[KEY_ID]] = true
		if not members.is_empty():
			groups.append(_group(StringName(String(sector.get(KEY_ID, ""))), String(
				sector.get(KEY_NAME, "")
			), members))
	for entry: Dictionary in items:
		if placed.has(entry[KEY_ID]):
			continue
		var key: StringName = entry[KEY_SECTOR]
		var group: Dictionary = _find_group(groups, key)
		if group.is_empty():
			group = _group(key, String(key).to_upper(), [])
			groups.append(group)
		(group[KEY_ENTRIES] as Array).append(entry)
	return groups


static func group_by_author(
	items: Array[Dictionary], speakers: Dictionary, unknown_label: String
) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	var missing: Array[Dictionary] = []
	for entry: Dictionary in items:
		if not bool(entry[KEY_COLLECTED]):
			missing.append(entry)
			continue
		var author: StringName = entry[KEY_AUTHOR]
		var group: Dictionary = _find_group(groups, author)
		if group.is_empty():
			group = _group(author, author_name(author, speakers), [])
			groups.append(group)
		(group[KEY_ENTRIES] as Array).append(entry)
	if not missing.is_empty():
		groups.append(_group(UNKNOWN_GROUP, unknown_label, missing))
	return groups


static func author_name(author: StringName, speakers: Dictionary) -> String:
	var data: Variant = speakers.get(author, speakers.get(String(author), {}))
	if data is Dictionary:
		var named: String = String((data as Dictionary).get(KEY_NAME, ""))
		if not named.is_empty():
			return named
	return String(author).to_upper()


static func author_color(author: StringName, speakers: Dictionary, fallback: Color) -> Color:
	var data: Variant = speakers.get(author, speakers.get(String(author), {}))
	if data is Dictionary:
		var text: String = String((data as Dictionary).get("color", ""))
		if not text.is_empty() and Color.html_is_valid(text):
			return Color.html(text)
	return fallback


static func flatten(groups: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group: Dictionary in groups:
		for entry: Variant in group[KEY_ENTRIES] as Array:
			result.append(entry)
	return result


static func index_of(items: Array[Dictionary], log_id: StringName) -> int:
	for index: int in range(items.size()):
		if items[index][KEY_ID] == log_id:
			return index
	return -1


static func collected_from_save(path: String) -> Array[StringName]:
	var result: Array[StringName] = []
	if not FileAccess.file_exists(path):
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return result
	var state: Variant = (parsed as Dictionary).get("state", {})
	if not (state is Dictionary):
		return result
	for value: Variant in (state as Dictionary).get("collected_ids", []) as Array:
		result.append(StringName(String(value)))
	return result


static func _group(key: StringName, label: String, members: Array) -> Dictionary:
	var list: Array[Dictionary] = []
	for value: Variant in members:
		list.append(value)
	return {KEY_ID: key, KEY_LABEL: label, KEY_ENTRIES: list}


static func _find_group(groups: Array[Dictionary], key: StringName) -> Dictionary:
	for group: Dictionary in groups:
		if group[KEY_ID] == key:
			return group
	return {}


static func _as_set(values: Array) -> Dictionary:
	var result: Dictionary = {}
	for value: Variant in values:
		var text: String = String(value)
		if not text.is_empty():
			result[StringName(text)] = true
	return result
