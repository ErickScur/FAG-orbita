class_name StationMapModel
extends RefCounted

const PATH: String = "res://data/map/station.json"
const LEVELS_DIR: String = "res://data/levels/"
const VISITED_PREFIX: String = "visited_"
const STATE_RESTORED: StringName = &"restored"
const STATE_VISITED: StringName = &"visited"
const STATE_SEALED: StringName = &"sealed"
const STATE_UNKNOWN: StringName = &"unknown"
const KEY_ID: String = "id"
const KEY_NAME: String = "name"
const KEY_LEVEL: String = "level"
const KEY_SCENE: String = "scene"
const KEY_EXTRA_SCENES: String = "extra_scenes"
const KEY_REQUIRES: String = "requires"
const KEY_REQUIRES_ABILITY: String = "requires_ability"
const KEY_RESTORED_WHEN: String = "restored_when"
const KEY_CELL: String = "cell"
const SNAP_RESTORED: String = "restored"
const SNAP_FLAGS: String = "flags"
const SNAP_COLLECTED: String = "collected"
const SNAP_CHECKPOINT: String = "checkpoint_scene"
const SNAP_CURRENT: String = "current_scene"
const SNAP_ABILITIES: String = "abilities"
const KIND_RESEARCH: StringName = &"research"
const DIRECTIONS: Array[Vector2i] = [
	Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
]
const PERPENDICULAR_WEIGHT: int = 2

static var _research_cache: Dictionary = {}


static func load_station(path: String = PATH) -> Dictionary:
	var empty: Array[Dictionary] = []
	var result: Dictionary = {"station": "", "hub": &"", "sectors": empty}
	if not FileAccess.file_exists(path):
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return result
	var data: Dictionary = parsed
	result["station"] = String(data.get("station", ""))
	result["hub"] = StringName(String(data.get("hub", "")))
	var sectors: Array[Dictionary] = []
	for value: Variant in data.get("sectors", []) as Array:
		if value is Dictionary:
			var sector: Dictionary = _normalized(value as Dictionary)
			if sector[KEY_ID] != &"":
				sectors.append(sector)
	result["sectors"] = sectors
	return result


static func snapshot(state: Object, current_scene: String) -> Dictionary:
	var checkpoint: Variant = state.get("checkpoint") if state != null else {}
	var checkpoint_scene: String = ""
	if checkpoint is Dictionary:
		checkpoint_scene = String((checkpoint as Dictionary).get("scene", ""))
	var flags: Variant = state.get("flags") if state != null else {}
	return {
		SNAP_RESTORED: _names(state.get("sectors_restored") if state != null else []),
		SNAP_FLAGS: flags if flags is Dictionary else {},
		SNAP_COLLECTED: _names(state.get("collected_ids") if state != null else []),
		SNAP_CHECKPOINT: checkpoint_scene,
		SNAP_CURRENT: current_scene,
		SNAP_ABILITIES: _names(state.get("abilities") if state != null else []),
	}


static func visited_flag(level_key: String) -> String:
	return VISITED_PREFIX + level_key


static func find(sectors: Array[Dictionary], sector_id: StringName) -> Dictionary:
	for sector: Dictionary in sectors:
		if sector[KEY_ID] == sector_id:
			return sector
	return {}


static func current_sector(sectors: Array[Dictionary], snap: Dictionary) -> StringName:
	for sector: Dictionary in sectors:
		if is_current(sector, snap):
			return sector[KEY_ID]
	return &""


static func is_restored(sector: Dictionary, snap: Dictionary) -> bool:
	var restored: Array = snap.get(SNAP_RESTORED, [])
	if restored.has(sector[KEY_ID]):
		return true
	var trigger: StringName = sector[KEY_RESTORED_WHEN]
	return trigger != &"" and restored.has(trigger)


static func is_sealed(sector: Dictionary, snap: Dictionary) -> bool:
	if missing_ability(sector, snap) != &"":
		return true
	var requirement: StringName = sector[KEY_REQUIRES]
	if requirement == &"":
		return false
	return not (snap.get(SNAP_RESTORED, []) as Array).has(requirement)


static func missing_ability(sector: Dictionary, snap: Dictionary) -> StringName:
	var ability: StringName = sector.get(KEY_REQUIRES_ABILITY, &"")
	if ability == &"":
		return &""
	if (snap.get(SNAP_ABILITIES, []) as Array).has(ability):
		return &""
	return ability


static func sealed_by_ability_only(sector: Dictionary, snap: Dictionary) -> bool:
	if missing_ability(sector, snap) == &"":
		return false
	var requirement: StringName = sector[KEY_REQUIRES]
	return requirement == &"" or (snap.get(SNAP_RESTORED, []) as Array).has(requirement)


static func is_current(sector: Dictionary, snap: Dictionary) -> bool:
	var current: String = String(snap.get(SNAP_CURRENT, ""))
	if current.is_empty():
		return false
	if String(sector[KEY_SCENE]) == current:
		return true
	return (sector.get(KEY_EXTRA_SCENES, PackedStringArray()) as PackedStringArray).has(current)


static func was_visited(sector: Dictionary, snap: Dictionary, logs: Dictionary) -> bool:
	if is_current(sector, snap):
		return true
	var flags: Dictionary = snap.get(SNAP_FLAGS, {})
	if bool(flags.get(visited_flag(String(sector[KEY_LEVEL])), false)):
		return true
	var scene: String = sector[KEY_SCENE]
	if not scene.is_empty() and scene == String(snap.get(SNAP_CHECKPOINT, "")):
		return true
	var collected: Array = snap.get(SNAP_COLLECTED, [])
	return (
		LogCatalog.found_count(log_ids(sector, logs), collected) > 0
		or LogCatalog.found_count(research_ids(sector[KEY_LEVEL]), collected) > 0
	)


static func state_of(sector: Dictionary, snap: Dictionary, logs: Dictionary) -> StringName:
	if is_restored(sector, snap):
		return STATE_RESTORED
	if was_visited(sector, snap, logs):
		return STATE_VISITED
	if is_sealed(sector, snap):
		return STATE_SEALED
	return STATE_UNKNOWN


static func shows_counts(state: StringName) -> bool:
	return state == STATE_RESTORED or state == STATE_VISITED


static func log_ids(sector: Dictionary, logs: Dictionary) -> Array[StringName]:
	return LogCatalog.ids_for_sector(logs, [sector[KEY_ID], sector[KEY_LEVEL]])


static func counts(sector: Dictionary, snap: Dictionary, logs: Dictionary) -> Dictionary:
	var collected: Array = snap.get(SNAP_COLLECTED, [])
	var logs_here: Array[StringName] = log_ids(sector, logs)
	var research_here: Array[StringName] = research_ids(sector[KEY_LEVEL])
	return {
		"logs_found": LogCatalog.found_count(logs_here, collected),
		"logs_total": logs_here.size(),
		"data_found": LogCatalog.found_count(research_here, collected),
		"data_total": research_here.size(),
	}


static func restored_count(sectors: Array[Dictionary], snap: Dictionary) -> int:
	var total: int = 0
	for sector: Dictionary in sectors:
		if is_restored(sector, snap):
			total += 1
	return total


static func research_ids(level_key: StringName) -> Array[StringName]:
	var none: Array[StringName] = []
	if level_key == &"":
		return none
	if _research_cache.has(level_key):
		return (_research_cache[level_key] as Array[StringName]).duplicate()
	var found: Array[StringName] = _scan_research(String(level_key))
	_research_cache[level_key] = found
	return found.duplicate()


static func clear_cache() -> void:
	_research_cache.clear()


static func neighbor(
	sectors: Array[Dictionary], from_id: StringName, direction: Vector2i
) -> StringName:
	var origin: Dictionary = find(sectors, from_id)
	if origin.is_empty():
		return &""
	var start: Vector2i = origin[KEY_CELL]
	var best: StringName = &""
	var best_score: int = -1
	for sector: Dictionary in sectors:
		if sector[KEY_ID] == from_id:
			continue
		var delta: Vector2i = (sector[KEY_CELL] as Vector2i) - start
		var along: int = delta.x * direction.x + delta.y * direction.y
		if along <= 0:
			continue
		var across: int = absi(delta.x * direction.y) + absi(delta.y * direction.x)
		var score: int = along + across * PERPENDICULAR_WEIGHT
		if best_score < 0 or score < best_score:
			best_score = score
			best = sector[KEY_ID]
	return best


static func _scan_research(level_key: String) -> Array[StringName]:
	var found: Array[StringName] = []
	var text_path: String = LEVELS_DIR + level_key + ".txt"
	if not FileAccess.file_exists(text_path):
		return found
	var symbols: Dictionary = _research_symbols()
	if symbols.is_empty():
		return found
	var meta: Dictionary = {}
	var meta_path: String = LEVELS_DIR + level_key + ".json"
	if FileAccess.file_exists(meta_path):
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if raw is Dictionary:
			meta = raw
	var entities_meta: Variant = meta.get("entities", {})
	var by_cell: Dictionary = entities_meta if entities_meta is Dictionary else {}
	var parsed: Dictionary = LevelParser.parse(
		FileAccess.get_file_as_string(text_path), LevelBuilder.entity_chars()
	)
	for entry: Dictionary in parsed.get("entities", []) as Array:
		if not symbols.has(String(entry.get("symbol", ""))):
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		var params: Variant = by_cell.get(LevelParser.cell_key(cell), {})
		var cell_params: Dictionary = params if params is Dictionary else {}
		found.append(_item_id(level_key, cell, cell_params))
	return found


static func _item_id(level_key: String, cell: Vector2i, params: Dictionary) -> StringName:
	if params.has("item_id"):
		return StringName(String(params["item_id"]))
	return LevelBuilder.default_item_id(level_key, KIND_RESEARCH, cell, params)


static func _research_symbols() -> Dictionary:
	var symbols: Dictionary = {}
	for symbol: Variant in LevelBuilder.LEGEND:
		var definition: Dictionary = LevelBuilder.LEGEND[symbol]
		if StringName(definition.get("kind", &"")) == KIND_RESEARCH:
			symbols[String(symbol)] = true
	return symbols


static func _normalized(raw: Dictionary) -> Dictionary:
	var cell_raw: Variant = raw.get(KEY_CELL, [0, 0])
	var cell := Vector2i.ZERO
	if cell_raw is Array and (cell_raw as Array).size() == 2:
		cell = Vector2i(int((cell_raw as Array)[0]), int((cell_raw as Array)[1]))
	return {
		KEY_ID: StringName(String(raw.get(KEY_ID, ""))),
		KEY_NAME: String(raw.get(KEY_NAME, "")),
		KEY_LEVEL: StringName(String(raw.get(KEY_LEVEL, raw.get(KEY_ID, "")))),
		KEY_SCENE: String(raw.get(KEY_SCENE, "")),
		KEY_EXTRA_SCENES: _scene_list(raw.get(KEY_EXTRA_SCENES, [])),
		KEY_REQUIRES: StringName(String(raw.get(KEY_REQUIRES, ""))),
		KEY_REQUIRES_ABILITY: StringName(String(raw.get(KEY_REQUIRES_ABILITY, ""))),
		KEY_RESTORED_WHEN: StringName(String(raw.get(KEY_RESTORED_WHEN, ""))),
		KEY_CELL: cell,
	}


static func _scene_list(values: Variant) -> PackedStringArray:
	var result := PackedStringArray()
	if values is Array:
		for value: Variant in values as Array:
			result.append(String(value))
	return result


static func _names(values: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if values is Array:
		for value: Variant in values as Array:
			result.append(StringName(String(value)))
	return result
