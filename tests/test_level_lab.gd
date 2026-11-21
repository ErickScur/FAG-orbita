extends TestCase

const MAP_PATH: String = "res://data/levels/lab.txt"
const META_PATH: String = "res://data/levels/lab.json"
const ENERGY_PATH: String = "res://data/energy/lab.json"
const SCENE_PATH: String = "res://scenes/levels/lab.tscn"
const NODE_SCENE: String = "res://scenes/world/sector_node.tscn"
const CAMPAIGN_METAS: Array[String] = [
	"res://data/levels/core_hub.json", "res://data/levels/greenhouse.json", META_PATH
]
const TERMINAL_ID: String = "lab"
const MAP_WIDTH: int = 112
const MAP_HEIGHT: int = 44
const SOLID: String = "#"
const MAGNETIC: String = "M"
const BLOCKING: String = "#M"
const LIGHT_SYMBOLS: String = "@iX"
const DARK_POCKET_RADIUS_TILES: int = 8
const RECT_LIGHT_COVER: float = 1.3
const FURNACE_KIND: String = "furnace"
const HEAT_KINDS: Array[String] = ["warm", "furnace"]
const EXPECTED_COUNTS: Dictionary = {
	"E": 1, "T": 3, "|": 3, "S": 2, "~": 3, "m": 1, "X": 5, "v": 5, "i": 4, "h": 6,
	"D": 4, "L": 2, "l": 0, "r": 2, "C": 1, "x": 2, "c": 3, "k": 3, "o": 1, "@": 2,
}
const LIFT_ID: String = "lab_lift"
const LIFT_FLOORS: Array[float] = [42.0, 16.0]

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


func test_map_is_wide_and_bigger_than_the_greenhouse() -> void:
	assert_eq(int(_parsed.get("width", 0)), MAP_WIDTH, "largura do Laboratório")
	assert_eq(int(_parsed.get("height", 0)), MAP_HEIGHT, "altura do Laboratório")
	assert_true(MAP_WIDTH * MAP_HEIGHT > 48 * 64, "maior que a Estufa")
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
	assert_eq(String(_meta.get("on_enter_dialogue", "")), "lab_enter", "fala de entrada")
	for id: String in ["lab_enter", "lab_heat_sink", "lab_restored"]:
		assert_true(sequences.has(StringName(id)), "fala de marco '%s'" % id)
	for value: Variant in _meta.get("triggers", []) as Array:
		var trigger: Dictionary = value
		assert_false(trigger.has("dialogue"), "gatilho '%s' fala fora de marco" % trigger.get("id"))
		assert_false(trigger.has("objective"), "gatilho '%s' troca o objetivo" % trigger.get("id"))


func test_two_logs_and_the_heat_sink() -> void:
	var logs: Dictionary = DialogueManager.logs()
	for id: String in ["log_lab_01", "log_lab_02"]:
		assert_ne(_cell_of(id), Vector2i(-1, -1), "log '%s' no mapa" % id)
		assert_true(logs.has(StringName(id)), "log '%s' nos dados" % id)
	assert_eq(
		String((logs.get(&"log_lab_01", {}) as Dictionary).get("unlock_ability", "")),
		"heat_sink",
		"o protocolo da ala entrega o Dissipador"
	)


func test_terminal_is_mute_and_shared_by_three_consoles() -> void:
	var grid: EnergyGrid = _grid()
	assert_not_null(grid, "terminal lab carregou")
	if grid == null:
		return
	assert_false(grid.verbose, "terminal mudo")
	assert_true(_meta.get("terminals", []).has(TERMINAL_ID), "fase declara o terminal")
	var consoles: int = 0
	for entry: Dictionary in _entities_of("T"):
		consoles += 1
		assert_eq(String(entry["params"].get("terminal", "")), TERMINAL_ID, "console do lab")
	assert_eq(consoles, 3, "consoles A, B e C")


func test_no_console_past_the_research_wing_door() -> void:
	var door: Vector2i = _cell_of("lab_wing_door")
	assert_ne(door, Vector2i(-1, -1), "comporta da ala no mapa")
	var region: Dictionary = _flood(door + Vector2i.RIGHT, [door])
	assert_false(region.is_empty(), "a ala existe")
	for entry: Dictionary in _entities_of("T"):
		assert_false(region.has(entry["cell"]), "console %s depois da ala" % entry["params"]["id"])
	assert_false(region.has(_parsed.get("spawn", Vector2i.ZERO)), "a ala é fechada")
	for id: String in ["log_lab_01", "lab_node_door", "lab_sector_node", "lab_dock_04"]:
		assert_true(region.has(_cell_of(id)), "'%s' fica depois da comporta da ala" % id)


func test_the_sector_node_lives_behind_its_door() -> void:
	var door: Vector2i = _cell_of("lab_node_door")
	var node: Vector2i = _cell_of("lab_sector_node")
	var params: Dictionary = _params_of("lab_sector_node")
	assert_eq(String(params.get("scene", "")), NODE_SCENE, "o tile instancia o Nó")
	assert_eq(String(params.get("sector_id", "")), TERMINAL_ID, "setor do Nó")
	var room: Dictionary = _flood(node, [door])
	assert_false(room.has(_cell_of("lab_dock_04")), "a doca fica do lado de fora da porta")
	assert_eq(String(_params_of("lab_node_door").get("system_id", "")), "node_door", "porta meta")
	assert_eq(String(_params_of("lab_wing_door").get("system_id", "")), "wing_door", "porta da ala")


func test_the_landing_dock_comes_before_console_c() -> void:
	var dock: Vector2i = _cell_of("lab_dock_03")
	var console: Vector2i = _cell_of("lab_console_c")
	var door: Vector2i = _cell_of("lab_wing_door")
	assert_eq(dock.y, console.y, "doca e console no patamar")
	assert_true(
		console.x < dock.x and dock.x < door.x, "voltando da ala passa pela doca antes de C"
	)


func test_systems_are_wired_by_kind() -> void:
	for entry: Dictionary in _entities_of("i"):
		var params: Dictionary = entry["params"]
		var island: String = String(params.get("id", ""))
		var linked: String = String(params.get("system_id", ""))
		assert_eq(linked, "cooling", "ilha %s na refrigeração" % island)
		assert_eq(String(params.get("terminal_id", "")), TERMINAL_ID, "ilha no terminal lab")
		assert_eq((params.get("rect", []) as Array).size(), 2, "ilha com rect")
	for entry: Dictionary in _entities_of("v"):
		var params: Dictionary = entry["params"]
		assert_eq(String(params.get("group", "")), "lab_vents", "vapor %s no grupo" % params["id"])
		assert_false(params.has("system_id"), "vapor sem vínculo direto (o alívio inverte o grupo)")
	for entry: Dictionary in _entities_of("~"):
		var params: Dictionary = entry["params"]
		var spore: String = String(params.get("id", ""))
		assert_eq(String(params.get("group", "")), "lab_spores", "esporo %s no grupo" % spore)
		assert_true(params.has("system_id"), "esporo declara system_id")
		assert_eq(String(params.get("system_id", "x")), "", "esporo sem sistema próprio")
		assert_eq(String(params.get("terminal_id", "")), TERMINAL_ID, "esporo no terminal lab")
	for entry: Dictionary in _entities_of("X"):
		assert_eq(String(entry["params"].get("system_id", "")), "towers", "torre nas torres")
	var furnaces: int = 0
	for entry: Dictionary in _entities_of("h"):
		var params: Dictionary = entry["params"]
		assert_true(HEAT_KINDS.has(String(params.get("kind", ""))), "tipo de calor válido")
		assert_false(params.has("system_id"), "calor não é ligável")
		if String(params.get("kind", "")) == FURNACE_KIND:
			furnaces += 1
	assert_true(furnaces >= 2 and furnaces <= 3, "dois ou três trechos de fornalha")


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


func test_the_lift_docks_level_with_both_floors() -> void:
	var cell: Vector2i = _cell_of(LIFT_ID)
	var points: PackedVector2Array = MovingPlatform.points_from(
		_params_of(LIFT_ID).get("path", [])
	)
	assert_eq(points.size(), 2, "elevador com duas paradas")
	if points.size() != 2:
		return
	var origin: float = float(cell.y) + 0.5
	assert_almost_eq(origin + points[0].y - 0.25, LIFT_FLOORS[1], 0.01, "estacionado no patamar")
	assert_almost_eq(origin + points[1].y - 0.25, LIFT_FLOORS[0], 0.01, "desce rente ao piso")
	var system: String = String(_params_of(LIFT_ID).get("system_id", ""))
	assert_eq(system, "sample_lift", "elevador de amostras")


func test_the_secret_room_hides_the_second_log() -> void:
	var walls: Array[Vector2i] = []
	for entry: Dictionary in _entities_of("x"):
		assert_eq(String(entry["params"].get("secret_id", "")), "lab_secret_01", "um segredo")
		walls.append(entry["cell"])
	assert_eq(walls.size(), 2, "parede falsa de dois tiles")
	var room: Dictionary = _flood(_cell_of("log_lab_02"), walls)
	assert_true(room.has(_cell_of("capacitor_lab_01")), "capacitor na sala secreta")
	assert_false(room.has(_parsed.get("spawn", Vector2i.ZERO)), "a sala só abre pela parede falsa")


func test_the_furnace_data_sits_in_a_dark_pocket() -> void:
	var data: Vector2i = _cell_of("data_lab_02")
	assert_ne(data, Vector2i(-1, -1), "dado da fornalha no mapa")
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		var symbol: String = String(entry.get("symbol", ""))
		if not LIGHT_SYMBOLS.contains(symbol):
			continue
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		assert_true(
			(cell - data).length() > DARK_POCKET_RADIUS_TILES, "luz '%s' perto do bolsão" % symbol
		)
	for entry: Dictionary in _entities_of("h"):
		var rect: Array = entry["params"].get("rect", [1, 1])
		var size := Vector2(float(rect[0]), float(rect[1]))
		var center: Vector2 = Vector2(entry["cell"]) + size * 0.5
		var half: Vector2 = size * RECT_LIGHT_COVER * 0.5
		var inside: bool = (
			absf(float(data.x) + 0.5 - center.x) < half.x
			and absf(float(data.y) + 0.5 - center.y) < half.y
		)
		assert_false(inside, "o brilho de '%s' alcança o bolsão" % entry["params"]["id"])


func test_scene_and_data_agree() -> void:
	assert_true(ResourceLoader.exists(SCENE_PATH), "cena da fase existe")
	assert_eq(String(_meta.get("id", "")), TERMINAL_ID, "id do JSON")
	assert_true(ResourceLoader.exists(String(_meta.get("tileset", ""))), "tileset do Lab")
	assert_true(ResourceLoader.exists(String(_meta.get("entity_tiles", ""))), "folha do setor")
	assert_true(bool(_meta.get("reactor_online", false)), "o timer corre no Lab")
	assert_false(String(_meta.get("ambient_restored", "")).is_empty(), "paleta religada")
	assert_true(
		FileAccess.get_file_as_string("res://tests/scenes.txt").contains(SCENE_PATH),
		"cena registrada no smoke"
	)


func _flood(start: Vector2i, walls: Array) -> Dictionary:
	var blocked: Dictionary = {}
	for value: Variant in walls:
		var cell: Vector2i = value
		while cell.y >= 0 and not BLOCKING.contains(_symbol_at(cell)):
			blocked[cell] = true
			cell += Vector2i.UP
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
		if String(entry.get("symbol", "")) == MAGNETIC:
			continue
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
