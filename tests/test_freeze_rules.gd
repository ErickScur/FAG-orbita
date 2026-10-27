extends TestCase

const HEAT_SCENE: String = "res://scenes/world/heat_zone.tscn"
const ISLAND_SCENE: String = "res://scenes/world/cold_island.tscn"
const STEP: float = 1.0 / 60.0

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	GameState.clear_statuses()


func test_cold_freezes_unless_warmed_or_immune() -> void:
	assert_true(FreezeRules.freezes(true, false, false), "frio congela")
	assert_false(FreezeRules.freezes(true, true, false), "aquecedor ligado anula")
	assert_false(FreezeRules.freezes(true, false, true), "Núcleo Aquecido imuniza")
	assert_false(FreezeRules.freezes(false, false, false), "fora do frio nada")
	assert_true(FreezeRules.has_heated_core([&"heated_core"]), "habilidade reconhecida")
	assert_false(FreezeRules.has_heated_core([&"heat_sink"]), "Dissipador não é Núcleo")


func test_freeze_status_slows_and_shortens_the_jump() -> void:
	var statuses := StatusEffects.new()
	statuses.apply(StatusEffects.FREEZE)
	assert_almost_eq(statuses.speed_multiplier(), 0.5, 0.0001, "velocidade -50%")
	assert_almost_eq(statuses.jump_multiplier(), 0.7, 0.0001, "pulo -30%")
	assert_true(statuses.is_slippery(), "chão escorregadio")
	assert_almost_eq(FreezeRules.walk_speed(statuses.speed_multiplier()), 55.0, 0.001, "55 px/s")
	assert_almost_eq(FreezeRules.walk_speed(1.0), Balance.WALK_SPEED, 0.001, "normal 110")
	assert_true(Balance.V9_CHASE_SPEED > FreezeRules.walk_speed(0.5), "a V-9 alcança o congelado")
	assert_true(Balance.V9_CHASE_SPEED < FreezeRules.walk_speed(1.0), "e não o MU-7 normal")


func test_frozen_jump_peak_is_seventy_percent_of_the_height() -> void:
	var height: float = FreezeRules.jump_height(Balance.FREEZE_JUMP_MULT)
	assert_almost_eq(height, Balance.JUMP_HEIGHT * 0.7, 0.001, "28 px")
	var initial: float = PlatformerMath.jump_velocity(height, Balance.GRAVITY, STEP)
	var peak: float = PlatformerMath.simulate_jump_peak(
		initial, Balance.GRAVITY, STEP, Balance.MAX_FALL_SPEED
	)
	assert_almost_eq(peak, height, 1.0, "o pico simulado bate com a altura")
	assert_true(peak < Balance.TILE_SIZE * 2.0, "congelado não sobe degrau de 2 tiles")


func test_slippery_floor_brakes_at_twenty_percent() -> void:
	var normal: float = FreezeRules.horizontal_rate(0.0, 80.0, true, false)
	assert_almost_eq(normal, Balance.WALK_DECEL, 0.001, "freio normal")
	var icy: float = FreezeRules.horizontal_rate(0.0, 80.0, true, true)
	assert_almost_eq(icy, Balance.WALK_DECEL * Balance.FREEZE_DECEL_MULT, 0.001, "gelo: 0,2")
	var turning: float = FreezeRules.horizontal_rate(-1.0, 80.0, true, true)
	assert_almost_eq(
		turning, Balance.WALK_ACCEL * Balance.FREEZE_DECEL_MULT, 0.001, "virar também escorrega"
	)
	assert_almost_eq(
		FreezeRules.horizontal_rate(1.0, 80.0, true, true), Balance.WALK_ACCEL, 0.001,
		"acelerar no mesmo sentido não muda"
	)
	assert_almost_eq(
		FreezeRules.horizontal_rate(0.0, 80.0, false, true),
		Balance.WALK_DECEL * Balance.AIR_ACCEL_RATIO, 0.001, "no ar vale o controle aéreo"
	)


func test_slide_distance_grows_on_ice() -> void:
	assert_true(_slide(true) > _slide(false) * 4.0, "escorrega pelo menos 4x mais longe")


func test_zone_kinds_keep_the_lab_defaults() -> void:
	assert_eq(HeatRules.normalize_kind(&""), HeatRules.KIND_WARM, "h sem kind = calor")
	assert_eq(HeatRules.normalize_kind(&"cold"), HeatRules.KIND_COLD, "frio")
	assert_eq(HeatRules.normalize_kind(&"furnace"), HeatRules.KIND_FURNACE, "fornalha")
	assert_eq(HeatRules.normalize_island_kind(&""), HeatRules.ISLAND_COOL, "i sem kind = fria")
	assert_eq(HeatRules.normalize_island_kind(&"warm"), HeatRules.ISLAND_WARM, "aquecedor")


func test_cold_zone_scene_has_one_blue_light_and_falling_flakes() -> void:
	var zone: HeatZone = _add(HEAT_SCENE)
	zone.configure({"rect": [6, 3], "kind": "cold"})
	assert_true(zone.is_cold(), "zona fria")
	assert_false(zone.is_furnace(), "não é fornalha")
	var glow: PointLight2D = zone.get_node("Glow")
	assert_eq(glow.color, HeatZone.COLD_COLOR, "luz azul")
	assert_true(glow.energy < HeatZone.WARM_ENERGY, "fraca")
	var flakes: CPUParticles2D = zone.get_node("Shimmer")
	assert_true(flakes.gravity.y > 0.0, "flocos caem")


func test_warm_island_follows_power_and_warms() -> void:
	var island: ColdIsland = _add(ISLAND_SCENE)
	island.configure({"rect": [3, 2], "kind": "warm"})
	assert_true(island.is_warm(), "aquecedor")
	assert_true(island.warms(), "ligado aquece")
	assert_false(island.cools(), "não resfria")
	var glow: PointLight2D = island.get_node("Glow")
	assert_eq(glow.color, ColdIsland.WARM_LIGHT_COLOR, "luz laranja")
	assert_true((island.get_node("Frost") as CPUParticles2D).gravity.y < 0.0, "vapor sobe")
	island.set_powered_silent(false)
	assert_false(island.warms(), "desligado não aquece")
	var cool: ColdIsland = _add(ISLAND_SCENE)
	cool.configure({"rect": [3, 2]})
	assert_true(cool.cools(), "ilha do Laboratório continua fria")
	assert_eq((cool.get_node("Glow") as PointLight2D).color, ColdIsland.LIGHT_COLOR, "luz azul")


func _slide(slippery: bool) -> float:
	var speed: float = Balance.WALK_SPEED
	var travelled: float = 0.0
	for _index: int in range(600):
		var rate: float = FreezeRules.horizontal_rate(0.0, speed, true, slippery)
		speed = PlatformerMath.approach(speed, 0.0, rate * STEP)
		travelled += speed * STEP
		if is_zero_approx(speed):
			break
	return travelled


func _add(scene_path: String) -> Node:
	var node: Node = load(scene_path).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	_nodes.append(node)
	return node
