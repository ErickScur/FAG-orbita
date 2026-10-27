extends TestCase

const SPORE_SCENE: String = "res://scenes/enemies/spore_swarm.tscn"
const STEAM_SCENE: String = "res://scenes/world/steam_vent.tscn"
const COLD_SCENE: String = "res://scenes/world/cold_island.tscn"
const HEAT_SCENE: String = "res://scenes/world/heat_zone.tscn"
const TERMINAL: StringName = &"lab_probe"
const GRID: Dictionary = {
	"id": "lab_probe",
	"budget": 2,
	"initial": ["cooling"],
	"systems": [
		{
			"id": "cooling",
			"name": "REFRIGERAÇÃO",
			"cost": 1,
			"effects": [{"target": "group:probe_spores", "action": "invert"}],
		},
		{
			"id": "relief",
			"name": "ALÍVIO",
			"cost": 1,
			"effects": [{"target": "group:probe_vents", "action": "invert"}],
		},
	],
}

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_inverted_spores_swell_when_cooling_turns_off() -> void:
	var spores: SporeSwarm = _add(SPORE_SCENE)
	spores.configure({"terminal_id": "lab_probe", "system_id": ""})
	spores.add_to_group(&"probe_spores")
	var network: EnergyNetwork = _network()
	assert_false(spores.is_heated(), "refrigeração ligada no carregamento: esporos pequenos")
	assert_almost_eq(spores.current_radius(), Balance.SPORE_RADIUS, 0.01, "raio pequeno no load")
	network.toggle(TERMINAL, &"cooling")
	assert_true(spores.is_heated(), "refrigeração desligada: esporos incham")


func test_relief_stops_the_steam_vents() -> void:
	var vent: SteamVent = _add(STEAM_SCENE)
	vent.add_to_group(&"probe_vents")
	var network: EnergyNetwork = _network()
	assert_true(vent.powered, "alívio desligado: jatos ciclando")
	network.toggle(TERMINAL, &"relief")
	assert_false(vent.powered, "alívio ligado: jatos param")
	assert_false(vent.is_jetting(), "jato parado")


func test_steam_cycle_matches_the_gdd() -> void:
	assert_eq(SteamVent.phase_at(0.0), SteamVent.Phase.JET, "começa soprando")
	assert_eq(SteamVent.phase_at(Balance.STEAM_ON_TIME - 0.01), SteamVent.Phase.JET, "3 s ligado")
	assert_eq(SteamVent.phase_at(Balance.STEAM_ON_TIME + 0.1), SteamVent.Phase.IDLE, "desligado")
	var period: float = Balance.STEAM_ON_TIME + Balance.STEAM_OFF_TIME
	var warn: float = period - Balance.STEAM_WARN_TIME * 0.5
	assert_eq(SteamVent.phase_at(warn), SteamVent.Phase.WARN, "aviso no fim do desligado")
	assert_eq(SteamVent.phase_at(period + 0.1), SteamVent.Phase.JET, "ciclo repete")


func test_steam_vent_hurts_only_while_jetting() -> void:
	var vent: SteamVent = _add(STEAM_SCENE)
	var jet: DamageArea = vent.get_node("Jet")
	assert_eq(jet.contact_damage, Balance.STEAM_DAMAGE, "dano do jato")
	assert_true(jet.knockback, "empurra")
	vent.configure({"phase": Balance.STEAM_ON_TIME + 0.5})
	assert_false(jet.hurts_on_contact(), "fora da fase de jato não machuca")
	vent.configure({"phase": 0.0})
	assert_true(jet.hurts_on_contact(), "jato machuca")
	vent.set_powered_silent(false)
	assert_false(jet.hurts_on_contact(), "desligado não machuca")


func test_cold_island_follows_its_system() -> void:
	var island: ColdIsland = _add(COLD_SCENE)
	island.configure({"rect": [4, 3], "terminal_id": "lab_probe", "system_id": "cooling"})
	assert_eq(island.size_tiles, Vector2i(4, 3), "retângulo lido do JSON")
	var network: EnergyNetwork = _network()
	assert_true(island.is_active(), "refrigeração ligada")
	network.toggle(TERMINAL, &"cooling")
	assert_false(island.is_active(), "refrigeração desligada: ilha some")
	assert_false((island.get_node("Frost") as CPUParticles2D).emitting, "geada some")


func test_zone_rect_starts_at_the_letter_tile() -> void:
	var zone: HeatZone = _add(HEAT_SCENE)
	zone.position = Vector2(40.0, 24.0)
	zone.configure({"rect": [5, 2], "kind": "furnace"})
	assert_true(zone.is_furnace(), "fornalha")
	var rect: Rect2 = zone.world_rect()
	assert_eq(rect.position, Vector2(32.0, 16.0), "canto superior esquerdo do tile da letra")
	assert_eq(rect.size, Vector2(80.0, 32.0), "5 x 2 tiles")
	var lights: int = 0
	for child: Node in zone.get_children():
		if child is PointLight2D:
			lights += 1
	assert_eq(lights, 1, "uma luz por zona, esticada")


func test_legend_knows_the_lab_letters() -> void:
	var scenes: Dictionary = {
		"X": "res://scenes/enemies/cx2.tscn",
		"h": HEAT_SCENE,
		"i": COLD_SCENE,
		"v": STEAM_SCENE,
	}
	for symbol: String in scenes:
		assert_true(LevelBuilder.LEGEND.has(symbol), "legenda tem '%s'" % symbol)
		var scene: String = String(LevelBuilder.LEGEND[symbol]["scene"])
		assert_eq(scene, scenes[symbol], "cena de '%s'" % symbol)
		assert_true(ResourceLoader.exists(scenes[symbol]), "cena existe: %s" % symbol)


func test_lab_letters_are_not_solid_for_reachability() -> void:
	var room: String = "\n".join([
		"##########",
		"#        #",
		"#  X  h  #",
		"#P  i  v #",
		"##########",
	])
	var parsed: Dictionary = LevelParser.parse(room, LevelBuilder.entity_chars())
	assert_true((parsed["errors"] as PackedStringArray).is_empty(), "letras reconhecidas")
	for cell: Vector2i in [Vector2i(3, 2), Vector2i(6, 2), Vector2i(4, 3), Vector2i(7, 3)]:
		assert_false((parsed["solids"] as Dictionary).has(cell), "letra não é sólida: %s" % cell)
	assert_false(LevelReachability.analyze(room).is_empty(), "alcançabilidade aceita as letras")


func test_heat_sink_has_a_chassis_label() -> void:
	var texts: Dictionary = HudModel.load_texts("res://data/ui/chassis_menu.json")
	assert_eq(
		HudModel.text_for(&"ability_heat_sink", texts), "DISSIPADOR TÉRMICO", "rótulo"
	)


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
