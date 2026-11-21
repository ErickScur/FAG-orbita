extends TestCase

const STUB_LEVEL: String = "res://tests/argos_stub_level.gd"
const COUPLER_SCENE: String = "res://scenes/world/root_coupler.tscn"
const TOWER_SCENE: String = "res://scenes/enemies/cx2_armored.tscn"
const PLATFORM_SCENE: String = "res://scenes/world/thermal_platform.tscn"
const HEAT_SCENE: String = "res://scenes/world/heat_zone.tscn"
const FLOOR_SCENE: String = "res://scenes/world/electric_floor.tscn"
const ENCOUNTER_SCRIPT: String = "res://scenes/bosses/argos_encounter.gd"
const LEVEL_SCENE: String = "res://scenes/levels/reactor_core.tscn"
const TERMINAL: StringName = &"reactor_core"
const ROOT: StringName = &"root_access"
const LINES: Array[StringName] = [&"line_1", &"line_2", &"line_3"]

var _nodes: Array[Node] = []
var _had_root: bool = false
var _saved_energy: Dictionary = {}


func before_each() -> void:
	_had_root = GameState.abilities.has(ROOT)
	_saved_energy = GameState.energy_states.duplicate(true)
	GameState.energy_states.erase(TERMINAL)


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	if not _had_root:
		GameState.abilities.erase(ROOT)
	GameState.energy_states = _saved_energy


func test_coupler_needs_its_line_and_root() -> void:
	GameState.abilities.erase(ROOT)
	var coupler: RootCoupler = _coupler(&"probe")
	assert_eq(coupler.panel().prompt_text, InteractionRules.text(RootCoupler.PROMPT_UNFED), "sem")
	assert_false(coupler.panel().is_actionable(), "sem linha o painel só informa")
	assert_false(coupler.begin_overload(null), "sem linha não sobrecarrega")
	coupler.set_powered_silent(true)
	assert_eq(coupler.panel().prompt_text, InteractionRules.text(RootCoupler.PROMPT_NO_ROOT), "R")
	assert_false(coupler.panel().is_actionable(), "sem Root o painel só informa")
	assert_false(coupler.can_overload(), "sem Root não sobrecarrega")
	GameState.abilities.append(ROOT)
	coupler.set_powered_silent(true)
	assert_eq(coupler.panel().prompt_text, InteractionRules.text(RootCoupler.PROMPT_READY), "ok")
	assert_true(coupler.panel().is_actionable(), "pronto para sobrecarregar")
	assert_true(coupler.can_overload(), "linha + Root")


func test_overload_charges_then_burns_and_survives_the_line() -> void:
	GameState.abilities.append(ROOT)
	var coupler: RootCoupler = _coupler(&"probe")
	coupler.set_powered_silent(true)
	var actor := Node2D.new()
	_track(actor)
	Engine.get_main_loop().root.add_child(actor)
	actor.global_position = coupler.global_position
	var burnt: Array[StringName] = []
	coupler.overloaded.connect(func(id: StringName) -> void: burnt.append(id))
	assert_true(coupler.begin_overload(actor), "começa a carregar")
	assert_true(coupler.is_charging(), "carregando")
	coupler._process(Balance.ARGOS_COUPLER_CHARGE_TIME * 0.5)
	assert_false(coupler.is_overloaded(), "ainda não")
	coupler._process(Balance.ARGOS_COUPLER_CHARGE_TIME)
	assert_true(coupler.is_overloaded(), "queimou")
	assert_eq(burnt, [&"probe"] as Array[StringName], "avisou uma vez")
	coupler.set_powered(false)
	assert_true(coupler.is_overloaded(), "sem a linha continua queimado")
	assert_eq(coupler.panel().prompt_text, InteractionRules.text(RootCoupler.PROMPT_DONE), "feito")
	assert_false(coupler.panel().enabled, "não interage mais")
	coupler.reset_overload()
	assert_false(coupler.is_overloaded(), "reset limpa")


func test_walking_away_or_losing_the_line_cancels_the_charge() -> void:
	GameState.abilities.append(ROOT)
	var coupler: RootCoupler = _coupler(&"probe")
	coupler.set_powered_silent(true)
	var actor := Node2D.new()
	_track(actor)
	Engine.get_main_loop().root.add_child(actor)
	actor.global_position = coupler.global_position
	coupler.begin_overload(actor)
	actor.global_position += Vector2(Balance.ARGOS_COUPLER_RANGE * 2.0, 0.0)
	coupler._process(0.1)
	assert_false(coupler.is_charging(), "afastar cancela")
	assert_false(coupler.is_overloaded(), "não queimou")
	actor.global_position = coupler.global_position
	coupler.begin_overload(actor)
	coupler.set_powered(false)
	assert_false(coupler.is_charging(), "perder a linha cancela")


func test_armored_tower_only_flinches() -> void:
	var tower: Cx2Armored = _add(TOWER_SCENE)
	tower.shutdown(Balance.BEAM_SHUTDOWN_TIME)
	assert_true(tower.is_shut_down(), "o feixe atordoa")
	assert_almost_eq(
		tower.shutdown_remaining(), Balance.ARGOS_TOWER_STUN_TIME, 0.001, "só 2,5 s"
	)
	tower.set_sweep_scale(1.5)
	assert_almost_eq(tower.sweep_speed(), Balance.CX2_SWEEP_SPEED * 1.5, 0.001, "acelera")
	assert_true(tower.is_in_group(&"argos_tower"), "grupo das torres")
	assert_true(tower.is_in_group(&"beam_target"), "o feixe acerta")
	var sprite: AnimatedSprite2D = tower.get_node("Mount/Sprite")
	assert_not_null(sprite.sprite_frames, "quadros da torre")
	var frame: Texture2D = sprite.sprite_frames.get_frame_texture(&"scan", 0)
	assert_true(frame is AtlasTexture, "quadro recortado")
	assert_eq(
		(frame as AtlasTexture).atlas.resource_path, Cx2Armored.ARMORED_SHEET, "arte blindada"
	)


func test_thermal_platform_follows_the_heat_cycle() -> void:
	var platform: ThermalPlatform = _add(PLATFORM_SCENE)
	platform.configure({"path": [[0, 0], [0, -9]], "phase": 0.0})
	var low: Vector2 = platform.point_at(0.0)
	var high: Vector2 = platform.point_at(1.0)
	assert_almost_eq(high.y - low.y, -9.0 * Balance.TILE_SIZE, 0.01, "sobe 9 tiles")
	assert_eq(ThermalPlatform.heat_frame(0.0), 0, "fria embaixo")
	assert_eq(ThermalPlatform.heat_frame(1.0), ThermalPlatform.HEAT_FRAMES - 1, "branca em cima")
	platform._physics_process(Balance.ARGOS_LIFT_CYCLE * 0.6)
	assert_almost_eq(platform.current_ratio(), 1.0, 0.001, "no alto do ciclo")
	assert_almost_eq(
		platform.point_at(platform.current_ratio()).y, high.y, 0.01, "alvo no alto do trilho"
	)
	platform.freeze()
	var parked: float = platform.current_ratio()
	platform._physics_process(1.0)
	assert_almost_eq(platform.current_ratio(), parked, 0.001, "congelada não mexe")
	assert_true(platform.powered, "a energia do terminal não a para")
	platform.set_powered(false)
	assert_true(platform.powered, "continua viva")


func test_encounter_resets_and_wins_on_the_third_coupler() -> void:
	GameState.abilities.append(ROOT)
	var level: Node2D = _stub_level()
	var network := EnergyNetwork.new()
	level.add_child(network)
	network.load_terminals([String(TERMINAL)])
	var couplers: Array[RootCoupler] = []
	for index: int in range(3):
		var coupler: RootCoupler = _make(COUPLER_SCENE)
		coupler.configure({
			"id": "c%d" % index, "terminal_id": String(TERMINAL), "system_id": String(LINES[index])
		})
		level.add_child(coupler)
		couplers.append(coupler)
	var tower: Cx2Armored = _make(TOWER_SCENE)
	tower.add_to_group(&"argos_tower")
	level.add_child(tower)
	var floor_tile: ElectricFloor = _make(FLOOR_SCENE)
	floor_tile.add_to_group(&"argos_floor")
	level.add_child(floor_tile)
	var heat: HeatZone = _make(HEAT_SCENE)
	heat.add_to_group(&"rc_heat")
	level.add_child(heat)
	var platform: ThermalPlatform = _make(PLATFORM_SCENE)
	level.add_child(platform)
	network.apply_all(TERMINAL, true)
	var encounter: ArgosEncounter = load(ENCOUNTER_SCRIPT).new()
	level.add_child(encounter)
	encounter._configure()
	assert_true(encounter.is_configured(), "lê o bloco argos")
	assert_eq(encounter.couplers().size(), 3, "acha os três acopladores")
	assert_eq(encounter.state_name(), "idle", "espera o MU-7")
	encounter._logic.start()
	network.toggle(TERMINAL, &"coolant")
	network.toggle(TERMINAL, &"line_1")
	assert_true(couplers[0].powered, "linha 1 alimenta o acoplador 1")
	assert_true(encounter.overload_coupler(&"c0"), "acoplador 1 queima")
	assert_eq(encounter.overloaded_count(), 1, "conta um")
	assert_eq(encounter.phase(), 2, "fase 2")
	assert_almost_eq(
		tower.sweep_speed(), Balance.CX2_SWEEP_SPEED * (1.0 + Balance.ARGOS_PHASE_SPEEDUP), 0.001,
		"torre acelera"
	)
	encounter.reset_encounter()
	assert_eq(encounter.state_name(), "idle", "reset volta a esperar")
	assert_eq(encounter.overloaded_count(), 0, "reset limpa a contagem")
	assert_false(couplers[0].is_overloaded(), "reset limpa o acoplador")
	assert_false(couplers[0].powered, "reset devolve a energia inicial")
	assert_almost_eq(encounter.time_left(), Balance.ARGOS_TIME, 0.001, "relógio cheio")
	encounter._logic.start()
	for coupler: RootCoupler in couplers:
		coupler.force_overload()
	assert_true(encounter.is_defeated(), "três acopladores derrubam o ARGOS")
	assert_false(tower.is_active(), "torre apaga")
	assert_false(floor_tile.is_live(), "piso apaga")
	assert_false((heat.get_node("Glow") as PointLight2D).enabled, "o calor cai")
	assert_true(platform.is_frozen(), "plataforma para")
	encounter._kill_tween()


func test_level_scene_carries_the_encounter() -> void:
	var packed: PackedScene = load(LEVEL_SCENE)
	assert_not_null(packed, "cena carrega")
	var state: SceneState = packed.get_state()
	var found: bool = false
	for index: int in range(state.get_node_count()):
		if String(state.get_node_name(index)) == "Argos":
			found = true
	assert_true(found, "nó Argos na fase")


func _stub_level() -> Node2D:
	var level := Node2D.new()
	level.set_script(load(STUB_LEVEL))
	level.set(&"meta", {
		"argos": {
			"terminal": String(TERMINAL),
			"core": [64, 64],
			"arena": [0, 0, 20, 20],
			"heat_group": "rc_heat",
			"tower_group": "argos_tower",
			"floor_group": "argos_floor",
			"alarm_group": "rc_alarm",
		}
	})
	_track(level)
	Engine.get_main_loop().root.add_child(level)
	return level


func _coupler(id: StringName) -> RootCoupler:
	var coupler: RootCoupler = _add(COUPLER_SCENE)
	coupler.configure({"id": String(id)})
	return coupler


func _make(path: String) -> Node:
	return (load(path) as PackedScene).instantiate()


func _add(path: String) -> Node:
	var node: Node = _make(path)
	_track(node)
	Engine.get_main_loop().root.add_child(node)
	return node


func _track(node: Node) -> void:
	_nodes.append(node)
