extends TestCase

const MAP_PATH: String = "res://data/levels/infirmary.txt"
const META_PATH: String = "res://data/levels/infirmary.json"
const ENERGY_PATH: String = "res://data/energy/infirmary.json"
const SCENE_PATH: String = "res://scenes/levels/infirmary.tscn"
const NODE_SCENE: String = "res://scenes/world/sector_node.tscn"
const PROPS_SHEET: String = "res://assets/sprites/props/infirmary_props_sheet.png"
const CAMPAIGN_METAS: Array[String] = [
	"res://data/levels/core_hub.json",
	"res://data/levels/greenhouse.json",
	"res://data/levels/lab.json",
	META_PATH,
]
const TERMINAL_ID: String = "infirmary"
const MAP_WIDTH: int = 110
const MAP_HEIGHT: int = 52
const SOLID: String = "#"
const BLOCKING: String = "#"
const ICE_WALL: String = "I"
const THIN_ICE: String = "_"
const LIGHT_SYMBOLS: String = "@i"
const DARK_POCKET_RADIUS_TILES: int = 8
const RECT_LIGHT_COVER: float = 1.3
const WARD_LAMP_MAX_RADIUS: float = 64.0
const EXPECTED_COUNTS: Dictionary = {
	"E": 1, "T": 2, "|": 3, "Y": 4, "i": 5, "h": 7, "m": 1, "D": 4, "L": 2, "l": 0,
	"r": 2, "C": 1, "x": 2, "c": 2, "k": 2, "@": 7, "I": 20, "_": 23, "o": 23,
}
const WARD_V9: Array[String] = ["inf_v9_01", "inf_v9_02", "inf_v9_03"]
const WARD_HEATERS: Array[String] = ["inf_heater_ala_01", "inf_heater_ala_02"]
const HEATER_WALLS: Dictionary = {
	"inf_ice_pharmacy": "inf_heater_pharmacy", "inf_ice_quarantine": "inf_heater_quarantine"
}
const CORE_WALLS: Array[String] = ["inf_ice_cryo_gate", "inf_ice_detour", "inf_ice_node_hall"]
const LIFT_ID: String = "inf_lift"
const LIFT_FLOORS: Array[float] = [47.0, 17.0]
const BRIDGE_ROW: int = 30
const BED_FRAME: int = 0
const EMPTY_BED_FRAME: int = 1
const CREW_BEDS: int = 12
const BODY_OVERHANG_PX: float = 12.0

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


func test_map_is_the_biggest_so_far() -> void:
	assert_eq(int(_parsed.get("width", 0)), MAP_WIDTH, "largura da Enfermaria")
	assert_eq(int(_parsed.get("height", 0)), MAP_HEIGHT, "altura da Enfermaria")
	assert_true(MAP_WIDTH * MAP_HEIGHT > 112 * 44, "maior que o Laboratório")
	for line: String in _lines:
		assert_eq(line.length(), MAP_WIDTH, "linha com largura irregular")


func test_cast_and_collectibles_match_the_feature() -> void:
	assert_ne(_parsed.get("spawn", Vector2i.ZERO), Vector2i.ZERO, "um spawn")
	for symbol: String in EXPECTED_COUNTS:
		var expected: int = int(EXPECTED_COUNTS[symbol])
		assert_eq(_count_symbol(symbol), expected, "quantidade de '%s'" % symbol)


func test_entity_keys_and_map_agree() -> void:
	var cells: Dictionary = _entity_cells()
	var entities: Dictionary = _meta.get("entities", {})
	for key: Variant in entities:
		var cell: Vector2i = LevelParser.key_to_cell(String(key))
		assert_true(cells.has(cell), "chave '%s' sem entidade" % key)
	for cell: Variant in cells:
		assert_true(entities.has(LevelParser.cell_key(cell)), "entidade em %s sem dados" % cell)


func test_item_ids_are_unique_across_the_campaign() -> void:
	var seen: Dictionary = {}
	for path: String in CAMPAIGN_METAS:
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (raw is Dictionary):
			continue
		for key: Variant in (raw as Dictionary).get("entities", {}):
			var params: Dictionary = ((raw as Dictionary)["entities"] as Dictionary)[key]
			var id: String = String(params.get("id", ""))
			if id.is_empty():
				continue
			assert_false(seen.has(id), "id '%s' repetido na campanha" % id)
			seen[id] = true


func test_orbita_only_speaks_at_milestones() -> void:
	var sequences: Dictionary = DialogueManager.sequences()
	var objective := StringName(String(_meta.get("objective", "")))
	assert_true(Objectives.load_all().has(objective), "objetivo")
	assert_eq(String(_meta.get("on_enter_dialogue", "")), "inf_enter", "fala de entrada")
	for id: String in ["inf_enter", "inf_heated_core", "inf_restored", "core_return_lab"]:
		assert_true(sequences.has(StringName(id)), "fala de marco '%s'" % id)
	assert_true((_meta.get("triggers", []) as Array).is_empty(), "nenhum gatilho de fala")


func test_two_logs_and_the_heated_core() -> void:
	var logs: Dictionary = DialogueManager.logs()
	for id: String in ["log_inf_01", "log_inf_02"]:
		assert_ne(_cell_of(id), Vector2i(-1, -1), "log '%s' no mapa" % id)
		assert_true(logs.has(StringName(id)), "log '%s' nos dados" % id)
	assert_eq(
		String((logs.get(&"log_inf_01", {}) as Dictionary).get("unlock_ability", "")),
		String(FreezeRules.ABILITY_ID),
		"o protocolo da quarentena entrega o Núcleo Aquecido"
	)


func test_terminal_is_mute_and_shared_by_two_consoles() -> void:
	var grid: EnergyGrid = _grid()
	assert_not_null(grid, "terminal infirmary carregou")
	if grid == null:
		return
	assert_false(grid.verbose, "terminal mudo")
	assert_true(_meta.get("terminals", []).has(TERMINAL_ID), "fase declara o terminal")
	var consoles: Array[String] = []
	for entry: Dictionary in _entities_of("T"):
		consoles.append(String(entry["params"].get("id", "")))
		assert_eq(String(entry["params"].get("terminal", "")), TERMINAL_ID, "console da fase")
	consoles.sort()
	assert_eq(consoles, ["inf_console_b", "inf_console_c"], "consoles B e C")


func test_no_console_before_the_end_of_the_ward() -> void:
	var dock: Vector2i = _cell_of("inf_dock_02")
	var gate := Vector2i(dock.x - 1, dock.y)
	var ward: Dictionary = _flood(_parsed.get("spawn", Vector2i.ZERO), [gate], "")
	assert_true(ward.size() > 400, "a Ala é grande")
	for entry: Dictionary in _entities_of("T"):
		assert_false(ward.has(entry["cell"]), "console %s antes da Ala" % entry["params"]["id"])
	for id: String in WARD_V9 + WARD_HEATERS:
		assert_true(ward.has(_cell_of(id)), "'%s' fica na Ala" % id)
	assert_true(_cell_of("inf_console_b").x > dock.x, "a doca do fim da Ala vem antes de B")


func test_no_console_past_the_quarantine_door() -> void:
	var door: Vector2i = _cell_of("inf_quarantine_door")
	assert_ne(door, Vector2i(-1, -1), "comporta da quarentena no mapa")
	var wing: Dictionary = _flood(door + Vector2i.RIGHT, [door], "")
	assert_false(wing.is_empty(), "a quarentena existe")
	for entry: Dictionary in _entities_of("T"):
		assert_false(wing.has(entry["cell"]), "console %s depois da quarentena" % entry["params"]["id"])
	assert_false(wing.has(_parsed.get("spawn", Vector2i.ZERO)), "a quarentena é fechada")
	for id: String in [
		"log_inf_01", "log_inf_02", "capacitor_inf_01", "data_inf_02", "inf_node_door",
		"inf_sector_node", "inf_dock_04",
	]:
		assert_true(wing.has(_cell_of(id)), "'%s' fica depois da comporta da quarentena" % id)


func test_the_heated_core_comes_before_the_cryo_chamber() -> void:
	var door: Vector2i = _cell_of("inf_quarantine_door")
	var frozen: Dictionary = _flood(door + Vector2i.RIGHT, [door], ICE_WALL)
	assert_false(frozen.has(_cell_of("log_inf_01")), "sem aquecimento o gelo guarda o protocolo")
	var heated: Dictionary = _flood(door + Vector2i.RIGHT, [door], ICE_WALL, HEATER_WALLS.keys())
	assert_true(heated.has(_cell_of("log_inf_01")), "o aquecedor abre o caminho do protocolo")
	for id: String in ["inf_dock_04", "inf_sector_node", "data_inf_02", "log_inf_02"]:
		assert_false(heated.has(_cell_of(id)), "'%s' só depois do Núcleo Aquecido" % id)


func test_the_sector_node_lives_behind_its_door() -> void:
	var door: Vector2i = _cell_of("inf_node_door")
	var node: Vector2i = _cell_of("inf_sector_node")
	var params: Dictionary = _params_of("inf_sector_node")
	assert_eq(String(params.get("scene", "")), NODE_SCENE, "o tile instancia o Nó")
	assert_eq(String(params.get("sector_id", "")), TERMINAL_ID, "setor do Nó")
	var room: Dictionary = _flood(node, [door], "")
	assert_false(room.has(_cell_of("inf_dock_04")), "a doca fica do lado de fora da porta")
	assert_eq(String(_params_of("inf_node_door").get("system_id", "")), "node_door", "porta meta")
	assert_eq(
		String(_params_of("inf_quarantine_door").get("system_id", "")),
		"quarantine_door",
		"comporta da quarentena"
	)
	assert_eq(
		String(_params_of("inf_pharmacy_door").get("system_id", "")), "pharmacy_door", "farmácia"
	)


func test_the_landing_dock_sits_between_console_c_and_the_quarantine() -> void:
	var dock: Vector2i = _cell_of("inf_dock_03")
	var console: Vector2i = _cell_of("inf_console_c")
	var door: Vector2i = _cell_of("inf_quarantine_door")
	assert_eq(dock.y, console.y, "doca e console no patamar")
	assert_true(console.x < dock.x and dock.x < door.x, "voltando da quarentena passa pela doca")
	var heater: Dictionary = _params_of("inf_heater_landing")
	assert_true(_inside_rect(console, _cell_of("inf_heater_landing"), heater), "C no aquecedor")


func test_systems_are_wired_by_kind() -> void:
	var heater_groups: Dictionary = {}
	for entry: Dictionary in _entities_of("i"):
		var params: Dictionary = entry["params"]
		var heater: String = String(params.get("id", ""))
		assert_eq(String(params.get("kind", "")), "warm", "%s é aquecedor" % heater)
		assert_eq(String(params.get("system_id", "")), "heating", "%s no aquecimento" % heater)
		assert_eq(String(params.get("terminal_id", "")), TERMINAL_ID, "%s no terminal" % heater)
		assert_eq((params.get("rect", []) as Array).size(), 2, "%s com rect" % heater)
		var group: String = String(params.get("group", ""))
		assert_false(group.is_empty(), "%s com grupo" % heater)
		assert_false(heater_groups.has(group), "grupo '%s' repetido" % group)
		heater_groups[group] = heater
	for entry: Dictionary in _entities_of(ICE_WALL):
		var params: Dictionary = entry["params"]
		var wall: String = String(params.get("id", ""))
		assert_false(params.has("system_id"), "%s segue o aquecedor, não o terminal" % wall)
		assert_false(heater_groups.has(String(params.get("group", ""))), "%s sem grupo" % wall)
		var linked: String = String(params.get("heater", ""))
		if not linked.is_empty():
			assert_true(heater_groups.has(linked), "%s aponta um aquecedor que existe" % wall)
	for prefix: String in HEATER_WALLS:
		var heater_id: String = String(HEATER_WALLS[prefix])
		var group: String = String(_params_of(heater_id).get("group", ""))
		for wall: Dictionary in _walls_with_prefix(prefix):
			assert_eq(String(wall["params"].get("heater", "")), group, "%s" % prefix)
	for prefix: String in CORE_WALLS:
		var walls: Array[Dictionary] = _walls_with_prefix(prefix)
		assert_true(walls.size() >= 3, "%s empilhada" % prefix)
		for wall: Dictionary in walls:
			assert_false(wall["params"].has("heater"), "%s só derrete com o Núcleo" % prefix)
	for entry: Dictionary in _entities_of("Y"):
		var params: Dictionary = entry["params"]
		assert_eq(String(params.get("system_id", "")), "sentinels", "V-9 nas sentinelas")
		assert_true((params.get("path", []) as Array).size() >= 2, "V-9 com trilho")
	for entry: Dictionary in _entities_of("h"):
		var params: Dictionary = entry["params"]
		assert_eq(String(params.get("kind", "")), "cold", "zona fria")
		assert_false(params.has("system_id"), "o frio não é ligável")


func test_energy_targets_exist_on_the_map() -> void:
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
		var system: String = String(params.get("system_id", ""))
		if not system.is_empty():
			assert_true(grid.has_system(StringName(system)), "sistema '%s' em %s" % [system, key])
	for system_id: StringName in grid.system_ids():
		for value: Variant in grid.effects_of(system_id):
			var target: String = String((value as Dictionary)["target"])
			if target.begins_with(EnergyGrid.TARGET_GROUP):
				assert_true(groups.has(target.substr(EnergyGrid.TARGET_GROUP.length())), target)
			elif target.begins_with(EnergyGrid.TARGET_ID):
				assert_true(ids.has(target.substr(EnergyGrid.TARGET_ID.length())), target)


func test_the_stretcher_lift_docks_level_with_both_bands() -> void:
	var cell: Vector2i = _cell_of(LIFT_ID)
	var points: PackedVector2Array = MovingPlatform.points_from(
		_params_of(LIFT_ID).get("path", [])
	)
	assert_eq(points.size(), 2, "elevador com duas paradas")
	if points.size() != 2:
		return
	var origin: float = float(cell.y) + 0.5
	assert_almost_eq(origin + points[0].y - 0.25, LIFT_FLOORS[1], 0.01, "estacionado no patamar")
	assert_almost_eq(origin + points[1].y - 0.25, LIFT_FLOORS[0], 0.01, "desce rente à Ala")
	assert_eq(String(_params_of(LIFT_ID).get("system_id", "")), "stretcher_lift", "elevador")


func test_the_secret_room_hides_the_second_log_behind_core_ice() -> void:
	var walls: Array[Vector2i] = []
	for entry: Dictionary in _entities_of("x"):
		assert_eq(String(entry["params"].get("secret_id", "")), "inf_secret_01", "um segredo")
		walls.append(entry["cell"])
	assert_eq(walls.size(), 2, "parede falsa de dois tiles")
	var room: Dictionary = _flood(_cell_of("log_inf_02"), walls, "")
	assert_true(room.has(_cell_of("capacitor_inf_01")), "capacitor na sala secreta")
	assert_false(room.has(_parsed.get("spawn", Vector2i.ZERO)), "a sala só abre pela parede falsa")
	assert_false(room.has(_cell_of("log_inf_01")), "a sala não encosta na quarentena")
	var detour: Dictionary = _flood(_cell_of("log_inf_01"), [], ICE_WALL, HEATER_WALLS.keys())
	assert_false(detour.has(walls[0]), "a parede de gelo do desvio guarda a parede falsa")
	var heaters: Array[Dictionary] = _entities_of("i")
	for wall: Dictionary in _walls_with_prefix("inf_ice_detour"):
		for heater: Dictionary in heaters:
			assert_false(
				_near_rect(wall["cell"], heater["cell"], heater["params"]),
				"a parede do desvio fica fora do alcance de aquecedor"
			)


func test_the_bridge_needs_the_heated_core() -> void:
	var runs: Array[Vector2i] = _thin_runs(BRIDGE_ROW)
	assert_eq(runs.size(), 2, "duas pontes de gelo fino sobre o fosso")
	if runs.size() != 2:
		return
	var middle_gap: int = runs[1].x - runs[0].y - 1
	assert_true(middle_gap >= 3, "vão do meio de %d tiles" % middle_gap)
	var needed: float = float(middle_gap * Balance.TILE_SIZE) - BODY_OVERHANG_PX
	var frozen_speed: float = Balance.WALK_SPEED * Balance.FREEZE_SPEED_MULT
	var frozen_jump: float = Balance.JUMP_HEIGHT * Balance.FREEZE_JUMP_MULT
	assert_true(_reach(frozen_speed, frozen_jump) < needed, "congelado não salta o vão")
	assert_true(_reach(Balance.WALK_SPEED, Balance.JUMP_HEIGHT) > needed, "aquecido salta")
	var west_edge: int = runs[0].x - 1
	while west_edge > 0 and _symbol_at(Vector2i(west_edge, BRIDGE_ROW - 2)) != SOLID:
		west_edge -= 1
	var rise: float = float(2 * Balance.TILE_SIZE)
	assert_eq(_symbol_at(Vector2i(west_edge, BRIDGE_ROW - 2)), SOLID, "borda oeste mais alta")
	assert_true(frozen_jump < rise, "congelado não sobe a borda de dois tiles")
	assert_true(Balance.JUMP_HEIGHT > rise, "aquecido sobe")


func test_every_drop_has_a_way_back() -> void:
	var meta_console_c: Vector2i = _cell_of("inf_console_c")
	var console_b: Vector2i = _cell_of("inf_console_b")
	var drops: Dictionary = {
		"corredor do Nó": [_cell_of("inf_dock_04"), meta_console_c],
		"fundo do poço escuro": [_cell_of("data_inf_02"), meta_console_c],
		"fundo do fosso": [Vector2i(90, 34), meta_console_c],
		"fosso do desvio": [Vector2i(84, 9), meta_console_c],
		"duto congelado": [_cell_of("cell_inf_01"), console_b],
		"poço do elevador": [Vector2i(68, 46), meta_console_c],
	}
	for label: String in drops:
		var start: Vector2i = (drops[label] as Array)[0]
		var goal: Vector2i = (drops[label] as Array)[1]
		var result: Dictionary = LevelReachability.analyze(_map_with_spawn_at(start), _meta)
		assert_true(
			LevelReachability.can_interact_with(result, goal), "do %s volta ao console" % label
		)


func test_the_beds_tell_who_fell_ill() -> void:
	var beds: int = 0
	var empty: int = 0
	for entry: Dictionary in _entities_of("o"):
		var params: Dictionary = entry["params"]
		if params.has("scene"):
			continue
		assert_eq(String(params.get("sheet", "")), PROPS_SHEET, "prop da folha da Enfermaria")
		var frame: int = int(params.get("frame", -1))
		assert_true(frame >= 0 and frame <= 7, "quadro de prop válido")
		if frame == BED_FRAME:
			beds += 1
		elif frame == EMPTY_BED_FRAME:
			empty += 1
	assert_eq(beds + empty, CREW_BEDS, "doze leitos")
	assert_eq(empty, 1, "um leito vazio")


func test_the_dark_stays_dark() -> void:
	var data: Vector2i = _cell_of("data_inf_02")
	var chamber: Dictionary = _flood(data, [], "|I")
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if not LIGHT_SYMBOLS.contains(String(entry.get("symbol", ""))):
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if not chamber.has(cell):
			continue
		assert_true(
			(cell - data).length() > DARK_POCKET_RADIUS_TILES, "luz perto do poço escuro"
		)
	var ward_end: int = _cell_of("inf_dock_02").x
	for entry: Dictionary in _entities_of("@"):
		var params: Dictionary = entry["params"]
		var cell: Vector2i = entry["cell"]
		if cell.x <= _parsed.get("spawn", Vector2i.ZERO).x + 2 or cell.x >= ward_end:
			continue
		assert_true(
			float(params.get("radius", 96.0)) <= WARD_LAMP_MAX_RADIUS,
			"lâmpada da Ala é poça de luz: %s" % params.get("id")
		)
		assert_false(params.has("system_id"), "luz de emergência da Ala sempre acesa")


func test_scene_and_data_agree() -> void:
	assert_true(ResourceLoader.exists(SCENE_PATH), "cena da fase existe")
	assert_eq(String(_meta.get("id", "")), TERMINAL_ID, "id do JSON")
	assert_true(ResourceLoader.exists(String(_meta.get("tileset", ""))), "tileset da Enfermaria")
	assert_true(ResourceLoader.exists(String(_meta.get("entity_tiles", ""))), "folha do setor")
	assert_true(bool(_meta.get("reactor_online", false)), "o timer corre na Enfermaria")
	assert_false(String(_meta.get("ambient_restored", "")).is_empty(), "paleta religada")
	assert_true(
		FileAccess.get_file_as_string("res://tests/scenes.txt").contains(SCENE_PATH),
		"cena registrada no smoke"
	)


func _map_with_spawn_at(cell: Vector2i) -> String:
	var lines: PackedStringArray = _lines.duplicate()
	for row: int in range(lines.size()):
		lines[row] = lines[row].replace(LevelParser.SPAWN, " ")
	var line: String = lines[cell.y]
	lines[cell.y] = line.substr(0, cell.x) + LevelParser.SPAWN + line.substr(cell.x + 1)
	return "\n".join(lines)


func _reach(speed: float, jump: float) -> float:
	var airtime: float = 2.0 * sqrt(2.0 * jump / Balance.GRAVITY)
	return speed * (airtime + Balance.COYOTE_TIME)


func _thin_runs(row: int) -> Array[Vector2i]:
	var runs: Array[Vector2i] = []
	var line: String = _lines[row]
	var start: int = -1
	for x: int in range(line.length() + 1):
		var thin: bool = x < line.length() and line.substr(x, 1) == THIN_ICE
		if thin and start < 0:
			start = x
		elif not thin and start >= 0:
			runs.append(Vector2i(start, x - 1))
			start = -1
	return runs


func _inside_rect(cell: Vector2i, anchor: Vector2i, params: Dictionary) -> bool:
	var rect: Array = params.get("rect", [1, 1])
	return (
		cell.x >= anchor.x and cell.x < anchor.x + int(rect[0])
		and cell.y >= anchor.y and cell.y < anchor.y + int(rect[1])
	)


func _near_rect(cell: Vector2i, anchor: Vector2i, params: Dictionary) -> bool:
	var rect: Array = params.get("rect", [1, 1])
	var size := Vector2(float(rect[0]), float(rect[1]))
	var center: Vector2 = Vector2(anchor) + size * 0.5
	var half: Vector2 = size * RECT_LIGHT_COVER * 0.5 + Vector2.ONE * 2.0
	return (
		absf(float(cell.x) + 0.5 - center.x) < half.x
		and absf(float(cell.y) + 0.5 - center.y) < half.y
	)


func _walls_with_prefix(prefix: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for entry: Dictionary in _entities_of(ICE_WALL):
		if String(entry["params"].get("id", "")).begins_with(prefix):
			found.append(entry)
	return found


func _flood(
	start: Vector2i, walls: Array, extra_blocking: String, open_prefixes: Array = []
) -> Dictionary:
	var blocked: Dictionary = {}
	for value: Variant in walls:
		var cell: Vector2i = value
		while cell.y >= 0 and not BLOCKING.contains(_symbol_at(cell)):
			blocked[cell] = true
			cell += Vector2i.UP
	if not extra_blocking.is_empty():
		for entry: Dictionary in _parsed.get("entities", []) as Array:
			if not extra_blocking.contains(String(entry.get("symbol", ""))):
				continue
			var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
			var id: String = String(
				(_meta.get("entities", {}) as Dictionary).get(LevelParser.cell_key(cell), {}).get(
					"id", ""
				)
			)
			var opened: bool = false
			for prefix: Variant in open_prefixes:
				opened = opened or id.begins_with(String(prefix))
			if not opened:
				blocked[cell] = true
	var seen: Dictionary = {}
	if blocked.has(start) or BLOCKING.contains(_symbol_at(start)):
		return seen
	seen[start] = true
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var current: Vector2i = pending.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + step
			if seen.has(next) or blocked.has(next) or BLOCKING.contains(_symbol_at(next)):
				continue
			seen[next] = true
			pending.append(next)
	return seen


func _entities_of(symbol: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var entities: Dictionary = _meta.get("entities", {})
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) != symbol:
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		found.append({"cell": cell, "params": entities.get(LevelParser.cell_key(cell), {})})
	return found


func _entity_cells() -> Dictionary:
	var cells: Dictionary = {}
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		cells[entry.get("cell", Vector2i.ZERO)] = String(entry.get("symbol", ""))
	return cells


func _count_symbol(symbol: String) -> int:
	var total: int = 0
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == symbol:
			total += 1
	return total


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


func _grid() -> EnergyGrid:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	return EnergyGrid.from_dict(raw) if raw is Dictionary else null


func _cell_of(entity_id: String) -> Vector2i:
	for key: Variant in _meta.get("entities", {}):
		if String((_meta["entities"] as Dictionary)[key].get("id", "")) == entity_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func _params_of(entity_id: String) -> Dictionary:
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if String(params.get("id", "")) == entity_id:
			return params
	return {}
