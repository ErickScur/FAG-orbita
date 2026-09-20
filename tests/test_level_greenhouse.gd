extends TestCase

const MAP_PATH: String = "res://data/levels/greenhouse.txt"
const META_PATH: String = "res://data/levels/greenhouse.json"
const ENERGY_PATH: String = "res://data/energy/greenhouse.json"
const SCENE_PATH: String = "res://scenes/levels/greenhouse.tscn"
const NODE_SCENE: String = "res://scenes/world/sector_node.tscn"
const TERMINAL_ID: StringName = &"greenhouse"
const MIN_HEIGHT: int = 14
const MAX_STEP_TILES: int = 2
const MAX_GAP_TILES: int = 3
const SOLID: String = "#"
const SUPPORTS: String = "#="
const EXPECTED_GROUPS: Array[String] = [
	"gh_spores", "gh_heat_vents", "gh_corridor_lamps", "gh_grow_lamps"
]
const EXPECTED_ENTITY_IDS: Array[String] = ["gh_plant_1", "gh_lift", "gh_node_door"]
const ROUTE_BASE: Array = [
	[5, 37, ""], [7, 37, ""], [8, 35, ""], [9, 37, ""], [14, 37, ""], [15, 37, ""],
	[16, 35, ""], [17, 37, ""], [18, 37, ""]
]
const ROUTE_PLANT: Array = [
	[18, 37, ""], [19, 35, ""], [20, 35, ""], [21, 34, "planta"], [22, 32, ""],
	[21, 30, ""], [22, 28, ""], [20, 27, ""]
]
const ROUTE_LIFT: Array = [
	[18, 37, ""], [19, 35, ""], [20, 35, ""], [21, 37, ""], [25, 37, ""], [30, 37, ""],
	[33, 37, ""], [35, 37, ""], [35, 27, "elevador"], [32, 27, ""]
]
const ROUTE_MIDDLE: Array = [
	[20, 27, ""], [17, 27, ""], [14, 27, ""], [9, 27, ""], [8, 25, ""], [8, 23, ""],
	[9, 21, ""], [10, 19, ""], [11, 19, ""], [12, 17, ""]
]
const ROUTE_NODE: Array = [
	[12, 17, ""], [14, 17, ""], [24, 17, ""], [27, 17, ""], [28, 17, ""], [30, 17, ""],
	[32, 17, ""], [33, 15, ""], [34, 17, ""], [36, 17, ""], [35, 8, "garras"],
	[34, 7, ""], [33, 7, ""], [30, 7, ""], [29, 7, ""], [28, 5, ""], [27, 7, ""],
	[20, 7, ""], [15, 7, ""], [9, 7, ""], [7, 7, "porta"], [4, 7, ""]
]

var _parsed: Dictionary = {}
var _meta: Dictionary = {}
var _lines: PackedStringArray = []


func before_each() -> void:
	_lines = _map_lines()
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


func test_map_is_a_tall_vertical_level() -> void:
	var height: int = int(_parsed.get("height", 0))
	var width: int = int(_parsed.get("width", 0))
	assert_true(height >= MIN_HEIGHT, "altura %d deve ser >= %d" % [height, MIN_HEIGHT])
	assert_true(height >= width, "a Estufa é vertical: %d linhas x %d colunas" % [height, width])
	for line: String in _lines:
		assert_eq(line.length(), width, "linha com largura irregular")


func test_single_spawn_and_the_expected_cast() -> void:
	assert_eq(_count_symbol("P"), 1, "exatamente um spawn")
	assert_eq(_count_symbol("E"), 0, "a Estufa acaba no Nó, não numa saída de fase")
	assert_eq(_count_symbol("T"), 3, "três consoles do mesmo terminal")
	assert_eq(_count_symbol("|"), 1, "uma porta de energia")
	assert_eq(_count_symbol("S"), 2, "duas SR-3")
	assert_eq(_count_symbol("~"), 3, "três focos de esporos")
	assert_eq(_count_symbol("m"), 1, "um elevador")
	assert_eq(_count_symbol("g"), 1, "uma trepadeira")
	assert_eq(_count_symbol("x"), 2, "uma parede falsa de dois tiles")


func test_collectibles_match_the_feature_budget() -> void:
	assert_eq(_count_symbol("D"), 2, "duas docas de backup")
	assert_eq(_count_symbol("L"), 2, "dois terminais de registro")
	assert_eq(_count_symbol("l"), 0, "nenhum fragmento solto de log")
	assert_eq(_count_symbol("r"), 3, "três dados de pesquisa")
	assert_eq(_count_symbol("c"), 4, "quatro células de energia")
	assert_eq(_count_symbol("k"), 2, "dois kits de solda")
	assert_eq(_count_symbol("C"), 1, "um núcleo de capacitor")


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


func test_item_ids_are_unique_across_the_demo() -> void:
	var seen: Dictionary = {}
	for path: String in ["res://data/levels/core_hub.json", META_PATH]:
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (raw is Dictionary):
			continue
		for key: Variant in (raw as Dictionary).get("entities", {}):
			var params: Dictionary = ((raw as Dictionary)["entities"] as Dictionary)[key]
			var id: String = String(params.get("id", ""))
			if id.is_empty():
				continue
			assert_false(seen.has(id), "id '%s' repetido na demo" % id)
			seen[id] = true


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


func test_script_barks_exist() -> void:
	var sequences: Dictionary = DialogueManager.sequences()
	for id: String in ["gh_claws", "gh_restored"]:
		assert_true(sequences.has(StringName(id)), "fala de script '%s'" % id)


func test_log_ids_exist_and_are_unique() -> void:
	var logs: Dictionary = DialogueManager.logs()
	var seen: Array[String] = []
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		var id: String = String(params.get("id", ""))
		if not id.begins_with("log_"):
			continue
		assert_true(logs.has(StringName(id)), "log '%s'" % id)
		assert_false(seen.has(id), "log '%s' repetido" % id)
		seen.append(id)
	assert_eq(seen.size(), 2, "dois logs da Estufa")


func test_no_trigger_changes_the_objective() -> void:
	for value: Variant in _meta.get("triggers", []) as Array:
		var trigger: Dictionary = value
		assert_false(
			trigger.has("objective"), "gatilho '%s' troca o objetivo" % trigger.get("id", "?")
		)


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


func test_puzzle_is_five_systems_two_units() -> void:
	var grid: EnergyGrid = _grid()
	assert_not_null(grid, "terminal greenhouse carregou")
	if grid == null:
		return
	assert_eq(grid.budget, 2, "duas unidades de energia")
	assert_eq(grid.system_ids().size(), 5, "cinco sistemas")
	assert_true(grid.is_powered(&"heating"), "aquecimento começa ligado")
	assert_true(grid.is_powered(&"corridor_light"), "corredor começa aceso")
	assert_false(grid.goal_met(), "o puzzle não começa resolvido")
	assert_true(_meta.get("terminals", []).has(String(TERMINAL_ID)), "fase declara o terminal")


func test_map_provides_every_target_the_energy_file_expects() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	var groups: Dictionary = {}
	var ids: Dictionary = {}
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if params.has("group"):
			groups[String(params["group"])] = true
		if params.has("id"):
			ids[String(params["id"])] = true
	for system_id: StringName in grid.system_ids():
		for value: Variant in grid.effects_of(system_id):
			var target: String = String((value as Dictionary)["target"])
			if target.begins_with(EnergyGrid.TARGET_GROUP):
				var group: String = target.substr(EnergyGrid.TARGET_GROUP.length())
				assert_true(groups.has(group), "grupo '%s' sem entidade no mapa" % group)
			elif target.begins_with(EnergyGrid.TARGET_ID):
				var id: String = target.substr(EnergyGrid.TARGET_ID.length())
				assert_true(ids.has(id), "id '%s' sem entidade no mapa" % id)
	for group: String in EXPECTED_GROUPS:
		assert_true(groups.has(group), "grupo esperado '%s'" % group)
	for id: String in EXPECTED_ENTITY_IDS:
		assert_true(ids.has(id), "entidade esperada '%s'" % id)


func test_every_system_id_in_the_map_exists_in_the_terminal() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		var system: String = String(params.get("system_id", ""))
		if system.is_empty():
			continue
		assert_eq(String(params.get("terminal_id", "")), String(TERMINAL_ID), "terminal em %s" % key)
		assert_true(grid.has_system(StringName(system)), "sistema '%s'" % system)


func test_plant_route_is_solvable_in_the_terminal() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	assert_eq(grid.toggle(&"heating")["result"], EnergyGrid.Result.OK, "desliga o aquecimento")
	assert_eq(grid.toggle(&"grow_light")["result"], EnergyGrid.Result.OK, "liga a luz")
	assert_true(grid.is_powered(&"grow_light"), "trepadeira alimentada")
	assert_eq(grid.toggle(&"corridor_light")["result"], EnergyGrid.Result.OK, "apaga o corredor")
	assert_eq(grid.toggle(&"node_door")["result"], EnergyGrid.Result.OK, "abre a porta do Nó")
	assert_true(grid.goal_met(), "meta cumprida")
	assert_eq(grid.used(), 2, "2/2 em uso")


func test_lift_route_is_solvable_in_the_terminal() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	assert_eq(grid.toggle(&"corridor_light")["result"], EnergyGrid.Result.OK, "apaga o corredor")
	assert_eq(grid.toggle(&"lift_platform")["result"], EnergyGrid.Result.OK, "liga o elevador")
	assert_true(grid.is_powered(&"heating"), "o elevador depende do aquecimento")
	assert_eq(grid.toggle(&"lift_platform")["result"], EnergyGrid.Result.OK, "desliga lá em cima")
	assert_eq(grid.toggle(&"node_door")["result"], EnergyGrid.Result.OK, "abre a porta do Nó")
	assert_true(grid.goal_met(), "meta cumprida")


func test_no_configuration_powers_everything() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	for system_id: StringName in grid.system_ids():
		grid.power_on(system_id)
	assert_true(grid.used() <= grid.budget, "o orçamento nunca é estourado")
	assert_true(grid.powered().size() <= 2, "no máximo dois sistemas ligados")


func test_plant_route_geometry_reaches_the_middle_floor() -> void:
	_walk(ROUTE_BASE, "base")
	_walk(ROUTE_PLANT, "trepadeira")


func test_lift_route_geometry_reaches_the_middle_floor() -> void:
	_walk(ROUTE_BASE, "base")
	_walk(ROUTE_LIFT, "elevador")


func test_both_routes_lead_to_the_sector_node() -> void:
	_walk(ROUTE_MIDDLE, "passarela até o corredor")
	_walk(ROUTE_NODE, "corredor até o Nó")
	assert_eq(_symbol_at(Vector2i(4, 7)), "o", "o Nó do setor mora em 4,7")
	var params: Dictionary = (_meta["entities"] as Dictionary)["4,7"]
	assert_eq(String(params.get("scene", "")), NODE_SCENE, "o tile do Nó instancia a cena nova")
	assert_eq(String(params.get("sector_id", "")), String(TERMINAL_ID), "setor do Nó")
	assert_true(ResourceLoader.exists(NODE_SCENE), "cena do Nó existe")


func test_floors_are_thick_enough_to_read_as_floors() -> void:
	var width: int = int(_parsed.get("width", 0))
	for row: int in [8, 18, 28, 38]:
		var solid_columns: int = 0
		for column: int in range(width):
			if _symbol_at(Vector2i(column, row)) == SOLID:
				solid_columns += 1
		assert_true(solid_columns >= width / 2, "laje da linha %d muito vazada" % row)


func test_the_claws_gate_comes_before_the_magnetic_wall_exit() -> void:
	var claw_log_row: int = -1
	for key: Variant in _meta.get("entities", {}):
		if String((_meta["entities"] as Dictionary)[key].get("id", "")) != "log_gh_02":
			continue
		claw_log_row = LevelParser.key_to_cell(String(key)).y
	assert_true(claw_log_row > 0, "o log das garras está no mapa")
	var wall_rows: Array[int] = []
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == "M":
			wall_rows.append((entry.get("cell", Vector2i.ZERO) as Vector2i).y)
	assert_false(wall_rows.is_empty(), "a parede magnética está no mapa")
	wall_rows.sort()
	assert_true(
		claw_log_row > wall_rows[0],
		"o log (linha %d) fica abaixo do topo da parede (linha %d)" % [claw_log_row, wall_rows[0]]
	)
	assert_eq(
		String(DialogueManager.logs()[&"log_gh_02"].get("unlock_ability", "")),
		String(ClimbLogic.ABILITY_ID),
		"o log libera as garras"
	)


func test_scene_and_data_agree() -> void:
	assert_true(ResourceLoader.exists(SCENE_PATH), "cena da fase existe")
	assert_eq(String(_meta.get("id", "")), "greenhouse", "id do JSON")
	assert_true(ResourceLoader.exists(String(_meta.get("tileset", ""))), "tileset da fase")
	assert_true(bool(_meta.get("reactor_online", false)), "o timer já corre na Estufa")
	assert_true(bool(_meta.get("parallax", false)), "parallax ligado")
	assert_false(String(_meta.get("ambient_restored", "")).is_empty(), "paleta do setor religado")
	assert_true(
		FileAccess.get_file_as_string("res://tests/scenes.txt").contains(SCENE_PATH),
		"cena registrada no smoke"
	)


func test_the_first_log_hangs_off_the_lift_shaft() -> void:
	var log_cell: Vector2i = _cell_of("log_gh_01")
	assert_ne(log_cell, Vector2i(-1, -1), "log_gh_01 está no mapa")
	if log_cell.x < 0:
		return
	var solids: Dictionary = _parsed.get("solids", {})
	assert_false(solids.has(log_cell), "a célula do registro está livre")
	assert_true(solids.has(log_cell + Vector2i.DOWN), "o registro tem piso embaixo")
	var gap: int = 0
	for column: int in range(log_cell.x - 1, 0, -1):
		if solids.has(Vector2i(column, log_cell.y + 1)):
			break
		gap += 1
	assert_true(gap >= 3, "o registro fica do outro lado de um vão de %d tiles" % gap)
	var lift_cell: Vector2i = _cell_of("gh_lift")
	assert_true(
		lift_cell.x < log_cell.x and log_cell.x - lift_cell.x <= gap,
		"o poço do elevador é o que serve o registro"
	)


func test_the_first_log_ledge_always_lets_you_leave() -> void:
	var log_cell: Vector2i = _cell_of("log_gh_01")
	if log_cell.x < 0:
		return
	var solids: Dictionary = _parsed.get("solids", {})
	var height: int = int(_parsed.get("height", 0))
	var column: int = log_cell.x - 1
	var row: int = log_cell.y + 1
	while row < height and not solids.has(Vector2i(column, row)):
		row += 1
	assert_true(row < height, "a coluna ao lado da saliência termina em chão firme")
	assert_true(
		row - log_cell.y >= 4,
		"da saliência dá para cair de volta na Zona A (%d tiles)" % (row - log_cell.y)
	)


func test_the_first_log_is_never_on_the_walking_route() -> void:
	var log_cell: Vector2i = _cell_of("log_gh_01")
	for value: Variant in ROUTE_BASE + ROUTE_PLANT + ROUTE_LIFT + ROUTE_MIDDLE + ROUTE_NODE:
		var step: Array = value
		assert_ne(
			Vector2i(int(step[0]), int(step[1])),
			log_cell,
			"o registro não pode estar num passo da rota principal"
		)
	assert_ne(log_cell, _parsed.get("spawn", Vector2i.ZERO), "nem em cima do spawn")


func test_reaching_the_first_log_costs_a_system() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	assert_true(
		grid.requires_of(&"lift_platform").has(&"heating"), "o elevador exige o aquecimento"
	)
	assert_eq(
		_ids(grid.shutdown_candidates(&"lift_platform")),
		_ids([&"corridor_light"]),
		"ligar o elevador obriga a apagar o corredor"
	)
	grid.power_off(&"corridor_light")
	grid.power_on(&"lift_platform")
	assert_true(grid.is_powered(&"lift_platform"), "o elevador leva ao registro")
	assert_false(grid.is_powered(&"corridor_light"), "o corredor apagou por causa dele")
	assert_true(grid.can_power(&"node_door") != EnergyGrid.Result.UNKNOWN_SYSTEM, "meta existe")


func test_the_lift_docks_level_with_both_floors() -> void:
	var lift_cell: Vector2i = _cell_of("gh_lift")
	var points: PackedVector2Array = MovingPlatform.points_from(
		_params_of("gh_lift").get("path", [])
	)
	assert_eq(points.size(), 2, "o elevador tem dois pontos de parada")
	if points.size() != 2:
		return
	var origin: float = float(lift_cell.y) + 0.5
	assert_almost_eq(
		origin + points[0].y - 0.25, float(lift_cell.y + 1), 0.01, "embaixo fica rente ao piso"
	)
	assert_almost_eq(
		origin + points[1].y - 0.25, 28.0, 0.01, "em cima fica rente ao piso da Zona B"
	)


func _walk(route: Array, label: String) -> void:
	var previous: Array = []
	for value: Variant in route:
		var step: Array = value
		var cell := Vector2i(int(step[0]), int(step[1]))
		var special: String = String(step[2])
		if special.is_empty():
			assert_true(
				_is_standing_cell(cell),
				"%s: (%d,%d) não é piso" % [label, cell.x, cell.y]
			)
		if not previous.is_empty() and special.is_empty() and String(previous[2]).is_empty():
			_assert_reachable(Vector2i(int(previous[0]), int(previous[1])), cell, label)
		previous = step


func _assert_reachable(from: Vector2i, to: Vector2i, label: String) -> void:
	if from.y == to.y:
		var step: int = 1 if to.x > from.x else -1
		var gap: int = 0
		var column: int = from.x + step
		while column != to.x:
			if _is_standing_cell(Vector2i(column, from.y)):
				gap = 0
			else:
				gap += 1
				assert_true(
					gap <= MAX_GAP_TILES,
					"%s: vão de %d tiles na linha %d" % [label, gap, from.y]
				)
			column += step
		return
	assert_true(
		absi(to.x - from.x) <= MAX_GAP_TILES and to.y - from.y >= -MAX_STEP_TILES,
		"%s: salto (%d,%d) -> (%d,%d) fora do alcance" % [label, from.x, from.y, to.x, to.y]
	)


func _is_standing_cell(cell: Vector2i) -> bool:
	if not _is_open(cell) or not _is_open(cell + Vector2i.UP):
		return false
	return SUPPORTS.contains(_symbol_at(cell + Vector2i.DOWN))


func _is_open(cell: Vector2i) -> bool:
	return _symbol_at(cell) != SOLID


func _symbol_at(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= _lines.size():
		return SOLID
	var line: String = _lines[cell.y]
	if cell.x < 0 or cell.x >= line.length():
		return SOLID
	return line.substr(cell.x, 1)


func _map_lines() -> PackedStringArray:
	var text: String = FileAccess.get_file_as_string(MAP_PATH).replace("\r\n", "\n")
	var lines: PackedStringArray = text.split("\n")
	while lines.size() > 0 and lines[lines.size() - 1].is_empty():
		lines.remove_at(lines.size() - 1)
	return lines


func _count_symbol(symbol: String) -> int:
	if symbol == "P":
		return 1 if _parsed.get("spawn", Vector2i.ZERO) != Vector2i.ZERO else 0
	var total: int = 0
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == symbol:
			total += 1
	return total


func _entity_cells() -> Dictionary:
	var cells: Dictionary = {}
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == "M":
			continue
		cells[entry.get("cell", Vector2i.ZERO)] = String(entry.get("symbol", ""))
	return cells


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


func _cell_of(entity_id: String) -> Vector2i:
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if String(params.get("id", "")) == entity_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func _params_of(entity_id: String) -> Dictionary:
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if String(params.get("id", "")) == entity_id:
			return params
	return {}


func _ids(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	return result
