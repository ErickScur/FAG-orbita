extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const ENERGY_DIR: String = "res://data/energy/"


func test_every_txt_has_json() -> void:
	var levels: PackedStringArray = _level_ids()
	assert_false(levels.is_empty(), "pelo menos uma fase em %s" % LEVELS_DIR)
	for level_id: String in levels:
		assert_true(
			FileAccess.file_exists(LEVELS_DIR + level_id + ".json"),
			"fase '%s' sem metadados" % level_id
		)


func test_json_entity_coords_exist() -> void:
	for level_id: String in _level_ids():
		var parsed: Dictionary = _parse(level_id)
		var meta: Dictionary = _meta(level_id)
		var cells: Dictionary = {}
		for entry: Dictionary in parsed["entities"] as Array:
			cells[LevelParser.cell_key(entry["cell"])] = true
		for key: Variant in meta.get("entities", {}) as Dictionary:
			assert_true(
				cells.has(String(key)),
				"fase '%s': chave '%s' não aponta para entidade no .txt" % [level_id, key]
			)


func test_trigger_rects_inside() -> void:
	for level_id: String in _level_ids():
		var parsed: Dictionary = _parse(level_id)
		var width: int = int(parsed["width"])
		var height: int = int(parsed["height"])
		for value: Variant in _meta(level_id).get("triggers", []) as Array:
			var rect: Array = (value as Dictionary).get("rect", [])
			assert_eq(rect.size(), 4, "fase '%s': rect com 4 valores" % level_id)
			if rect.size() != 4:
				continue
			assert_true(
				int(rect[0]) >= 0 and int(rect[1]) >= 0, "fase '%s': rect negativo" % level_id
			)
			assert_true(
				int(rect[0]) + int(rect[2]) <= width and int(rect[1]) + int(rect[3]) <= height,
				"fase '%s': rect fora do mapa" % level_id
			)


func test_tileset_paths_exist() -> void:
	for level_id: String in _level_ids():
		var path: String = String(_meta(level_id).get("tileset", ""))
		assert_false(path.is_empty(), "fase '%s' sem tileset" % level_id)
		assert_true(ResourceLoader.exists(path), "tileset ausente: %s" % path)


func test_terminals_exist() -> void:
	if _energy_files().is_empty():
		return
	for level_id: String in _level_ids():
		for value: Variant in _meta(level_id).get("terminals", []) as Array:
			var path: String = ENERGY_DIR + String(value) + ".json"
			assert_true(FileAccess.file_exists(path), "terminal ausente: %s" % path)


func test_levels_parse_without_errors() -> void:
	for level_id: String in _level_ids():
		var parsed: Dictionary = _parse(level_id)
		var errors: PackedStringArray = parsed["errors"]
		assert_true(errors.is_empty(), "fase '%s': %s" % [level_id, ", ".join(errors)])


func test_entity_ids_unique() -> void:
	for level_id: String in _level_ids():
		var seen: Dictionary = {}
		for key: Variant in _meta(level_id).get("entities", {}) as Dictionary:
			var params: Dictionary = (_meta(level_id)["entities"] as Dictionary)[key]
			if not params.has("id"):
				continue
			var id: String = String(params["id"])
			assert_false(seen.has(id), "fase '%s': id repetido '%s'" % [level_id, id])
			seen[id] = true


func test_test_room_has_every_implemented_char() -> void:
	var parsed: Dictionary = _parse("test_room")
	var symbols: Dictionary = {}
	for entry: Dictionary in parsed["entities"] as Array:
		symbols[String(entry["symbol"])] = true
	for symbol: Variant in LevelBuilder.LEGEND:
		var feature: String = String((LevelBuilder.LEGEND[symbol] as Dictionary)["feature"])
		if feature == "F32" or feature == "F34":
			continue
		assert_true(symbols.has(String(symbol)), "test_room sem o caractere '%s'" % symbol)


func test_build_tiles_uses_mask() -> void:
	var parsed: Dictionary = _parse("test_room")
	var solid := TileMapLayer.new()
	var background := TileMapLayer.new()
	LevelBuilder.build_tiles(parsed, solid, background)
	assert_eq(solid.get_cell_atlas_coords(Vector2i(0, 0)), Vector2i(7, 1), "canto fechado")
	assert_eq(solid.get_cell_atlas_coords(Vector2i(5, 0)), Vector2i(3, 1), "teto")
	assert_eq(solid.get_cell_atlas_coords(Vector2i(0, 4)), Vector2i(5, 1), "parede esquerda")
	assert_eq(
		solid.get_cell_atlas_coords(Vector2i(2, 5)), LevelBuilder.ONE_WAY_TILE, "plataforma one-way"
	)
	assert_eq(solid.get_cell_source_id(Vector2i(1, 1)), -1, "interior sem sólido")
	assert_eq(
		background.get_cell_atlas_coords(Vector2i(1, 1)),
		LevelBuilder.BACKGROUND_TILE,
		"fundo preenchido"
	)
	solid.free()
	background.free()


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


func _energy_files() -> PackedStringArray:
	var files: PackedStringArray = []
	var dir := DirAccess.open(ENERGY_DIR)
	if dir == null:
		return files
	for file_name: String in dir.get_files():
		if file_name.ends_with(".json"):
			files.append(file_name)
	return files


func _parse(level_id: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".txt")
	return LevelParser.parse(text, LevelBuilder.entity_chars())


func _meta(level_id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".json")
	)
	return parsed if parsed is Dictionary else {}
