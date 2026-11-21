extends TestCase

const FLOOR_SCENE: String = "res://scenes/world/electric_floor.tscn"
const CHASSIS_TEXTS: String = "res://data/ui/chassis_menu.json"
const TERMINAL: StringName = &"floor_probe"
const GRID: Dictionary = {
	"id": "floor_probe",
	"budget": 1,
	"initial": ["grid"],
	"systems": [
		{"id": "grid", "name": "GRADE", "cost": 1, "effects": []},
		{"id": "other", "name": "OUTRO", "cost": 1, "effects": []},
	],
}

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_live_floor_burns_and_discharges() -> void:
	var tile: ElectricFloor = _add(FLOOR_SCENE)
	var surface: DamageArea = tile.get_node("Surface")
	assert_true(tile.is_live(), "nasce energizado")
	assert_true(surface.hurts_over_time(), "dano contínuo")
	assert_false(surface.hurts_on_contact(), "sem dano de toque")
	assert_almost_eq(surface.damage_per_second, Balance.ELECTRIC_FLOOR_DPS, 0.001, "8/s")
	assert_eq(surface.status_id, StatusEffects.DISCHARGE, "aplica DESCARGA")
	assert_almost_eq(surface.status_duration, Balance.DISCHARGE_TIME, 0.001, "3 s")
	assert_false(surface.dash_passable, "dash não atravessa o piso")
	assert_false(surface.knockback, "não empurra")
	assert_eq(surface.collision_layer, 16, "camada hazard")


func test_floor_is_solid_world() -> void:
	var tile: ElectricFloor = _add(FLOOR_SCENE)
	assert_eq(tile.collision_layer, 1, "é chão (world)")
	assert_true(tile.is_in_group(&"powered"), "grupo powered")


func test_unpowered_floor_is_inert_and_dark() -> void:
	var tile: ElectricFloor = _add(FLOOR_SCENE)
	tile.set_powered_silent(false)
	var surface: DamageArea = tile.get_node("Surface")
	assert_false(tile.is_live(), "desligado")
	assert_false(surface.hurts_over_time(), "não machuca")
	assert_false((tile.get_node("Sparks") as CPUParticles2D).emitting, "sem faísca")
	assert_false(tile.glow_enabled(), "sem luz")
	var sprite: Sprite2D = tile.get_node("Sprite2D")
	assert_eq(sprite.frame, ElectricFloor.ROW_OFF * ElectricFloor.FRAMES, "quadro apagado")


func test_terminal_switches_the_floor() -> void:
	var tile: ElectricFloor = _add(FLOOR_SCENE)
	tile.configure({"terminal_id": String(TERMINAL), "system_id": "grid"})
	var network: EnergyNetwork = _network()
	assert_true(tile.is_live(), "grade ligada no carregamento")
	network.toggle(TERMINAL, &"grid")
	assert_false(tile.is_live(), "desligar a grade apaga o piso")
	network.toggle(TERMINAL, &"other")
	assert_false(tile.is_live(), "a unidade foi para o outro sistema")
	network.toggle(TERMINAL, &"other")
	network.toggle(TERMINAL, &"grid")
	assert_true(tile.is_live(), "religa")


func test_notify_status_goes_through_game_state() -> void:
	GameState.clear_statuses()
	var tile: ElectricFloor = _add(FLOOR_SCENE)
	(tile.get_node("Surface") as DamageArea).notify_status()
	assert_true(GameState.has_status(StatusEffects.DISCHARGE), "estado do jogo recebe a DESCARGA")
	assert_true(GameState.statuses.blocks_abilities(), "bloqueia habilidades")
	GameState.clear_statuses()


func test_a_run_of_plates_shares_one_glow_per_segment() -> void:
	var tiles: Array[ElectricFloor] = []
	for index: int in range(9):
		var tile: ElectricFloor = _add(FLOOR_SCENE)
		tile.position = Vector2(float(index) * 16.0 + 8.0, 40.0)
		tiles.append(tile)
	for tile: ElectricFloor in tiles:
		tile._merge_glow()
	var lit: int = 0
	for tile: ElectricFloor in tiles:
		if tile.glow_enabled():
			lit += 1
	var expected: int = ceili(9.0 / float(ElectricFloor.GLOW_SEGMENT_TILES))
	assert_eq(lit, expected, "9 placas, uma luz por trecho")
	tiles[0].set_powered_silent(false)
	assert_false(tiles[0].glow_enabled(), "desligada apaga a luz do trecho")


func test_legend_letter_z_is_the_electric_floor() -> void:
	assert_true(LevelBuilder.LEGEND.has("z"), "legenda tem 'z'")
	var entry: Dictionary = LevelBuilder.LEGEND["z"]
	assert_eq(String(entry["scene"]), FLOOR_SCENE, "cena do piso")
	assert_eq(StringName(entry["anchor"]), &"center", "ocupa o tile")
	assert_true(bool(entry.get("solid", false)), "conta como chão")
	assert_true(ResourceLoader.exists(FLOOR_SCENE), "cena existe")


func test_floor_letter_is_solid_for_tiles_and_reachability() -> void:
	var room: String = "\n".join([
		"##########",
		"#        #",
		"#        #",
		"#P      T#",
		"###zzzz###",
	])
	var parsed: Dictionary = LevelParser.parse(room, LevelBuilder.entity_chars())
	assert_true((parsed["errors"] as PackedStringArray).is_empty(), "letra reconhecida")
	assert_false((parsed["solids"] as Dictionary).has(Vector2i(4, 4)), "parser vê entidade")
	var solids: Dictionary = LevelBuilder.solid_cells(parsed)
	for x: int in range(3, 7):
		assert_true(solids.has(Vector2i(x, 4)), "tile embaixo do piso é sólido: %d" % x)
	assert_eq(
		LevelBuilder.silhouette_loops(parsed["solids"]).size(), 1, "sem o piso a sala vaza"
	)
	assert_eq(LevelBuilder.silhouette_loops(solids).size(), 2, "com o piso a sala fecha")
	var report: Dictionary = LevelReachability.analyze(room)
	assert_false(report.is_empty(), "alcançabilidade aceita a letra")


func test_hazard_bench_level_parses() -> void:
	var text: String = FileAccess.get_file_as_string("res://data/levels/hazard_test.txt")
	var parsed: Dictionary = LevelParser.parse(text, LevelBuilder.entity_chars())
	assert_true((parsed["errors"] as PackedStringArray).is_empty(), "bancada sem erro")
	var floors: int = 0
	for entry: Dictionary in parsed["entities"] as Array:
		if String(entry["symbol"]) == "z":
			floors += 1
	assert_eq(floors, 4, "quatro placas de piso")


func test_chassis_names_every_status() -> void:
	var texts: Dictionary = HudModel.load_texts(CHASSIS_TEXTS)
	for status_id: StringName in StatusEffects.ORDER:
		var text: String = HudModel.text_for(StringName("status_" + String(status_id)), texts)
		assert_false(text.is_empty(), "legenda de %s" % status_id)
	assert_true(
		HudModel.text_for(&"status_discharge", texts).begins_with("DESCARGA"), "DESCARGA"
	)
	assert_true(
		HudModel.text_for(&"status_overload", texts).begins_with("SOBRECARGA"), "SOBRECARGA"
	)


func test_hud_has_an_icon_for_every_status() -> void:
	var seen: Dictionary = {}
	for status_id: StringName in StatusEffects.ORDER:
		assert_true(HudModel.STATUS_ICONS.has(status_id), "ícone de %s" % status_id)
		seen[HudModel.status_icon_index(status_id)] = true
	assert_eq(seen.size(), StatusEffects.ORDER.size(), "ícones distintos")


func _network() -> EnergyNetwork:
	var network := EnergyNetwork.new()
	_tree().root.add_child(network)
	_nodes.append(network)
	var grid: EnergyGrid = EnergyGrid.from_dict(GRID)
	network._grids[TERMINAL] = grid
	network._order.append(TERMINAL)
	network.apply_all(TERMINAL, true)
	return network


func _add(scene_path: String) -> Node:
	var node: Node = load(scene_path).instantiate()
	_tree().root.add_child(node)
	_nodes.append(node)
	return node


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree
