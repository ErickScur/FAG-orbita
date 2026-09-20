extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const LOGS_DIR: String = "res://data/logs/"


func test_item_ids_unique_across_levels() -> void:
	var seen: Dictionary = {}
	for level_id: String in _level_ids():
		for entry: Dictionary in _items(level_id):
			var item_id: String = String(entry["item_id"])
			assert_false(
				seen.has(item_id),
				"id repetido '%s' (%s e %s)" % [item_id, seen.get(item_id, "?"), level_id]
			)
			seen[item_id] = level_id


func test_every_collectible_has_an_item_id() -> void:
	for level_id: String in _level_ids():
		for entry: Dictionary in _items(level_id):
			assert_false(
				String(entry["item_id"]).is_empty(),
				"fase '%s': coletável sem id em %s" % [level_id, entry["cell"]]
			)


func test_log_items_reference_existing_logs() -> void:
	var known: Dictionary = _known_logs()
	assert_false(known.is_empty(), "logs carregados de %s" % LOGS_DIR)
	for level_id: String in _level_ids():
		for entry: Dictionary in _items(level_id):
			if StringName(entry["kind"]) != PickupRules.KIND_LOG:
				continue
			assert_true(
				known.has(String(entry["item_id"])),
				"fase '%s': log inexistente '%s'" % [level_id, entry["item_id"]]
			)


func test_log_objects_reference_existing_logs() -> void:
	var known: Dictionary = _known_logs()
	for level_id: String in _level_ids():
		var meta: Dictionary = _meta(level_id)
		var entities: Dictionary = meta.get("entities", {})
		for entry: Dictionary in _entities(level_id):
			if String(entry["symbol"]) != "L":
				continue
			var params: Variant = entities.get(LevelParser.cell_key(entry["cell"]), {})
			assert_true(params is Dictionary, "fase '%s': terminal de log sem id" % level_id)
			var id: String = String((params as Dictionary).get("id", ""))
			assert_true(known.has(id), "fase '%s': log inexistente '%s'" % [level_id, id])


func test_collectible_chars_map_to_known_kinds() -> void:
	for symbol: Variant in LevelBuilder.LEGEND:
		var definition: Dictionary = LevelBuilder.LEGEND[symbol]
		if not definition.has("kind"):
			continue
		var kind: StringName = StringName(definition["kind"])
		assert_true(PickupRules.is_known(kind), "caractere '%s' com tipo '%s'" % [symbol, kind])


func _items(level_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var meta: Dictionary = _meta(level_id)
	var entities: Dictionary = meta.get("entities", {})
	for entry: Dictionary in _entities(level_id):
		var definition: Dictionary = LevelBuilder.LEGEND.get(String(entry["symbol"]), {})
		if not definition.has("kind"):
			continue
		var cell: Vector2i = entry["cell"]
		var raw: Variant = entities.get(LevelParser.cell_key(cell), {})
		var params: Dictionary = raw if raw is Dictionary else {}
		var kind: StringName = StringName(definition["kind"])
		result.append({
			"kind": kind,
			"cell": cell,
			"item_id": LevelBuilder.default_item_id(level_id, kind, cell, params),
		})
	return result


func _entities(level_id: String) -> Array:
	var text: String = FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".txt")
	return LevelParser.parse(text, LevelBuilder.entity_chars()).get("entities", [])


func _meta(level_id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".json")
	)
	return parsed if parsed is Dictionary else {}


func _known_logs() -> Dictionary:
	var known: Dictionary = {}
	var dir := DirAccess.open(LOGS_DIR)
	if dir == null:
		return known
	for file_name: String in dir.get_files():
		if not file_name.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(
			FileAccess.get_file_as_string(LOGS_DIR + file_name)
		)
		if not (parsed is Dictionary):
			continue
		for value: Variant in (parsed as Dictionary).get("logs", []) as Array:
			if value is Dictionary:
				known[String((value as Dictionary).get("id", ""))] = true
	return known


func _level_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return ids
	for file_name: String in dir.get_files():
		if file_name.ends_with(".txt"):
			ids.append(file_name.get_basename())
	ids.sort()
	return ids
