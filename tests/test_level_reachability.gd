extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const CAMPAIGN_LEVELS: Array[String] = ["core_hub", "greenhouse"]
const SANDBOX_LEVELS: Array[String] = ["test_room"]
const GOAL_SYMBOL: String = "c"
const OLD_CHIMNEY_COLUMN: int = 43
const OLD_CHIMNEY_ROWS: Array[int] = [12, 13, 14, 15]
const SECTOR_NODE_CELL: Vector2i = Vector2i(7, 11)

const STEP_TOO_TALL: Array[String] = [
	"############",
	"#          #",
	"#       c  #",
	"#     ######",
	"#     ######",
	"# P   ######",
	"############",
]
const STEP_CLIMBABLE: Array[String] = [
	"############",
	"#          #",
	"#          #",
	"#       c  #",
	"#     ######",
	"# P   ######",
	"############",
]
const PLANT_WITHOUT_LEDGE: Array[String] = [
	"############",
	"#          #",
	"#          #",
	"#          #",
	"#        c #",
	"#      #####",
	"#          #",
	"#          #",
	"#P  g      #",
	"############",
]
const PLANT_WITH_LEDGE: Array[String] = [
	"############",
	"#          #",
	"#          #",
	"#          #",
	"#        c #",
	"#      #####",
	"#          #",
	"#==        #",
	"#P  g      #",
	"############",
]
const CHIMNEY_ONE_TILE: Array[String] = [
	"############",
	"#         M#",
	"#  c      M#",
	"#         M#",
	"######### M#",
	"######### M#",
	"#         M#",
	"# P       M#",
	"############",
]
const CHIMNEY_TWO_TILES: Array[String] = [
	"############",
	"#         M#",
	"#  c      M#",
	"#         M#",
	"########  M#",
	"########  M#",
	"#         M#",
	"# P       M#",
	"############",
]
const STACK_ONE_COLUMN: Array[String] = [
	"############",
	"#          #",
	"#         c#",
	"#    ======#",
	"#          #",
	"# ====     #",
	"#P         #",
	"############",
]
const STACK_TWO_COLUMNS: Array[String] = [
	"############",
	"#          #",
	"#         c#",
	"#    ======#",
	"#          #",
	"# =====    #",
	"#P         #",
	"############",
]


var _analyzed: Dictionary = {}

func test_core_hub_exit_terminal_and_logs_are_reachable() -> void:
	_assert_interactables_reachable("core_hub")


func test_greenhouse_sector_node_terminals_and_logs_are_reachable() -> void:
	var result: Dictionary = _analyze_level("greenhouse")
	_assert_interactables_reachable("greenhouse", result)
	var symbols: PackedStringArray = []
	for entry: Dictionary in LevelReachability.required_interactables(result):
		symbols.append(String(entry.get("symbol", "")))
	assert_true(symbols.has("o"), "greenhouse: o Nó do Setor não entrou na lista de alvos")
	assert_true(symbols.has("T"), "greenhouse: nenhum console entrou na lista de alvos")
	assert_true(symbols.has("L"), "greenhouse: nenhum log entrou na lista de alvos")


func test_campaign_levels_have_no_unreachable_collectible() -> void:
	for level_id: String in CAMPAIGN_LEVELS:
		_assert_pickups_reachable(level_id, _analyze_level(level_id))


func test_every_level_file_has_no_unreachable_collectible() -> void:
	for file_name: String in DirAccess.get_files_at(LEVELS_DIR):
		if not file_name.ends_with(".txt"):
			continue
		var level_id: String = file_name.get_basename()
		if SANDBOX_LEVELS.has(level_id):
			continue
		_assert_pickups_reachable(level_id, _analyze_level(level_id))


func test_every_level_file_has_reachable_interactables() -> void:
	for file_name: String in DirAccess.get_files_at(LEVELS_DIR):
		if not file_name.ends_with(".txt"):
			continue
		var level_id: String = file_name.get_basename()
		if SANDBOX_LEVELS.has(level_id):
			continue
		_assert_interactables_reachable(level_id)


func test_the_sandbox_exemption_still_names_a_real_level() -> void:
	for level_id: String in SANDBOX_LEVELS:
		assert_true(
			FileAccess.file_exists(LEVELS_DIR + level_id + ".txt"),
			"SANDBOX_LEVELS cita '%s', que não existe mais: remova da lista" % level_id
		)


func test_a_three_tile_step_is_out_of_reach() -> void:
	var result: Dictionary = _analyze_fixture(STEP_TOO_TALL)
	assert_false(_goal_reached(result), "degrau de 3 tiles (48 px) não pode ser alcançado")
	assert_false(LevelReachability.can_stand_at(result, Vector2i(7, 2)), "topo do degrau de 3")


func test_a_two_tile_step_is_reachable() -> void:
	var result: Dictionary = _analyze_fixture(STEP_CLIMBABLE)
	assert_true(_goal_reached(result), "degrau de 2 tiles (32 px) tem de ser alcançável")
	assert_true(LevelReachability.can_stand_at(result, Vector2i(7, 3)), "topo do degrau de 2")


func test_a_plant_without_boarding_ledge_is_out_of_reach() -> void:
	var result: Dictionary = _analyze_fixture(PLANT_WITHOUT_LEDGE)
	assert_false(_goal_reached(result), "trepadeira sem patamar levou ao alvo")
	assert_false(LevelReachability.can_stand_at(result, Vector2i(4, 4)), "topo da trepadeira")
	var missing: Array[Dictionary] = LevelReachability.unreachable_pickups(result)
	assert_eq(missing.size(), 1, "o alvo deveria ser listado como inalcançável")
	if missing.size() == 1:
		var reason: String = String(missing[0].get("reason", ""))
		assert_true(reason.contains("trepadeira"), "motivo deveria citar a trepadeira: " + reason)


func test_a_plant_with_boarding_ledge_is_reachable() -> void:
	var result: Dictionary = _analyze_fixture(PLANT_WITH_LEDGE)
	assert_true(LevelReachability.can_stand_at(result, Vector2i(4, 4)), "topo da trepadeira")
	assert_true(_goal_reached(result), "trepadeira com patamar tem de levar ao alvo")


func test_a_one_tile_claw_chimney_jams() -> void:
	var result: Dictionary = _analyze_fixture(CHIMNEY_ONE_TILE)
	assert_false(_goal_reached(result), "chaminé de 1 tile não pode ser escalada")
	var jams: Array = result.get("jams", [])
	assert_false(jams.is_empty(), "a trava da chaminé deveria ser registrada")
	var missing: Array[Dictionary] = LevelReachability.unreachable_pickups(result)
	if missing.size() == 1:
		var reason: String = String(missing[0].get("reason", ""))
		assert_true(reason.contains("chaminé"), "motivo deveria citar a chaminé: " + reason)


func test_a_two_tile_claw_chimney_is_climbable() -> void:
	var result: Dictionary = _analyze_fixture(CHIMNEY_TWO_TILES)
	assert_true(_goal_reached(result), "chaminé de 2 tiles tem de ser escalável")
	assert_true(LevelReachability.can_stand_at(result, Vector2i(3, 3)), "andar de cima")


func test_stacked_thin_platforms_with_one_column_overlap_are_out_of_reach() -> void:
	var result: Dictionary = _analyze_fixture(STACK_ONE_COLUMN)
	assert_true(LevelReachability.can_stand_at(result, Vector2i(3, 4)), "primeira plataforma")
	assert_false(LevelReachability.can_stand_at(result, Vector2i(8, 2)), "segunda plataforma")
	assert_false(_goal_reached(result), "sobreposição de 1 coluna não pode bastar")
	var missing: Array[Dictionary] = LevelReachability.unreachable_pickups(result)
	if missing.size() == 1:
		var reason: String = String(missing[0].get("reason", ""))
		assert_true(
			reason.contains("sobreposição"), "motivo deveria citar a sobreposição: " + reason
		)


func test_stacked_thin_platforms_with_two_column_overlap_are_reachable() -> void:
	var result: Dictionary = _analyze_fixture(STACK_TWO_COLUMNS)
	assert_true(LevelReachability.can_stand_at(result, Vector2i(8, 2)), "segunda plataforma")
	assert_true(_goal_reached(result), "sobreposição de 2 colunas tem de bastar")


func test_greenhouse_with_the_old_one_tile_chimney_loses_the_node_room() -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(
		LEVELS_DIR + "greenhouse.txt"
	).split("\n")
	for row: int in OLD_CHIMNEY_ROWS:
		lines[row] = lines[row].substr(0, OLD_CHIMNEY_COLUMN) + "#" + lines[row].substr(
			OLD_CHIMNEY_COLUMN + 1
		)
	var meta: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(LEVELS_DIR + "greenhouse.json")
	)
	var result: Dictionary = LevelReachability.analyze("\n".join(lines), meta)
	var missing: Array[Dictionary] = LevelReachability.unreachable_interactables(result)
	var node_lost: bool = false
	for item: Dictionary in missing:
		node_lost = node_lost or item.get("cell", Vector2i.ZERO) == SECTOR_NODE_CELL
	assert_true(node_lost, "com a chaminé de 1 tile o Nó do Setor deveria ficar inalcançável")
	assert_false((result.get("jams", []) as Array).is_empty(), "a trava deveria ser registrada")


func test_the_profile_comes_from_the_scenes() -> void:
	var profile: Dictionary = LevelReachability.default_profile()
	assert_almost_eq(float(profile.get("body_half_width", 0.0)), 7.0, 0.001, "meia largura do MU-7")
	assert_almost_eq(float(profile.get("body_height", 0.0)), 24.0, 0.001, "altura do MU-7")
	assert_almost_eq(float(profile.get("plant_top_offset", 0.0)), -64.0, 0.001, "topo da planta")
	assert_almost_eq(float(profile.get("claw_reach", 0.0)), 10.0, 0.001, "alcance das garras")


func _assert_interactables_reachable(level_id: String, result: Dictionary = {}) -> void:
	var analyzed: Dictionary = result if not result.is_empty() else _analyze_level(level_id)
	for item: Dictionary in LevelReachability.unreachable_interactables(analyzed):
		fail("%s: interação inalcançável %s" % [level_id, LevelReachability.describe(item)])


func _assert_pickups_reachable(level_id: String, result: Dictionary) -> void:
	for item: Dictionary in LevelReachability.unreachable_pickups(result):
		fail("%s: coletável inalcançável %s" % [level_id, LevelReachability.describe(item)])


func _analyze_level(level_id: String) -> Dictionary:
	if not _analyzed.has(level_id):
		_analyzed[level_id] = LevelReachability.analyze_file(LEVELS_DIR + level_id + ".txt")
	return _analyzed[level_id]


func _analyze_fixture(lines: Array[String]) -> Dictionary:
	return LevelReachability.analyze("\n".join(PackedStringArray(lines)))


func _goal_reached(result: Dictionary) -> bool:
	var goals: Array[Dictionary] = LevelReachability.entities(result, GOAL_SYMBOL)
	if goals.size() != 1:
		fail("fixture deveria ter exatamente um alvo '%s'" % GOAL_SYMBOL)
		return false
	return LevelReachability.is_touched(result, goals[0].get("cell", Vector2i.ZERO))
