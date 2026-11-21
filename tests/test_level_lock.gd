extends TestCase

const MAP_PATH: String = "res://data/levels/docks.txt"
const META_PATH: String = "res://data/levels/docks.json"
const BOSS_ID: String = "lock_serralheiro"
const BOSS_SYMBOL: String = "K"
const COUPLER_SYMBOL: String = "A"
const SOLID: String = "#"
const EMPTY: String = " "
const SPAWN: String = "P"
const VACUUM: String = "V"
const NODE_ID: String = "dk_sector_node"
const VESTIBULE_DOCK: String = "dk_dock_05"
const DOCK_SYMBOL: String = "D"
const PATROL_SYMBOL: String = "S"
const DOOR_SYMBOL: String = "|"
const LANDING: Vector2i = Vector2i(91, 40)
const CENTER_FLOOR: Vector2i = Vector2i(100, 43)

var _lines: PackedStringArray = []
var _meta: Dictionary = {}
var _boss: Dictionary = {}
var _boss_cell: Vector2i = Vector2i(-1, -1)


func before_each() -> void:
	var text: String = FileAccess.get_file_as_string(MAP_PATH)
	_lines = text.strip_edges(false, true).split("\n")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	_meta = raw if raw is Dictionary else {}
	_boss_cell = Vector2i(-1, -1)
	_boss = {}
	var entities: Dictionary = _meta.get("entities", {})
	for key: Variant in entities:
		var params: Variant = entities[key]
		if params is Dictionary and String((params as Dictionary).get("id", "")) == BOSS_ID:
			_boss = params
			_boss_cell = LevelParser.key_to_cell(String(key))


func test_the_boss_sits_on_the_rail_of_the_arena() -> void:
	assert_ne(_boss_cell, Vector2i(-1, -1), "Serralheiro no JSON")
	assert_eq(_char(_boss_cell), BOSS_SYMBOL, "'K' no mapa")
	var arena: Rect2i = _rect("arena")
	assert_eq(arena, Rect2i(84, 32, 34, 12), "a antessala da F62 com o teto do trilho")
	assert_true(arena.has_point(_boss_cell), "estacionado dentro da arena")
	assert_eq(_boss_cell.y, arena.position.y, "no trilho do teto")
	var couplers: Array = _boss.get("couplers", [])
	assert_eq(couplers.size(), 3, "três acopladores")
	for coupler: Variant in couplers:
		var cell: Vector2i = _find(String(coupler))
		assert_eq(_char(cell), COUPLER_SYMBOL, "'%s' é um acoplador" % coupler)
		assert_true(_rect("trigger").has_point(cell), "'%s' dentro do gatilho" % coupler)
	assert_eq(String(_boss.get("node", "")), NODE_ID, "o Nó fica atrás do chefe")


func test_couplers_are_only_driven_by_the_boss() -> void:
	for coupler: Variant in _boss.get("couplers", []):
		var params: Dictionary = _entity(String(coupler))
		assert_eq(String(params.get("system_id", "-")), "", "'%s' sem sistema" % coupler)


func test_gate_hatch_and_bays_fit_the_map() -> void:
	var gate: Rect2i = _rect("gate")
	for cell: Vector2i in _cells(gate):
		assert_eq(_char(cell), EMPTY, "comporta em célula livre %s" % cell)
		assert_true(_rect("arena").has_point(cell), "comporta dentro da arena")
	assert_eq(_char(Vector2i(gate.position.x, gate.end.y)), SOLID, "a comporta desce até o piso")
	var hatch: Rect2i = _rect("hatch")
	for cell: Vector2i in _cells(hatch):
		assert_eq(_char(cell), EMPTY, "escotilha no poço %s" % cell)
		assert_eq(cell.y, _rect("arena").position.y - 1, "escotilha logo acima da arena")
	for value: Variant in _boss.get("bays", []):
		var cell := Vector2i(int(value[0]), int(value[1]))
		assert_eq(cell.y, _rect("arena").position.y, "baia no teto")
		assert_eq(_char(Vector2i(cell.x, cell.y - 1)), SOLID, "baia presa no teto")


func test_every_coupler_is_reachable_in_every_state() -> void:
	for state: String in ["open", "gate", "vent"]:
		var result: Dictionary = _analyze(state, LANDING, true)
		for coupler: Variant in _boss.get("couplers", []):
			assert_true(
				LevelReachability.can_stand_at(result, _find(String(coupler))),
				"'%s' alcançável com a arena em '%s'" % [coupler, state]
			)


func test_each_coupler_reaches_the_others_with_the_gate_shut() -> void:
	var couplers: Array = _boss.get("couplers", [])
	for from: Variant in couplers:
		var result: Dictionary = _analyze("gate", _find(String(from)), true)
		for to: Variant in couplers:
			assert_true(
				LevelReachability.can_stand_at(result, _find(String(to))),
				"de '%s' a '%s' com a comporta fechada" % [from, to]
			)


func test_the_gate_cuts_the_floor_route() -> void:
	var start: Vector2i = _find(String((_boss.get("couplers", []) as Array)[0]))
	var open: Dictionary = _analyze("open", start, false)
	assert_true(LevelReachability.can_stand_at(open, CENTER_FLOOR), "aberta: pelo piso")
	var shut: Dictionary = _analyze("gate", start, false)
	assert_false(LevelReachability.can_stand_at(shut, CENTER_FLOOR), "fechada: sem pulo duplo, não")
	var climb: Dictionary = _analyze("gate", start, true)
	assert_true(LevelReachability.can_stand_at(climb, CENTER_FLOOR), "fechada: por cima, com pulo duplo")


func test_the_node_waits_on_the_plinth_and_there_is_no_way_back() -> void:
	var result: Dictionary = _analyze("open", LANDING, true)
	assert_true(LevelReachability.can_interact_with(result, _find(NODE_ID)), "Nó alcançável depois")
	assert_false(
		LevelReachability.can_stand_at(result, _find(VESTIBULE_DOCK)),
		"a escotilha selada não deixa voltar ao vestíbulo"
	)
	var walk: Dictionary = _analyze("open", LANDING, false)
	assert_false(LevelReachability.can_interact_with(walk, _find(NODE_ID)), "o estrado pede pulo duplo")


func test_no_dock_shares_a_floor_with_a_patrol() -> void:
	var docks: int = 0
	for y: int in range(_lines.size() - 1):
		for x: int in range(_lines[y].length()):
			if _lines[y][x] != DOCK_SYMBOL:
				continue
			docks += 1
			var run: String = _floor_run(Vector2i(x, y))
			assert_false(run.contains(PATROL_SYMBOL), "doca %d,%d longe da patrulha" % [x, y])
	assert_true(docks > 0, "as Docas têm docas")


func _floor_run(cell: Vector2i) -> String:
	var run: String = _char(cell)
	for step: int in [-1, 1]:
		var probe: Vector2i = cell + Vector2i(step, 0)
		while _walkable(probe):
			run += _char(probe)
			probe.x += step
	return run


func _walkable(cell: Vector2i) -> bool:
	var here: String = _char(cell)
	if here == "" or here == SOLID or here == DOOR_SYMBOL:
		return false
	return _char(cell + Vector2i(0, 1)) == SOLID


func _analyze(state: String, start: Vector2i, double_jump: bool) -> Dictionary:
	var grid: Array[Array] = []
	for line: String in _lines:
		var row: Array = Array(line.split(""))
		for column: int in range(row.size()):
			if row[column] == SPAWN:
				row[column] = EMPTY
		grid.append(row)
	for cell: Vector2i in _cells(_rect("hatch")):
		grid[cell.y][cell.x] = SOLID
	if state != "open":
		for cell: Vector2i in _cells(_rect("gate")):
			grid[cell.y][cell.x] = SOLID
	var meta: Dictionary = _meta.duplicate(true)
	var entities: Dictionary = meta.get("entities", {})
	if state == "vent":
		var arena: Rect2i = _rect("arena")
		var corner := Vector2i(arena.position.x, arena.position.y + 1)
		grid[corner.y][corner.x] = VACUUM
		entities[LevelParser.cell_key(corner)] = {"rect": [arena.size.x, arena.size.y - 1]}
	grid[start.y][start.x] = SPAWN
	var rows: PackedStringArray = []
	for row: Array in grid:
		rows.append("".join(PackedStringArray(row)))
	var profile: Dictionary = LevelReachability.default_profile()
	profile[LevelReachability.PROFILE_DOUBLE_JUMP] = double_jump
	return LevelReachability.analyze("\n".join(rows), meta, profile)


func _rect(key: String) -> Rect2i:
	var raw: Array = _boss.get(key, [])
	if raw.size() < 4:
		return Rect2i()
	return Rect2i(int(raw[0]), int(raw[1]), int(raw[2]), int(raw[3]))


func _cells(rect: Rect2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			cells.append(Vector2i(x, y))
	return cells


func _char(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= _lines.size() or cell.x < 0 or cell.x >= _lines[cell.y].length():
		return ""
	return _lines[cell.y][cell.x]


func _entity(entity_id: String) -> Dictionary:
	var entities: Dictionary = _meta.get("entities", {})
	for key: Variant in entities:
		var params: Variant = entities[key]
		if params is Dictionary and String((params as Dictionary).get("id", "")) == entity_id:
			return params
	return {}


func _find(entity_id: String) -> Vector2i:
	var entities: Dictionary = _meta.get("entities", {})
	for key: Variant in entities:
		var params: Variant = entities[key]
		if params is Dictionary and String((params as Dictionary).get("id", "")) == entity_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)
