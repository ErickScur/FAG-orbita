extends TestCase

const MAP_PATH: String = "res://data/levels/greenhouse.txt"
const META_PATH: String = "res://data/levels/greenhouse.json"
const ENERGY_PATH: String = "res://data/energy/greenhouse.json"
const SCENE_PATH: String = "res://scenes/levels/greenhouse.tscn"
const NODE_SCENE: String = "res://scenes/world/sector_node.tscn"
const TERMINAL_ID: StringName = &"greenhouse"
const MAP_WIDTH: int = 48
const MAP_HEIGHT: int = 64
const MAX_STEP_TILES: int = 2
const MAX_GAP_TILES: int = 3
const SOLID: String = "#"
const SUPPORTS: String = "#=M"
const FLOOR_ROWS: Array[int] = [12, 22, 32, 42, 52, 62]
const EXPECTED_GROUPS: Array[String] = [
	"gh_spores", "gh_heat_vents", "gh_corridor_lamps", "gh_grow_lamps", "gh_canopy_lamps"
]
const EXPECTED_ENTITY_IDS: Array[String] = [
	"gh_plant_1", "gh_plant_2", "gh_lift", "gh_gondola", "gh_node_door"
]
const ROUTE_BASE: Array = [
	[5, 61, ""], [7, 61, ""], [10, 61, ""], [14, 61, ""], [16, 61, ""], [17, 60, ""],
	[18, 60, ""], [19, 61, ""], [21, 61, ""], [24, 61, ""], [27, 61, ""], [30, 61, ""],
	[33, 61, ""], [36, 60, ""], [37, 60, ""], [38, 61, ""], [41, 61, ""], [44, 61, ""]
]
const ROUTE_PLANT: Array = [
	[12, 61, ""], [12, 59, ""], [14, 58, "trepadeira"], [15, 55, ""], [14, 53, ""],
	[14, 51, ""], [16, 51, ""]
]
const ROUTE_LIFT: Array = [[44, 61, ""], [44, 41, "elevador"], [42, 41, ""]]
const ROUTE_NURSERY: Array = [[16, 51, ""], [13, 51, ""], [9, 51, ""], [7, 51, ""], [5, 51, ""]]
const ROUTE_STAIR: Array = [
	[25, 51, ""], [26, 49, ""], [28, 47, ""], [30, 45, ""], [32, 43, ""], [32, 41, ""]
]
const ROUTE_GALLERY: Array = [
	[32, 41, ""], [29, 41, ""], [26, 41, ""], [25, 41, ""], [21, 41, ""], [18, 41, ""],
	[15, 41, ""], [12, 41, ""], [9, 41, ""], [7, 41, ""], [5, 41, "gondola"]
]
const ROUTE_CANOPY: Array = [
	[18, 41, ""], [18, 39, ""], [20, 38, "trepadeira"], [19, 35, ""], [20, 33, ""],
	[20, 31, ""], [22, 31, ""]
]
const ROUTE_GONDOLA: Array = [[5, 41, "gondola"], [5, 31, "gondola"], [7, 31, ""]]
const ROUTE_CANOPY_FLOOR: Array = [
	[7, 31, ""], [9, 31, ""], [13, 31, ""], [16, 31, ""], [20, 31, ""], [24, 31, ""],
	[28, 31, ""], [32, 31, ""], [36, 31, ""], [39, 31, ""]
]
const ROUTE_TOWER: Array = [
	[9, 31, ""], [9, 29, ""], [10, 27, ""], [9, 25, ""], [9, 23, ""], [9, 21, ""], [11, 21, ""]
]
const ROUTE_CORRIDOR: Array = [
	[11, 21, ""], [13, 21, ""], [17, 21, ""], [20, 21, ""], [23, 21, ""], [25, 21, ""],
	[29, 21, ""], [33, 21, ""], [38, 21, ""], [42, 21, ""], [44, 21, ""]
]
const ROUTE_CLAWS: Array = [[44, 21, ""], [44, 11, "garras"], [42, 11, ""]]
const ROUTE_CLAWS_SECRET: Array = [[44, 21, ""], [44, 5, "garras"], [41, 5, "dado"], [42, 5, ""]]
const ROUTE_NODE_FLOOR: Array = [
	[42, 11, ""], [38, 11, ""], [34, 11, ""], [30, 11, ""], [26, 11, ""], [22, 11, ""],
	[18, 11, ""], [15, 11, ""], [13, 11, ""], [12, 11, "porta"], [11, 11, ""], [9, 11, ""],
	[7, 11, ""]
]
const ZONE_A: int = 0
const ZONE_B: int = 1
const ZONE_C: int = 2
const ZONE_D: int = 3
const ZONE_E: int = 4
const ZONE_F: int = 5
const ZONE_NAMES: Array[String] = ["A", "B", "C", "D", "E", "F"]
const CONSOLE_ZONES: Array[int] = [ZONE_A, ZONE_C, ZONE_F]

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


func test_map_grew_into_a_tall_vertical_level() -> void:
	assert_eq(int(_parsed.get("width", 0)), MAP_WIDTH, "largura da Estufa")
	assert_eq(int(_parsed.get("height", 0)), MAP_HEIGHT, "altura da Estufa")
	assert_true(MAP_HEIGHT > MAP_WIDTH, "a Estufa é vertical")
	for line: String in _lines:
		assert_eq(line.length(), MAP_WIDTH, "linha com largura irregular")


func test_single_spawn_and_the_expected_cast() -> void:
	assert_eq(_count_symbol("P"), 1, "exatamente um spawn")
	assert_eq(_count_symbol("E"), 0, "a Estufa acaba no Nó, não numa saída de fase")
	assert_eq(_count_symbol("T"), 3, "três consoles do mesmo terminal")
	assert_eq(_count_symbol("|"), 1, "uma porta de energia")
	assert_eq(_count_symbol("S"), 3, "três SR-3")
	assert_eq(_count_symbol("~"), 5, "cinco focos de esporos")
	assert_eq(_count_symbol("m"), 2, "elevador de carga e gôndola")
	assert_eq(_count_symbol("g"), 2, "duas trepadeiras")
	assert_eq(_count_symbol("x"), 4, "duas paredes falsas de dois tiles")


func test_collectibles_match_the_feature_budget() -> void:
	assert_eq(_count_symbol("D"), 2, "duas docas de backup")
	assert_eq(_count_symbol("L"), 2, "dois terminais de registro")
	assert_eq(_count_symbol("l"), 0, "nenhum fragmento solto de log")
	assert_eq(_count_symbol("r"), 3, "três dados de pesquisa")
	assert_eq(_count_symbol("c"), 5, "cinco células de energia")
	assert_eq(_count_symbol("k"), 3, "três kits de solda")
	assert_eq(_count_symbol("C"), 1, "um núcleo de capacitor")


func test_the_demo_still_has_exactly_four_research_data() -> void:
	var total: int = _count_symbol("r")
	var raw: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/levels/core_hub.json")
	)
	if raw is Dictionary:
		for key: Variant in (raw as Dictionary).get("entities", {}):
			var params: Dictionary = ((raw as Dictionary)["entities"] as Dictionary)[key]
			if String(params.get("id", "")).begins_with("data_"):
				total += 1
	assert_eq(total, Balance.RESEARCH_TOTAL, "o placar de Dados continua fechando")


func test_the_level_has_two_secret_areas() -> void:
	var walls: Dictionary = {}
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		var secret: String = String(params.get("secret_id", ""))
		if secret.is_empty():
			continue
		walls[secret] = int(walls.get(secret, 0)) + 1
	assert_eq(walls.size(), 2, "duas áreas secretas distintas")
	for secret: Variant in walls:
		assert_eq(int(walls[secret]), 2, "a parede falsa '%s' tem dois tiles" % secret)
	assert_true(
		walls.size() <= Balance.SECRETS_TOTAL, "os segredos cabem no placar da demo"
	)


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
		assert_true(
			int(rect[0]) >= 0 and int(rect[0]) + int(rect[2]) <= MAP_WIDTH, "'%s' em x" % id
		)
		assert_true(
			int(rect[1]) >= 0 and int(rect[1]) + int(rect[3]) <= MAP_HEIGHT, "'%s' em y" % id
		)
		assert_true(_rect_has_open_cell(rect), "gatilho '%s' só cobre tile sólido" % id)


func test_puzzle_is_six_systems_two_units() -> void:
	var grid: EnergyGrid = _grid()
	assert_not_null(grid, "terminal greenhouse carregou")
	if grid == null:
		return
	assert_eq(grid.budget, 2, "duas unidades de energia")
	assert_eq(grid.system_ids().size(), 6, "seis sistemas")
	assert_true(grid.validate().is_empty(), "terminal válido")
	assert_true(grid.is_powered(&"heating"), "aquecimento começa ligado")
	assert_true(grid.is_powered(&"corridor_light"), "corredor começa aceso")
	assert_false(grid.goal_met(), "o puzzle não começa resolvido")
	assert_false(grid.verbose, "a Estufa não explica os sistemas")
	assert_true(_meta.get("terminals", []).has(String(TERMINAL_ID)), "fase declara o terminal")


func test_the_puzzle_has_two_dependency_chains() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	assert_eq(
		_ids(grid.requires_of(&"canopy_light")), _ids([&"grow_light"]), "a copa puxa do canteiro"
	)
	assert_eq(
		_ids(grid.requires_of(&"lift_platform")),
		_ids([&"heating"]),
		"a linha de carga puxa do aquecimento"
	)
	grid.set_state([])
	assert_eq(
		grid.can_power(&"canopy_light"),
		EnergyGrid.Result.MISSING_DEPENDENCY,
		"a copa não liga sozinha"
	)
	grid.power_on(&"grow_light")
	assert_eq(grid.can_power(&"canopy_light"), EnergyGrid.Result.OK, "com o canteiro ligado, liga")
	assert_eq(grid.used(), 1, "o canteiro sozinho gasta uma unidade")
	grid.power_on(&"canopy_light")
	assert_eq(grid.used(), 2, "a cadeia consome o orçamento inteiro")
	assert_eq(
		grid.power_off(&"grow_light").size(), 2, "derrubar o canteiro derruba a copa em cascata"
	)


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


func test_the_three_consoles_share_one_terminal() -> void:
	var consoles: int = 0
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if not String(params.get("id", "")).begins_with("gh_console"):
			continue
		consoles += 1
		assert_eq(String(params.get("terminal", "")), String(TERMINAL_ID), "console em %s" % key)
	assert_eq(consoles, 3, "um console por zona com escolha")


func test_every_plant_has_a_boarding_ledge_two_tiles_below_its_top() -> void:
	for entity_id: String in ["gh_plant_1", "gh_plant_2"]:
		var cell: Vector2i = _cell_of(entity_id)
		assert_ne(cell, Vector2i(-1, -1), "'%s' está no mapa" % entity_id)
		if cell.x < 0:
			continue
		var top_row: int = cell.y - 4
		var found: bool = false
		for column: int in range(cell.x - 3, cell.x + 4):
			if _symbol_at(Vector2i(column, cell.y - 1)) == "=":
				found = true
		assert_true(
			found,
			"'%s' precisa de um degrau na linha %d: o topo fica %d tiles acima do piso"
			% [entity_id, cell.y - 1, cell.y - top_row]
		)


func test_botanic_route_geometry_reaches_the_node_floor() -> void:
	_walk(ROUTE_BASE, "base")
	_walk(ROUTE_PLANT, "trepadeira do canteiro")
	_walk(ROUTE_NURSERY, "viveiro")
	_walk(ROUTE_STAIR, "escada do viveiro")
	_walk(ROUTE_GALLERY, "galeria")
	_walk(ROUTE_CANOPY, "trepadeira alta")
	_walk(ROUTE_CANOPY_FLOOR, "copa")
	_walk(ROUTE_TOWER, "torre de plataformas finas")
	_walk(ROUTE_CORRIDOR, "corredor escuro")
	_walk(ROUTE_CLAWS, "parede magnética")
	_walk(ROUTE_NODE_FLOOR, "andar do Nó")


func test_freight_route_geometry_reaches_the_node_floor() -> void:
	_walk(ROUTE_BASE, "base")
	_walk(ROUTE_LIFT, "elevador de carga")
	_walk(ROUTE_GALLERY, "galeria")
	_walk(ROUTE_GONDOLA, "gôndola")
	_walk(ROUTE_CANOPY_FLOOR, "copa")
	_walk(ROUTE_TOWER, "torre de plataformas finas")
	_walk(ROUTE_CORRIDOR, "corredor escuro")
	_walk(ROUTE_CLAWS, "parede magnética")
	_walk(ROUTE_NODE_FLOOR, "andar do Nó")


func test_the_claw_alcove_is_only_reachable_by_climbing() -> void:
	_walk(ROUTE_CLAWS_SECRET, "nicho das garras")
	var data_cell: Vector2i = _cell_of("data_gh_03")
	assert_eq(data_cell, Vector2i(41, 5), "o terceiro Dado mora no nicho alto")
	assert_true(
		_symbol_at(Vector2i(41, 6)) == SOLID and _symbol_at(Vector2i(38, 6)) != SOLID,
		"o nicho é uma saliência isolada"
	)


func test_the_sector_node_lives_behind_the_energy_door() -> void:
	assert_eq(_symbol_at(Vector2i(7, 11)), "o", "o Nó do setor mora em 7,11")
	var params: Dictionary = _params_of("gh_sector_node")
	assert_eq(String(params.get("scene", "")), NODE_SCENE, "o tile do Nó instancia a cena nova")
	assert_eq(String(params.get("sector_id", "")), String(TERMINAL_ID), "setor do Nó")
	assert_true(ResourceLoader.exists(NODE_SCENE), "cena do Nó existe")
	assert_eq(_cell_of("gh_node_door"), Vector2i(12, 11), "a porta fecha a câmara")
	for row: int in range(2, 9):
		assert_eq(_symbol_at(Vector2i(12, row)), SOLID, "a parede da câmara não tem fresta")


func test_floors_are_thick_enough_to_read_as_floors() -> void:
	for row: int in FLOOR_ROWS:
		var solid_columns: int = 0
		for column: int in range(MAP_WIDTH):
			if SUPPORTS.contains(_symbol_at(Vector2i(column, row))):
				solid_columns += 1
		assert_true(solid_columns >= MAP_WIDTH / 2, "laje da linha %d muito vazada" % row)


func test_the_claws_gate_comes_before_the_magnetic_wall_exit() -> void:
	var claw_log_row: int = _cell_of("log_gh_02").y
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


func test_the_magnetic_wall_is_one_unbroken_climb() -> void:
	var rows: Array[int] = []
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) != "M":
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		assert_eq(cell.x, 45, "a parede inteira mora na coluna 45")
		rows.append(cell.y)
	rows.sort()
	assert_eq(rows.size(), rows[rows.size() - 1] - rows[0] + 1, "a parede não tem buraco")
	for row: int in rows:
		assert_ne(_symbol_at(Vector2i(44, row)), SOLID, "a coluna de escalada está livre")


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


func test_the_lift_docks_level_with_both_floors() -> void:
	_assert_platform_docks("gh_lift", 61, 62.0, 42.0)


func test_the_gondola_docks_level_with_both_floors() -> void:
	_assert_platform_docks("gh_gondola", 41, 42.0, 32.0)


func test_the_freight_line_moves_both_machines() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	var targets: Array[String] = []
	for value: Variant in grid.effects_of(&"lift_platform"):
		targets.append(String((value as Dictionary)["target"]))
	assert_true(targets.has("id:gh_lift"), "a linha de carga move o elevador")
	assert_true(targets.has("id:gh_gondola"), "a linha de carga move a gôndola")


func test_no_energy_state_can_strand_the_player() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	var start: Array[StringName] = grid.initial_state()
	var reachable: Dictionary = _explore(grid, _key(ZONE_A, start))
	assert_true(reachable.size() > 1, "a busca visitou o mapa")
	for key: Variant in reachable:
		assert_true(
			_can_finish(grid, String(key)),
			"o estado '%s' ainda fecha a fase" % _label_state(String(key))
		)


func test_every_zone_can_reach_a_console_without_energy() -> void:
	var grid: EnergyGrid = _grid()
	if grid == null:
		return
	for zone: int in range(ZONE_NAMES.size()):
		var current: int = zone
		var guard: int = 0
		while not CONSOLE_ZONES.has(current) and guard < ZONE_NAMES.size():
			current -= 1
			guard += 1
		assert_true(
			CONSOLE_ZONES.has(current),
			"da zona %s dá para descer até um console" % ZONE_NAMES[zone]
		)


func _assert_platform_docks(
	entity_id: String, origin_row: int, bottom_row: float, top_row: float
) -> void:
	var cell: Vector2i = _cell_of(entity_id)
	assert_eq(cell.y, origin_row, "'%s' nasce na linha %d" % [entity_id, origin_row])
	var points: PackedVector2Array = MovingPlatform.points_from(
		_params_of(entity_id).get("path", [])
	)
	assert_eq(points.size(), 2, "'%s' tem dois pontos de parada" % entity_id)
	if points.size() != 2:
		return
	var origin: float = float(cell.y) + 0.5
	assert_almost_eq(
		origin + points[0].y - 0.25, bottom_row, 0.01, "'%s' embaixo rente ao piso" % entity_id
	)
	assert_almost_eq(
		origin + points[1].y - 0.25, top_row, 0.01, "'%s' em cima rente ao piso" % entity_id
	)


func _zone_moves(zone: int) -> Array:
	match zone:
		ZONE_A:
			return [
				{"to": ZONE_B, "needs": [&"grow_light"]},
				{"to": ZONE_C, "needs": [&"lift_platform"]},
			]
		ZONE_B:
			return [{"to": ZONE_C, "needs": []}, {"to": ZONE_A, "needs": []}]
		ZONE_C:
			return [
				{"to": ZONE_D, "needs": [&"canopy_light"]},
				{"to": ZONE_D, "needs": [&"lift_platform"]},
				{"to": ZONE_B, "needs": []},
			]
		ZONE_D:
			return [{"to": ZONE_E, "needs": []}, {"to": ZONE_C, "needs": []}]
		ZONE_E:
			return [{"to": ZONE_F, "needs": []}, {"to": ZONE_D, "needs": []}]
		ZONE_F:
			return [{"to": ZONE_E, "needs": []}]
	return []


func _key(zone: int, state: Array[StringName]) -> String:
	var names: PackedStringArray = _ids(state)
	names.sort()
	return "%d|%s" % [zone, "/".join(names)]


func _label_state(key: String) -> String:
	var parts: PackedStringArray = key.split("|")
	return "zona %s com [%s]" % [ZONE_NAMES[int(parts[0])], parts[1].replace("/", ", ")]


func _neighbours(grid: EnergyGrid, key: String) -> PackedStringArray:
	var parts: PackedStringArray = key.split("|")
	var zone: int = int(parts[0])
	var state: Array[StringName] = []
	for name: String in parts[1].split("/", false):
		state.append(StringName(name))
	var result := PackedStringArray()
	for value: Variant in _zone_moves(zone):
		var move: Dictionary = value
		var allowed: bool = true
		for needed: Variant in move["needs"] as Array:
			if not state.has(StringName(needed)):
				allowed = false
		if allowed:
			result.append(_key(int(move["to"]), state))
	if not CONSOLE_ZONES.has(zone):
		return result
	for system_id: StringName in grid.system_ids():
		grid.set_state(state)
		var outcome: Dictionary = grid.toggle(system_id)
		if int(outcome["result"]) != EnergyGrid.Result.OK:
			continue
		result.append(_key(zone, grid.get_state()))
	grid.set_state(state)
	return result


func _explore(grid: EnergyGrid, start: String) -> Dictionary:
	var seen: Dictionary = {start: true}
	var pending: PackedStringArray = [start]
	while not pending.is_empty():
		var current: String = pending[pending.size() - 1]
		pending.remove_at(pending.size() - 1)
		for next: String in _neighbours(grid, current):
			if seen.has(next):
				continue
			seen[next] = true
			pending.append(next)
	return seen


func _can_finish(grid: EnergyGrid, start: String) -> bool:
	for key: Variant in _explore(grid, start):
		var parts: PackedStringArray = String(key).split("|")
		if int(parts[0]) != ZONE_F:
			continue
		if parts[1].split("/", false).has("node_door"):
			return true
	return false


func _walk(route: Array, label: String) -> void:
	var previous: Array = []
	for value: Variant in route:
		var step: Array = value
		var cell := Vector2i(int(step[0]), int(step[1]))
		var special: String = String(step[2])
		if special.is_empty():
			assert_true(
				_is_standing_cell(cell), "%s: (%d,%d) não é piso" % [label, cell.x, cell.y]
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
					gap <= MAX_GAP_TILES, "%s: vão de %d tiles na linha %d" % [label, gap, from.y]
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
