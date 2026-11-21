extends TestCase

const MAP_PATH: String = "res://data/levels/reactor_core.txt"
const META_PATH: String = "res://data/levels/reactor_core.json"
const ENERGY_PATH: String = "res://data/energy/reactor_core.json"
const SCENE_PATH: String = "res://scenes/levels/reactor_core.tscn"
const CORE_HUB_META: String = "res://data/levels/core_hub.json"
const TOWER_SCENE: String = "res://scenes/enemies/cx2_armored.tscn"
const COUPLER_SCENE: String = "res://scenes/world/root_coupler.tscn"
const PLATFORM_SCENE: String = "res://scenes/world/thermal_platform.tscn"
const TERMINAL_ID: StringName = &"reactor_core"
const EXPECTED_COUNTS: Dictionary = {
	"E": 1, "T": 2, "D": 2, "L": 1, "l": 0, "r": 1, "A": 3, "X": 3, "m": 2, "v": 2, "z": 11,
	"C": 0, "B": 0,
}
const ALL_ABILITIES: Array[StringName] = [
	&"dash", &"beam", &"magnetic_claws", &"heat_sink", &"heated_core", &"thruster",
	&"root_access",
]
const COUPLERS: Dictionary = {
	"rc_coupler_01": &"line_1", "rc_coupler_02": &"line_2", "rc_coupler_03": &"line_3",
}
const ARENA_DOCK: String = "rc_dock_02"
const DASH_LANDING: Vector2i = Vector2i(28, 44)
const ARENA_SPAWN: Vector2i = Vector2i(38, 31)
const LINES: Array[StringName] = [&"line_1", &"line_2", &"line_3"]

var _text: String = ""
var _parsed: Dictionary = {}
var _meta: Dictionary = {}


func before_each() -> void:
	_text = FileAccess.get_file_as_string(MAP_PATH)
	_parsed = LevelParser.parse(_text, LevelBuilder.entity_chars())
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(META_PATH))
	_meta = raw if raw is Dictionary else {}


func test_map_parses_and_counts_match_the_paper() -> void:
	var errors: PackedStringArray = _parsed.get("errors", [])
	assert_true(errors.is_empty(), "erros do parser: %s" % ", ".join(errors))
	for symbol: String in EXPECTED_COUNTS:
		assert_eq(_count(symbol), int(EXPECTED_COUNTS[symbol]), "quantidade de '%s'" % symbol)
	assert_true(ResourceLoader.exists(SCENE_PATH), "cena da fase existe")


func test_entry_follows_the_round_trip_pattern() -> void:
	var exit: Dictionary = _entity("rc_exit_core")
	assert_eq(String(exit.get("target", "")), "res://scenes/levels/core_hub.tscn", "volta ao hub")
	assert_eq(String(exit.get("sector", "")), "core", "setor do hub")
	var exit_cell: Vector2i = _cell("rc_exit_core")
	var spawn: Vector2i = _parsed.get("spawn", Vector2i.ZERO)
	var dock: Vector2i = _cell("rc_dock_01")
	assert_eq(spawn.y, exit_cell.y, "P no mesmo piso do portal")
	assert_true(absi(spawn.x - exit_cell.x) <= 4, "P junto do portal")
	assert_true(absi(dock.x - exit_cell.x) >= 3, "doca a 3+ colunas do portal")
	var revisit: Array = _meta.get("revisit", [])
	assert_false(revisit.is_empty(), "bloco revisit")
	var hub: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CORE_HUB_META))
	var hub_exit: Dictionary = (hub["entities"] as Dictionary).get("146,5", {})
	assert_eq(String(hub_exit.get("target", "")), "res://scenes/levels/reactor_core.tscn", "hub")
	assert_false((hub.get("reserved_exits", {}) as Dictionary).has("146,5"), "vaga consumida")


func test_boss_pieces_use_their_own_scenes() -> void:
	for id: String in ["rc_tower_01", "rc_tower_02", "rc_tower_03"]:
		var tower: Dictionary = _entity(id)
		assert_eq(String(tower.get("scene", "")), TOWER_SCENE, "%s é blindada" % id)
		assert_eq(String(tower.get("system_id", "x")), "", "%s fora do terminal" % id)
		assert_eq(String(tower.get("group", "")), "argos_tower", "%s no grupo das torres" % id)
	for id: String in COUPLERS:
		var coupler: Dictionary = _entity(id)
		assert_eq(String(coupler.get("scene", "")), COUPLER_SCENE, "%s é acoplador Root" % id)
		assert_eq(StringName(coupler.get("system_id", "")), COUPLERS[id], "%s na sua linha" % id)
	for id: String in ["rc_lift_01", "rc_lift_02"]:
		assert_eq(String(_entity(id).get("scene", "")), PLATFORM_SCENE, "%s é térmica" % id)
	var argos: Dictionary = _meta.get("argos", {})
	assert_eq(String(argos.get("terminal", "")), String(TERMINAL_ID), "terminal da arena")
	assert_eq((argos.get("arena", []) as Array).size(), 4, "retângulo da arena")
	assert_eq((argos.get("core", []) as Array).size(), 2, "posição do núcleo")


func test_everything_is_reachable_with_every_ability() -> void:
	var result: Dictionary = _analyze(ALL_ABILITIES)
	for item: Dictionary in LevelReachability.unreachable_pickups(result):
		fail("coletável: %s" % LevelReachability.describe(item))
	for item: Dictionary in LevelReachability.unreachable_interactables(result):
		fail("interativo: %s" % LevelReachability.describe(item))
	for id: String in COUPLERS:
		assert_true(LevelReachability.can_interact_with(result, _cell(id)), "%s alcançável" % id)


func test_claws_double_jump_and_dash_guard_the_arena() -> void:
	for missing: StringName in [&"magnetic_claws", &"thruster"]:
		var abilities: Array[StringName] = ALL_ABILITIES.duplicate()
		abilities.erase(missing)
		var result: Dictionary = _analyze(abilities)
		assert_false(
			LevelReachability.can_interact_with(result, _cell(ARENA_DOCK)),
			"sem %s não se chega à arena" % missing
		)
	var no_dash: Dictionary = LevelReachability.profile_with_abilities(ALL_ABILITIES)
	no_dash["dash_enabled"] = false
	var dashless: Dictionary = LevelReachability.analyze(_text, _meta, no_dash)
	assert_false(
		LevelReachability.can_stand_at(dashless, DASH_LANDING), "sem dash o vão não se cruza"
	)
	var full: Dictionary = _analyze(ALL_ABILITIES)
	assert_true(LevelReachability.can_stand_at(full, DASH_LANDING), "com dash cruza")


func test_claws_are_needed_for_the_high_coupler() -> void:
	var full: Dictionary = _analyze(ALL_ABILITIES)
	var high: Vector2i = _cell("rc_coupler_03")
	assert_true(LevelReachability.can_stand_at(full, high), "acoplador do alto")
	assert_true(LevelReachability.can_stand_at(full, _cell("rc_coupler_02")), "acoplador oeste")
	var climbing: Dictionary = LevelReachability.analyze(
		_arena_only_text(), _meta, _profile_without(&"magnetic_claws")
	)
	assert_false(LevelReachability.can_stand_at(climbing, high), "alto só com garras")
	assert_true(
		LevelReachability.can_stand_at(climbing, _cell("rc_coupler_01")), "o do piso não precisa"
	)


func test_the_high_data_sits_beyond_a_double_jump_from_the_ledge() -> void:
	var data: Vector2i = _cell("data_rc_01")
	var ledge: Vector2i = _cell("rc_coupler_03")
	assert_true(ledge.y - data.y >= 3, "o dado fica 3+ tiles acima do acoplador do alto")
	var result: Dictionary = _analyze(ALL_ABILITIES)
	assert_true(LevelReachability.is_touched(result, data), "dado alcançável")


func test_energy_needs_a_trade_or_the_root_overload() -> void:
	var grid: EnergyGrid = _grid()
	assert_true(grid.validate().is_empty(), "terminal válido: %s" % ", ".join(grid.validate()))
	assert_false(grid.has_system(&"argos"), "torres e piso não estão no terminal")
	assert_true(grid.is_powered(&"coolant"), "refrigeração nasce ligada")
	assert_false(grid.verbose, "terminal mudo")
	for line: StringName in LINES:
		assert_false(grid.is_powered(line), "%s nasce apagada" % line)
	grid.power_off(&"coolant")
	grid.power_on(&"line_1")
	grid.power_on(&"line_2")
	assert_eq(grid.can_power(&"line_3"), EnergyGrid.Result.NO_BUDGET, "três linhas não cabem")
	assert_true(grid.start_overload(Balance.ROOT_OVERLOAD_UNITS, Balance.ROOT_OVERLOAD_TIME), "")
	assert_eq(grid.can_power(&"line_3"), EnergyGrid.Result.OK, "com a sobrecarga cabem")
	grid.power_on(&"line_3")
	assert_true(grid.goal_met(), "as três vivas ao mesmo tempo")
	var shed: Array[StringName] = grid.end_overload()
	assert_eq(shed, [&"line_3"] as Array[StringName], "acaba a sobrecarga, cai a última")


func test_the_trade_route_feeds_every_coupler() -> void:
	var grid: EnergyGrid = _grid()
	var fed: Dictionary = {}
	for step: Array in [[&"coolant", &"line_2"], [&"line_1"], [&"line_2", &"line_3"]]:
		for system_id: StringName in step:
			grid.toggle(system_id)
		for line: StringName in LINES:
			if grid.is_powered(line):
				fed[line] = true
		assert_true(grid.used() <= grid.budget, "nunca passa do orçamento")
	assert_eq(fed.size(), 3, "as três linhas foram alimentadas em algum momento")


func _analyze(abilities: Array) -> Dictionary:
	return LevelReachability.analyze_with_abilities(_text, _meta, abilities)


func _profile_without(ability: StringName) -> Dictionary:
	var abilities: Array[StringName] = ALL_ABILITIES.duplicate()
	abilities.erase(ability)
	return LevelReachability.profile_with_abilities(abilities)


func _arena_only_text() -> String:
	var lines: PackedStringArray = _text.strip_edges(false, true).split("\n")
	var rows: Array[String] = []
	for index: int in range(lines.size()):
		var line: String = lines[index].replace("P", " ")
		if index == ARENA_SPAWN.y:
			line = line.substr(0, ARENA_SPAWN.x) + "P" + line.substr(ARENA_SPAWN.x + 1)
		rows.append(line)
	return "\n".join(rows)


func _grid() -> EnergyGrid:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	return EnergyGrid.from_dict(raw if raw is Dictionary else {})


func _entity(id: String) -> Dictionary:
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if String(params.get("id", "")) == id:
			return params
	return {}


func _cell(id: String) -> Vector2i:
	for key: Variant in _meta.get("entities", {}):
		var params: Dictionary = (_meta["entities"] as Dictionary)[key]
		if String(params.get("id", "")) == id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func _count(symbol: String) -> int:
	var total: int = 0
	for entry: Dictionary in _parsed.get("entities", []) as Array:
		if String(entry.get("symbol", "")) == symbol:
			total += 1
	return total
