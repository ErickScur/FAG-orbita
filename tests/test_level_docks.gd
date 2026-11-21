extends TestCase

const MAP_PATH: String = "res://data/levels/docks.txt"
const META_PATH: String = "res://data/levels/docks.json"
const ENERGY_PATH: String = "res://data/energy/docks.json"
const SCENE_PATH: String = "res://scenes/levels/docks.tscn"
const INFIRMARY_SCENE: String = "res://scenes/levels/infirmary.tscn"
const CORE_HUB_SCENE: String = "res://scenes/levels/core_hub.tscn"
const CORE_HUB_META: String = "res://data/levels/core_hub.json"
const TERMINAL_ID: String = "docks"
const MAP_WIDTH: int = 120
const MAP_HEIGHT: int = 50
const SOLID: String = "#"
const EXPECTED_COUNTS: Dictionary = {
	"E": 1, "T": 3, "|": 3, "D": 5, "L": 2, "l": 0, "r": 2, "C": 1, "x": 2, "c": 5, "k": 3,
	"V": 3, "A": 3, "S": 2, "X": 3, "Y": 3, "m": 1, "v": 1,
}
const NODE_ID: String = "dk_sector_node"
const NODE_DOOR_ID: String = "dk_node_door"
const HANGAR_VACUUM: String = "dk_vac_hangar"
const DOUBLE_JUMP_GATES: Array[String] = ["dk_console_c", NODE_ID]
const FIRST_HALF: Array[String] = ["log_dk_01", "dk_console_b", "dk_console_a", "log_dk_02"]

var _parsed: Dictionary = {}
var _meta: Dictionary = {}
var _lines: PackedStringArray = []


func before_each() -> void:
	var text: String = FileAccess.get_file_as_string(MAP_PATH)
	_lines = text.strip_edges(false, true).split("\n")
	_parsed = LevelParser.parse(text, LevelBuilder.entity_chars())
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	_meta = raw if raw is Dictionary else {}


func test_map_parses_without_errors() -> void:
	var errors: PackedStringArray = _parsed.get("errors", [])
	assert_true(errors.is_empty(), "erros do parser: %s" % ", ".join(errors))
	assert_eq(int(_parsed.get("width", 0)), MAP_WIDTH, "largura")
	assert_eq(int(_parsed.get("height", 0)), MAP_HEIGHT, "altura")


func test_entity_counts_match_the_paper() -> void:
	for symbol: String in EXPECTED_COUNTS:
		assert_eq(_count(symbol), int(EXPECTED_COUNTS[symbol]), "quantidade de '%s'" % symbol)


func test_every_entity_key_points_to_an_entity_cell() -> void:
	var cells: Dictionary = {}
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		cells[entry.get("cell", Vector2i.ZERO)] = true
	for key: Variant in _meta.get("entities", {}):
		assert_true(cells.has(LevelParser.key_to_cell(String(key))), "chave '%s' sem entidade" % key)


func test_fragments_and_secret_are_the_promised_ones() -> void:
	for wanted: String in ["log_dk_01", "log_dk_02", "data_dk_01", "data_dk_02", "capacitor_dk_01"]:
		assert_true(_find(wanted) != Vector2i(-1, -1), "'%s' no mapa" % wanted)
	var walls: Dictionary = {}
	for key: Variant in _meta.get("entities", {}):
		var secret: String = String(((_meta["entities"] as Dictionary)[key] as Dictionary).get(
			"secret_id", ""
		))
		if not secret.is_empty():
			walls[secret] = int(walls.get(secret, 0)) + 1
	assert_eq(walls.size(), 1, "uma área secreta")
	assert_eq(int(walls.get("dk_secret_01", 0)), 2, "parede falsa de dois tiles")


func test_the_terminal_is_mute_and_orbita_talks_only_at_milestones() -> void:
	assert_true((_meta.get("triggers", []) as Array).is_empty(), "sem gatilhos de fala na fase")
	assert_eq(String(_meta.get("on_enter_dialogue", "")), "dk_enter", "fala de entrada")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	assert_false(bool((raw as Dictionary).get("verbose", false)), "terminal mudo")


func test_entities_bind_to_systems_that_exist() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	var known: Dictionary = {}
	for value: Variant in (raw as Dictionary).get("systems", []) as Array:
		known[String((value as Dictionary).get("id", ""))] = true
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		var system_id: String = String(params.get("system_id", ""))
		if system_id.is_empty():
			continue
		assert_eq(String(params.get("terminal_id", "")), TERMINAL_ID, "terminal em %s" % key)
		assert_true(known.has(system_id), "sistema '%s' em %s" % [system_id, key])


func test_the_hangar_vacuum_answers_the_containment_field_inverted() -> void:
	var cell: Vector2i = _find(HANGAR_VACUUM)
	var params: Dictionary = _params(cell)
	assert_eq(String(params.get("group", "")), HANGAR_VACUUM, "zona no grupo")
	assert_eq(String(params.get("system_id", "x")), "", "system_id vazio explícito (pitfall F60)")
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	var inverted: bool = false
	for value: Variant in (raw as Dictionary).get("systems", []) as Array:
		var entry: Dictionary = value
		if String(entry.get("id", "")) != "containment":
			continue
		for effect: Variant in entry.get("effects", []) as Array:
			var target: String = String((effect as Dictionary).get("target", ""))
			var action: String = String((effect as Dictionary).get("action", ""))
			inverted = inverted or (target == "group:" + HANGAR_VACUUM and action == "invert")
	assert_true(inverted, "a contenção inverte o vácuo do hangar")


func test_no_console_after_the_node_door() -> void:
	var door: Vector2i = _find(NODE_DOOR_ID)
	var node: Vector2i = _find(NODE_ID)
	var bulkhead: Array = []
	var cell: Vector2i = door
	while _char(cell) != SOLID:
		bulkhead.append(cell)
		cell += Vector2i.UP
	var reached: Dictionary = _flood(node, bulkhead)
	assert_false(reached.has(_find("dk_console_c")), "C fica antes da comporta")
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == "T":
			assert_false(reached.has(entry.get("cell")), "console depois da comporta (ADR-F60-001)")
	assert_true(_flood(_parsed.get("spawn", Vector2i.ZERO), []).has(node), "o Nó tem caminho")


func test_the_first_half_needs_only_the_vacuum() -> void:
	var profile: Dictionary = LevelReachability.default_profile()
	profile["double_jump_enabled"] = false
	var result: Dictionary = LevelReachability.analyze(
		FileAccess.get_file_as_string(MAP_PATH), _meta, profile
	)
	for wanted: String in FIRST_HALF:
		assert_true(
			LevelReachability.can_interact_with(result, _find(wanted)),
			"'%s' alcançável sem o Propulsor" % wanted
		)
	for gate: String in DOUBLE_JUMP_GATES:
		assert_false(
			LevelReachability.can_interact_with(result, _find(gate)),
			"'%s' deveria exigir o pulo duplo" % gate
		)


func test_the_second_half_opens_with_the_double_jump() -> void:
	var result: Dictionary = LevelReachability.analyze_file(MAP_PATH)
	for gate: String in DOUBLE_JUMP_GATES:
		assert_true(
			LevelReachability.can_interact_with(result, _find(gate)),
			"'%s' alcançável com o Propulsor" % gate
		)
	assert_true(LevelReachability.is_touched(result, _find("data_dk_02")), "Dado do anel externo")
	assert_true(LevelReachability.is_touched(result, _find("data_dk_01")), "Dado do berço")


func test_the_scene_wires_the_thruster_and_ends_the_demo() -> void:
	var state: SceneState = (load(SCENE_PATH) as PackedScene).get_state()
	var narrative: Dictionary = _node_properties(state, "Narrative")
	assert_eq(String(narrative.get("sector_id", "")), "docks", "setor")
	assert_eq(String(narrative.get("ability_id", "")), String(VacuumRules.ABILITY_ID), "propulsor")
	assert_eq(String(narrative.get("ability_tutorial", "")), "tut_thruster", "cartão do propulsor")
	assert_eq(String(narrative.get("next_scene", "")), "", "as Docas fecham a demo (até a F64)")
	var infirmary: Dictionary = _node_properties(
		(load(INFIRMARY_SCENE) as PackedScene).get_state(), "Narrative"
	)
	assert_eq(String(infirmary.get("next_scene", "")), CORE_HUB_SCENE, "Enfermaria volta ao Núcleo")


func test_the_hub_has_a_revisit_after_the_docks() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(CORE_HUB_META))
	var block: Dictionary = SectorRevisit.active_block(raw, [&"greenhouse", &"lab", &"docks"])
	assert_eq(String(block.get("after_sector", "")), "docks", "entrada das Docas")
	assert_eq(String(block.get("objective", "")), "obj_core_memory", "próximo setor")
	var after_infirmary: Dictionary = SectorRevisit.active_block(
		raw, [&"greenhouse", &"lab", &"infirmary"]
	)
	assert_eq(String(after_infirmary.get("after_sector", "")), "infirmary", "entrada da Enfermaria")
	assert_eq(String(after_infirmary.get("objective", "")), "obj_core_docks", "rumo às Docas")
	assert_eq(
		String(after_infirmary.get("on_enter_dialogue", "")), "core_return_infirmary",
		"fala de marco da Enfermaria"
	)
	var everything: Dictionary = SectorRevisit.active_block(
		raw, [&"greenhouse", &"lab", &"infirmary", &"docks"]
	)
	assert_eq(String(everything.get("after_sector", "")), "docks", "as Docas vêm depois")


func test_the_hub_exit_to_the_docks_is_live() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CORE_HUB_META))
	var exits: Dictionary = ArrivalRoute.exits(raw)
	var found: bool = false
	for key: Variant in exits:
		if String((exits[key] as Dictionary).get("target", "")) == SCENE_PATH:
			found = true
	assert_true(found, "o hub tem uma saída viva para as Docas")
	assert_false(
		(raw.get("reserved_exits", {}) as Dictionary).has("125,11"), "a vaga foi consumida"
	)


func _node_properties(state: SceneState, node_name: String) -> Dictionary:
	var properties: Dictionary = {}
	for index: int in range(state.get_node_count()):
		if String(state.get_node_name(index)) != node_name:
			continue
		for property: int in range(state.get_node_property_count(index)):
			properties[String(state.get_node_property_name(index, property))] = (
				state.get_node_property_value(index, property)
			)
	return properties


func _flood(start: Vector2i, walls: Array) -> Dictionary:
	var seen: Dictionary = {start: true}
	var pending: Array[Vector2i] = [start]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if seen.has(next) or walls.has(next) or _char(next) == SOLID:
				continue
			seen[next] = true
			pending.append(next)
	return seen


func _char(cell: Vector2i) -> String:
	if cell.y < 0 or cell.y >= _lines.size() or cell.x < 0 or cell.x >= _lines[cell.y].length():
		return SOLID
	return _lines[cell.y][cell.x]


func _count(symbol: String) -> int:
	var total: int = 0
	for line: String in _lines:
		total += line.count(symbol)
	return total


func _find(entity_id: String) -> Vector2i:
	for key: Variant in _meta.get("entities", {}):
		if String(((_meta["entities"] as Dictionary)[key] as Dictionary).get("id", "")) == entity_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func _params(cell: Vector2i) -> Dictionary:
	return (_meta.get("entities", {}) as Dictionary).get(LevelParser.cell_key(cell), {})
