extends TestCase

const MAP_PATH: String = "res://data/levels/memory_core.txt"
const META_PATH: String = "res://data/levels/memory_core.json"
const ENERGY_PATH: String = "res://data/energy/memory_core.json"
const LOGS_PATH: String = "res://data/logs/memory_core.json"
const DIALOGUE_PATH: String = "res://data/dialogue/memory_core.json"
const SCENE_PATH: String = "res://scenes/levels/memory_core.tscn"
const CORE_HUB_SCENE: String = "res://scenes/levels/core_hub.tscn"
const CORE_HUB_META: String = "res://data/levels/core_hub.json"
const CORE_HUB_MAP: String = "res://data/levels/core_hub.txt"
const REACTOR_SCENE: String = "res://scenes/levels/reactor_core.tscn"
const CAMPAIGN_METAS: Array[String] = [
	"res://data/levels/core_hub.json",
	"res://data/levels/greenhouse.json",
	"res://data/levels/lab.json",
	"res://data/levels/infirmary.json",
	"res://data/levels/docks.json",
	META_PATH,
]
const MAP_WIDTH: int = 126
const MAP_HEIGHT: int = 60
const EXPECTED_COUNTS: Dictionary = {
	"E": 1, "P": 1, "T": 2, "|": 2, "D": 3, "L": 1, "l": 0, "r": 1, "c": 2, "k": 2, "m": 1,
	"M": 14, "@": 11, "C": 0, "S": 0, "X": 0, "Y": 0,
}
const MILESTONES: Array[String] = ["mem_enter", "mem_luto", "mem_restored"]
const FINAL_LOG: String = "log_mem_final"
const PARTY_LOG: String = "log_mem_01"
const NODE_ID: String = "mem_sector_node"
const WALKWAY_ID: String = "mem_walkway"

var _parsed: Dictionary = {}
var _meta: Dictionary = {}
var _grid: EnergyGrid = null
var _text: String = ""


func before_each() -> void:
	_text = FileAccess.get_file_as_string(MAP_PATH)
	_parsed = LevelParser.parse(_text, LevelBuilder.entity_chars())
	_meta = _json(META_PATH)
	var energy: Dictionary = _json(ENERGY_PATH)
	_grid = EnergyGrid.from_dict(energy) if not energy.is_empty() else null


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
		cells[LevelParser.cell_key(entry["cell"])] = true
	for key: Variant in _meta.get("entities", {}):
		assert_true(cells.has(String(key)), "chave '%s' sem entidade" % key)


func test_item_ids_are_unique_across_the_campaign() -> void:
	var seen: Dictionary = {}
	for path: String in CAMPAIGN_METAS:
		var raw: Dictionary = _json(path)
		for key: Variant in raw.get("entities", {}):
			var params: Dictionary = (raw["entities"] as Dictionary)[key]
			var id: String = String(params.get("id", ""))
			if id.is_empty():
				continue
			assert_false(seen.has(id), "id '%s' repetido na campanha" % id)
			seen[id] = true


func test_everything_is_reachable_with_the_docks_abilities() -> void:
	var result: Dictionary = LevelReachability.analyze(_text, _meta)
	for item: Dictionary in LevelReachability.unreachable_pickups(result):
		fail("coletável inalcançável: %s" % LevelReachability.describe(item))
	for item: Dictionary in LevelReachability.unreachable_interactables(result):
		fail("interativo inalcançável: %s" % LevelReachability.describe(item))
	var reach: Dictionary = _meta.get("reach", {})
	assert_true(bool(reach.get("double_jump", false)), "pulo duplo")


func test_the_pit_needs_the_walkway() -> void:
	var walkway: Vector2i = _find(WALKWAY_ID)
	var lines: PackedStringArray = _text.split("\n")
	var row: String = lines[walkway.y]
	lines[walkway.y] = row.substr(0, walkway.x) + " " + row.substr(walkway.x + 1)
	var without: Dictionary = LevelReachability.analyze("\n".join(lines), _meta)
	assert_false(
		LevelReachability.can_interact_with(without, _find("mem_console_b")),
		"sem a passarela o console B fica do outro lado do vão"
	)
	var with_walkway: Dictionary = LevelReachability.analyze(_text, _meta)
	assert_true(
		LevelReachability.can_interact_with(with_walkway, _find("mem_console_b")),
		"com a passarela se chega ao console B"
	)


func test_terminal_is_mute_and_starts_unsolved() -> void:
	assert_not_null(_grid, "terminal carregou")
	if _grid == null:
		return
	assert_true(_grid.validate().is_empty(), "válido: %s" % ", ".join(_grid.validate()))
	assert_eq(_grid.budget, 3, "três unidades")
	assert_eq(_grid.system_ids().size(), 5, "cinco sistemas")
	assert_false(_grid.verbose, "fora do tutorial o terminal não explica")
	assert_eq(_grid.initial_state(), [&"party_lights", &"luto"] as Array[StringName], "inicial")
	assert_false(_grid.goal_met(), "não começa resolvido")
	assert_eq(_grid.goal_systems(), [&"archive_door"] as Array[StringName], "meta: arquivo")


func test_naive_routing_loses_the_cable_it_needs() -> void:
	if _grid == null:
		return
	_grid.reset_to_initial()
	var after: Array[StringName] = _session(
		[&"luto", &"party_lights"], [&"hall_door", &"walkway"]
	)
	assert_true(after.has(&"hall_door"), "a porta fica")
	assert_false(after.has(&"walkway"), "a passarela, ligada por último, foi roubada")
	_grid.reset_to_initial()
	after = _session([&"party_lights"], [&"walkway", &"hall_door"])
	assert_false(after.has(&"hall_door"), "ligando a porta por último, a porta cai")


func test_feeding_the_firewall_a_decoy_solves_both_consoles() -> void:
	if _grid == null:
		return
	_grid.reset_to_initial()
	var at_a: Array[StringName] = _session(
		[&"luto", &"party_lights"], [&"hall_door", &"walkway", &"party_lights"]
	)
	assert_true(at_a.has(&"hall_door") and at_a.has(&"walkway"), "A: porta e passarela ficam")
	assert_true(at_a.has(&"luto"), "o firewall ficou com a unidade das luzes")
	var at_b: Array[StringName] = _session(
		[&"walkway", &"luto"], [&"archive_door", &"party_lights"]
	)
	assert_true(at_b.has(&"archive_door"), "B: a porta do arquivo fica aberta")
	assert_true(_grid.goal_met(), "meta cumprida")
	_grid.set_state(at_a)
	var naive_b: Array[StringName] = _session([&"walkway"], [&"archive_door"])
	assert_false(naive_b.has(&"archive_door"), "B ingênuo: a porta do arquivo cai")


func test_consoles_sit_on_each_side_of_the_pit() -> void:
	var pit: Rect2i = _void_rect()
	var console_a: Vector2i = _find("mem_console_a")
	var console_b: Vector2i = _find("mem_console_b")
	var hall: Vector2i = _find("mem_door_hall")
	var archive: Vector2i = _find("mem_door_archive")
	assert_true(console_a.x < hall.x and hall.x < pit.position.x, "A antes da porta do salão")
	assert_true(pit.end.x <= console_b.x, "B depois do vão")
	assert_true(console_b.x < archive.x, "B antes do arquivo")
	assert_true(_find("data_mem_01").x >= pit.position.x, "o Dado fica sobre o vão")
	assert_true(_find("data_mem_01").x < pit.end.x, "o Dado fica sobre o vão")


func test_protocol_block_fits_the_map() -> void:
	var protocol: Dictionary = _meta.get("protocol", {})
	assert_eq(String(protocol.get("terminal", "")), "memory_core", "terminal")
	var luto := StringName(String(protocol.get("luto_system", "")))
	assert_true(_grid != null and _grid.has_system(luto), "sistema do luto")
	var bounds := Rect2i(0, 0, MAP_WIDTH, MAP_HEIGHT)
	for key: String in ["ascent", "firewall", "recall"]:
		var block: Dictionary = protocol.get(key, {})
		assert_false(block.is_empty(), "bloco %s" % key)
		for rect_key: String in ["region", "trigger"]:
			var rect: Rect2i = _rect(block.get(rect_key, []))
			assert_true(bounds.encloses(rect), "%s.%s dentro do mapa" % [key, rect_key])
		var dock: String = String(block.get("dock", ""))
		if not dock.is_empty():
			assert_ne(_find(dock), Vector2i(-1, -1), "%s: doca %s existe" % [key, dock])
	var recall: Dictionary = protocol.get("recall", {})
	var line_start: int = int(recall.get("line_start", 0))
	var line_end: int = int(recall.get("line_end", 0))
	assert_true(line_start > line_end, "o log se lê andando para a esquerda")
	assert_true(_find(NODE_ID).x < line_end, "o Nó fica depois da última linha")
	assert_eq(String(recall.get("log", "")), FINAL_LOG, "log final")
	var ascent: Rect2i = _rect((protocol.get("ascent", {}) as Dictionary).get("region", []))
	assert_false(ascent.has_point(_find("mem_exit_core")), "a saída nunca some")
	assert_false(ascent.has_point(_find("mem_dock_01")), "a doca da entrada nunca some")


func test_logs_and_milestone_dialogue() -> void:
	var logs: Dictionary = {}
	for value: Variant in _json(LOGS_PATH).get("logs", []) as Array:
		logs[String((value as Dictionary).get("id", ""))] = value
	assert_eq(logs.size(), 2, "dois logs no setor")
	for id: String in [FINAL_LOG, PARTY_LOG]:
		assert_true(logs.has(id), "log %s" % id)
		assert_eq(String((logs.get(id, {}) as Dictionary).get("sector", "")), "memory", "setor")
	var final_log: Dictionary = logs.get(FINAL_LOG, {})
	assert_eq((final_log.get("lines", []) as Array).size(), 12, "o log final tem 12 linhas")
	var sequences: Dictionary = _json(DIALOGUE_PATH).get("sequences", {})
	assert_eq(sequences.keys().size(), MILESTONES.size(), "só falas de marco")
	for id: String in MILESTONES:
		assert_true(sequences.has(id), "fala %s" % id)
	assert_eq((_meta.get("triggers", []) as Array).size(), 0, "nenhum gatilho de fala")
	var objective := StringName(String(_meta.get("objective", "")))
	assert_true(Objectives.has(objective, Objectives.load_all()), "objetivo da fase")


func test_scene_wires_the_sector_and_the_provisional_end() -> void:
	var state: SceneState = (load(SCENE_PATH) as PackedScene).get_state()
	var narrative: Dictionary = _node_properties(state, "Narrative")
	assert_eq(String(narrative.get("sector_id", "")), "memory", "setor")
	assert_eq(String(narrative.get("next_scene", "")), CORE_HUB_SCENE, "volta ao Núcleo")
	assert_eq(String(narrative.get("demo_end_until", "")), REACTOR_SCENE, "fim provisório")
	assert_eq(String(narrative.get("restored_dialogue", "")), "mem_restored", "fala final")
	assert_true(_has_node(state, "Protocol"), "protocolo na cena")


func test_the_hub_links_the_memory_and_brightens() -> void:
	var hub: Dictionary = _json(CORE_HUB_META)
	var entities: Dictionary = hub.get("entities", {})
	assert_true(entities.has("146,14"), "saída viva no hub")
	assert_false((hub.get("reserved_exits", {}) as Dictionary).has("146,14"), "vaga consumida")
	var lines: PackedStringArray = FileAccess.get_file_as_string(CORE_HUB_MAP).split("\n")
	assert_eq(lines[14].substr(146, 1), "E", "portal desenhado")
	var revisits: Array = hub.get("revisit", [])
	var last: Dictionary = revisits[revisits.size() - 1]
	assert_eq(String(last.get("after_sector", "")), "memory", "a Memória é a última revisita")
	assert_eq(String(last.get("objective", "")), "obj_core_reactor", "objetivo do Reator")
	var before: Dictionary = revisits[revisits.size() - 2]
	var last_luma: float = _luma(Color(String(last.get("ambient_color", ""))))
	var before_luma: float = _luma(Color(String(before.get("ambient_color", ""))))
	assert_true(last_luma > before_luma, "o hub clareia de novo")


func _session(turn_off: Array[StringName], turn_on: Array[StringName]) -> Array[StringName]:
	var logic := FirewallLogic.create(&"luto", Balance.FIREWALL_SWAP_DELAY)
	logic.begin_session()
	for system_id: StringName in turn_off:
		for changed: StringName in _grid.power_off(system_id):
			logic.note_change(changed, false)
	for system_id: StringName in turn_on:
		for changed: StringName in _grid.power_on(system_id):
			logic.note_change(changed, true)
	var target: StringName = logic.end_session()
	for system_id: StringName in FirewallLogic.swap_plan(_grid, target, &"luto"):
		if _grid.is_powered(system_id):
			_grid.power_off(system_id)
		else:
			_grid.power_on(system_id)
	return _grid.get_state()


func _void_rect() -> Rect2i:
	var protocol: Dictionary = _meta.get("protocol", {})
	var voids: Array = (protocol.get("firewall", {}) as Dictionary).get("void", [])
	return _rect(voids[0]) if not voids.is_empty() else Rect2i()


func _rect(value: Variant) -> Rect2i:
	if not (value is Array) or (value as Array).size() < 4:
		return Rect2i()
	var raw: Array = value
	return Rect2i(int(raw[0]), int(raw[1]), int(raw[2]), int(raw[3]))


func _find(entity_id: String) -> Vector2i:
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if String(params.get("id", "")) == entity_id:
			var parts: PackedStringArray = String(key).split(",")
			return Vector2i(int(parts[0]), int(parts[1]))
	return Vector2i(-1, -1)


func _count(symbol: String) -> int:
	return _text.count(symbol)


func _json(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}


func _luma(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b


func _node_properties(state: SceneState, node_name: String) -> Dictionary:
	var result: Dictionary = {}
	for index: int in range(state.get_node_count()):
		if String(state.get_node_name(index)) != node_name:
			continue
		for property: int in range(state.get_node_property_count(index)):
			result[String(state.get_node_property_name(index, property))] = (
				state.get_node_property_value(index, property)
			)
	return result


func _has_node(state: SceneState, node_name: String) -> bool:
	for index: int in range(state.get_node_count()):
		if String(state.get_node_name(index)) == node_name:
			return true
	return false
