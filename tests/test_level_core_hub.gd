extends TestCase

const MAP_PATH: String = "res://data/levels/core_hub.txt"
const META_PATH: String = "res://data/levels/core_hub.json"
const ENERGY_PATH: String = "res://data/energy/core_hub.json"
const SCENE_PATH: String = "res://scenes/levels/core_hub.tscn"
const MIN_HEIGHT: int = 14
const MAX_STEP_TILES: int = 2
const MAX_GAP_TILES: int = 3
const TERMINAL_ID: StringName = &"core_hub"

var _parsed: Dictionary = {}
var _meta: Dictionary = {}


func before_each() -> void:
	_parsed = LevelParser.parse(
		FileAccess.get_file_as_string(MAP_PATH), LevelBuilder.entity_chars()
	)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	_meta = raw if raw is Dictionary else {}


func test_map_parses_without_errors() -> void:
	var errors: PackedStringArray = _parsed.get("errors", [])
	assert_true(errors.is_empty(), "erros do parser: %s" % ", ".join(errors))
	var warnings: PackedStringArray = _parsed.get("warnings", [])
	assert_true(warnings.is_empty(), "avisos do parser: %s" % ", ".join(warnings))


func test_map_is_tall_enough_for_the_viewport() -> void:
	assert_true(
		int(_parsed.get("height", 0)) >= MIN_HEIGHT,
		"altura %d deve ser >= %d" % [int(_parsed.get("height", 0)), MIN_HEIGHT]
	)
	for line: String in _lines():
		assert_eq(line.length(), int(_parsed.get("width", 0)), "linha com largura irregular")


func test_single_spawn_and_single_exit() -> void:
	assert_eq(_count_symbol("P"), 1, "exatamente um spawn")
	assert_eq(_count_symbol("E"), 1, "exatamente uma saída")
	assert_eq(_count_symbol("T"), 1, "exatamente um terminal de distribuição")
	assert_eq(_count_symbol("|"), 1, "exatamente uma porta de energia")
	assert_eq(_count_symbol("S"), 1, "exatamente uma SR-3")


func test_tutorial_has_one_of_each_pickup() -> void:
	assert_eq(_count_symbol("c"), 1, "uma célula de energia")
	assert_eq(_count_symbol("k"), 1, "um kit de solda")
	assert_eq(_count_symbol("r"), 1, "um dado de pesquisa")
	assert_eq(_count_symbol("l"), 1, "um fragmento de log")
	assert_eq(_count_symbol("D"), 2, "duas docas de backup")


func test_floor_is_continuous_and_climbable() -> void:
	var previous: int = -1
	var gap: int = 0
	for column: int in range(int(_parsed.get("width", 0))):
		var ground: int = _ground_row(column)
		if ground < 0:
			gap += 1
			assert_true(gap <= MAX_GAP_TILES, "vão de %d tiles na coluna %d" % [gap, column])
			continue
		gap = 0
		if previous >= 0:
			assert_true(
				absi(ground - previous) <= MAX_STEP_TILES,
				"degrau de %d tiles na coluna %d" % [absi(ground - previous), column]
			)
		previous = ground


func test_entity_keys_point_to_entity_cells() -> void:
	var cells: Dictionary = _entity_cells()
	for key: Variant in _meta.get("entities", {}):
		var cell: Vector2i = LevelParser.key_to_cell(String(key))
		assert_true(cells.has(cell), "chave '%s' sem entidade no mapa" % key)


func test_every_entity_is_described_in_the_json() -> void:
	var entities: Dictionary = _meta.get("entities", {})
	for cell: Variant in _entity_cells():
		assert_true(
			entities.has(LevelParser.cell_key(cell)),
			"entidade em %s sem metadados" % LevelParser.cell_key(cell)
		)


func test_objective_and_dialogue_ids_exist() -> void:
	var objectives: Dictionary = Objectives.load_all()
	var sequences: Dictionary = DialogueManager.sequences()
	assert_true(objectives.has(StringName(String(_meta.get("objective", "")))), "objetivo inicial")
	assert_true(
		sequences.has(StringName(String(_meta.get("on_enter_dialogue", "")))), "fala de abertura"
	)
	for value: Variant in _meta.get("triggers", []) as Array:
		var data: Dictionary = value
		var dialogue: String = String(data.get("dialogue", ""))
		if not dialogue.is_empty():
			assert_true(sequences.has(StringName(dialogue)), "fala '%s'" % dialogue)
		var objective: String = String(data.get("objective", ""))
		if not objective.is_empty():
			assert_true(objectives.has(StringName(objective)), "objetivo '%s'" % objective)


func test_log_ids_exist() -> void:
	var logs: Dictionary = DialogueManager.logs()
	var entities: Dictionary = _meta.get("entities", {})
	for key: Variant in entities:
		var params: Dictionary = entities[key]
		for field: String in ["log", "id"]:
			var candidate: String = String(params.get(field, ""))
			if candidate.begins_with("log_"):
				assert_true(logs.has(StringName(candidate)), "log '%s'" % candidate)


func test_objectives_never_repeat_along_the_route() -> void:
	var seen: Array[String] = []
	for value: Variant in _meta.get("triggers", []) as Array:
		var objective: String = String((value as Dictionary).get("objective", ""))
		if objective.is_empty():
			continue
		assert_false(seen.has(objective), "objetivo '%s' repetido" % objective)
		seen.append(objective)


func test_triggers_fit_inside_the_map() -> void:
	var width: int = int(_parsed.get("width", 0))
	var height: int = int(_parsed.get("height", 0))
	var ids: Array[String] = []
	for value: Variant in _meta.get("triggers", []) as Array:
		var data: Dictionary = value
		var id: String = String(data.get("id", ""))
		assert_false(id.is_empty(), "gatilho sem id")
		assert_false(ids.has(id), "gatilho '%s' repetido" % id)
		ids.append(id)
		var rect: Array = data.get("rect", [])
		assert_eq(rect.size(), 4, "gatilho '%s' sem rect" % id)
		if rect.size() != 4:
			continue
		assert_true(int(rect[0]) >= 0 and int(rect[0]) + int(rect[2]) <= width, "'%s' em x" % id)
		assert_true(int(rect[1]) >= 0 and int(rect[1]) + int(rect[3]) <= height, "'%s' em y" % id)
		assert_true(_rect_has_open_cell(rect), "gatilho '%s' só cobre tile sólido" % id)


func test_terminals_and_systems_match_the_energy_file() -> void:
	var terminals: Array = _meta.get("terminals", [])
	assert_true(terminals.has(String(TERMINAL_ID)), "fase declara o terminal core_hub")
	var grid: EnergyGrid = _grid()
	assert_not_null(grid, "terminal core_hub carregou")
	if grid == null:
		return
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		var system: String = String(params.get("system_id", ""))
		if system.is_empty():
			continue
		assert_eq(String(params.get("terminal_id", "")), String(TERMINAL_ID), "terminal em %s" % key)
		assert_true(grid.has_system(StringName(system)), "sistema '%s'" % system)


func test_puzzle_is_two_systems_one_unit_and_solvable() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	assert_eq(grid.budget, 1, "uma unidade de energia")
	assert_eq(grid.system_ids().size(), 2, "dois sistemas")
	assert_false(grid.goal_met(), "o puzzle não começa resolvido")
	grid.power_off(&"lights_core")
	assert_eq(grid.toggle(&"door_habitat")["result"], EnergyGrid.Result.OK, "porta liga")
	assert_true(grid.goal_met(), "meta cumprida ao ligar a porta")
	assert_false(grid.is_powered(&"lights_core"), "a luz fica desligada")


func test_exit_falls_back_to_the_demo_end() -> void:
	var exit_params: Dictionary = {}
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if params.has("target"):
			exit_params = params
	assert_false(exit_params.is_empty(), "a saída declara um alvo")
	assert_true(
		String(exit_params.get("target", "")).begins_with(ScenePaths.LEVELS_DIR),
		"alvo da saída é uma fase"
	)
	assert_true(ResourceLoader.exists(LevelBuilder.LEGEND["E"]["scene"]), "cena da saída existe")


func test_scene_and_data_agree() -> void:
	assert_true(ResourceLoader.exists(SCENE_PATH), "cena da fase existe")
	assert_eq(String(_meta.get("id", "")), "core_hub", "id do JSON")
	assert_true(ResourceLoader.exists(String(_meta.get("tileset", ""))), "tileset da fase")
	assert_false(bool(_meta.get("reactor_online", true)), "o timer começa congelado")
	assert_true(
		FileAccess.get_file_as_string("res://tests/scenes.txt").contains(SCENE_PATH),
		"cena registrada no smoke"
	)


func _lines() -> PackedStringArray:
	var text: String = FileAccess.get_file_as_string(MAP_PATH).replace("\r\n", "\n")
	var lines: PackedStringArray = text.split("\n")
	while lines.size() > 0 and lines[lines.size() - 1].is_empty():
		lines.remove_at(lines.size() - 1)
	return lines


func _count_symbol(symbol: String) -> int:
	var total: int = 0
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == symbol:
			total += 1
	if symbol == "P":
		return 1 if _parsed.get("spawn", Vector2i.ZERO) != Vector2i.ZERO else 0
	return total


func _entity_cells() -> Dictionary:
	var cells: Dictionary = {}
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		cells[entry.get("cell", Vector2i.ZERO)] = String(entry.get("symbol", ""))
	return cells


func _ground_row(column: int) -> int:
	var solids: Dictionary = _parsed.get("solids", {})
	var height: int = int(_parsed.get("height", 0))
	for row: int in range(height):
		if solids.has(Vector2i(column, row)) and not solids.has(Vector2i(column, row - 1)):
			if row > 1:
				return row
	return -1


func _rect_has_open_cell(rect: Array) -> bool:
	var solids: Dictionary = _parsed.get("solids", {})
	for x: int in range(int(rect[0]), int(rect[0]) + int(rect[2])):
		for y: int in range(int(rect[1]), int(rect[1]) + int(rect[3])):
			if not solids.has(Vector2i(x, y)):
				return true
	return false


func _grid() -> EnergyGrid:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	if not (raw is Dictionary):
		return null
	return EnergyGrid.from_dict(raw)
