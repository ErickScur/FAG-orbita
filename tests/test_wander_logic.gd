extends TestCase

const SEED: int = 42
const ANCHOR: Vector2 = Vector2(100.0, 50.0)
const RADIUS: float = 48.0
const DRONE_SCENE: String = "res://scenes/npc/botanico.tscn"
const GREENHOUSE_META: String = "res://data/levels/greenhouse.json"
const GREENHOUSE_MAP: String = "res://data/levels/greenhouse.txt"


func _rng(value: int = SEED) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = value
	return rng


func test_target_inside_radius() -> void:
	var rng: RandomNumberGenerator = _rng()
	for index: int in range(100):
		var target: Vector2 = WanderLogic.pick_target(ANCHOR, RADIUS, rng)
		assert_true(target.distance_to(ANCHOR) <= RADIUS + 0.001, "sorteio %d fora do raio" % index)


func test_targets_vary() -> void:
	var rng: RandomNumberGenerator = _rng()
	var seen: Dictionary = {}
	for index: int in range(10):
		seen[Vector2i(WanderLogic.pick_target(ANCHOR, RADIUS, rng))] = true
	assert_true(seen.size() >= 8, "só %d pontos distintos em 10 sorteios" % seen.size())


func test_targets_spread_to_both_sides() -> void:
	var rng: RandomNumberGenerator = _rng()
	var left: int = 0
	var right: int = 0
	for index: int in range(40):
		if WanderLogic.pick_target(ANCHOR, RADIUS, rng).x < ANCHOR.x:
			left += 1
		else:
			right += 1
	assert_true(
		left >= 10 and right >= 10, "vagueio viciado: %d à esquerda, %d à direita" % [left, right]
	)


func test_same_seed_same_sequence() -> void:
	var first: RandomNumberGenerator = _rng()
	var second: RandomNumberGenerator = _rng()
	for index: int in range(20):
		assert_eq(
			WanderLogic.pick_target(ANCHOR, RADIUS, first),
			WanderLogic.pick_target(ANCHOR, RADIUS, second),
			"sorteio %d diverge com a mesma semente" % index
		)


func test_step_moves_toward_target() -> void:
	var next: Vector2 = WanderLogic.step(Vector2.ZERO, Vector2(100.0, 0.0), 40.0, 0.5)
	assert_almost_eq(next.x, 20.0, 0.001, "anda speed*delta")
	assert_almost_eq(next.y, 0.0, 0.001, "em linha reta")


func test_step_does_not_overshoot() -> void:
	var next: Vector2 = WanderLogic.step(Vector2.ZERO, Vector2(10.0, 0.0), 40.0, 5.0)
	assert_eq(next, Vector2(10.0, 0.0), "para no alvo")


func test_reached_within_tolerance() -> void:
	assert_true(WanderLogic.reached(Vector2(2.0, 0.0), Vector2.ZERO, 3.0), "dentro")
	assert_false(WanderLogic.reached(Vector2(5.0, 0.0), Vector2.ZERO, 3.0), "fora")


func test_should_retarget_on_arrival() -> void:
	assert_true(WanderLogic.should_retarget(0.1, 1.5, false, true), "chegou")


func test_should_retarget_on_block() -> void:
	assert_true(WanderLogic.should_retarget(0.1, 1.5, true, false), "bloqueado")


func test_should_retarget_on_timeout() -> void:
	assert_true(WanderLogic.should_retarget(1.6, 1.5, false, false), "tempo")


func test_should_retarget_false_when_travelling() -> void:
	assert_false(WanderLogic.should_retarget(0.1, 1.5, false, false), "a caminho")


func test_clamp_keeps_point_inside_territory() -> void:
	var area := Rect2(0.0, 0.0, 100.0, 40.0)
	assert_eq(WanderLogic.clamp_to(Vector2(150.0, -10.0), area), Vector2(100.0, 0.0), "canto")
	assert_eq(WanderLogic.clamp_to(Vector2(50.0, 20.0), area), Vector2(50.0, 20.0), "dentro")
	var far := Vector2(500.0, 500.0)
	assert_eq(WanderLogic.clamp_to(far, Rect2()), far, "sem área")


func test_follow_point_leads_where_the_player_faces() -> void:
	var feet := Vector2(200.0, 300.0)
	var ahead_right: Vector2 = WanderLogic.follow_point(feet, 1, 40.0, 44.0)
	var ahead_left: Vector2 = WanderLogic.follow_point(feet, -1, 40.0, 44.0)
	assert_eq(ahead_right, Vector2(240.0, 256.0), "à direita e acima")
	assert_eq(ahead_left, Vector2(160.0, 256.0), "à esquerda e acima")


func test_notices_only_near_and_follows_only_inside_territory() -> void:
	var territory := Rect2(0.0, 0.0, 400.0, 100.0)
	var drone := Vector2(100.0, 50.0)
	assert_false(
		WanderLogic.should_follow(false, Vector2(300.0, 90.0), drone, territory, 120.0),
		"longe demais para notar"
	)
	assert_true(
		WanderLogic.should_follow(false, Vector2(180.0, 90.0), drone, territory, 120.0),
		"nota de perto"
	)
	assert_true(
		WanderLogic.should_follow(true, Vector2(390.0, 90.0), drone, territory, 120.0),
		"já seguindo, segue pelo território todo"
	)
	assert_false(
		WanderLogic.should_follow(true, Vector2(390.0, 300.0), drone, territory, 120.0),
		"saiu do território, volta para casa"
	)


func test_spray_only_on_arrival_and_by_chance() -> void:
	var rng: RandomNumberGenerator = _rng()
	assert_false(WanderLogic.should_spray(false, 1.0, rng), "não rega a caminho")
	assert_true(WanderLogic.should_spray(true, 1.0, rng), "chance 1 sempre rega")
	assert_false(WanderLogic.should_spray(true, 0.0, rng), "chance 0 nunca rega")
	var sprays: int = 0
	for index: int in range(200):
		if WanderLogic.should_spray(true, Balance.DRONE_SPRAY_CHANCE, rng):
			sprays += 1
	assert_true(sprays > 50 and sprays < 150, "chance de rega fora do esperado: %d/200" % sprays)


func test_territory_rect_from_tiles() -> void:
	assert_eq(
		WanderLogic.territory_rect([2, 16, 43, 6], 16),
		Rect2(32.0, 256.0, 688.0, 96.0),
		"zona em tiles vira retângulo em px"
	)
	assert_eq(WanderLogic.territory_rect([1, 2], 16), Rect2(), "zona mal escrita")


func test_follow_is_faster_than_the_player() -> void:
	assert_true(
		Balance.DRONE_FOLLOW_SPEED > Balance.WALK_SPEED,
		"o drone seguindo precisa alcançar o MU-7, senão a luz fica sempre atrás"
	)
	assert_true(Balance.DRONE_SPEED < Balance.WALK_SPEED, "vagueio sozinho é calmo")


func test_greenhouse_drone_lives_in_the_dark_corridor() -> void:
	var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(GREENHOUSE_META))
	assert_true(meta is Dictionary, "JSON da Estufa")
	var entity: Dictionary = (meta as Dictionary).get("entities", {}).get("16,18", {})
	assert_eq(String(entity.get("id", "")), "botanico_04", "BOTÂNICO 04 no tile 16,18")
	var rows: PackedStringArray = FileAccess.get_file_as_string(GREENHOUSE_MAP).split("\n")
	assert_eq(rows[18][16], "b", "símbolo b no mapa")
	var zone: Array = entity.get("zone", [])
	assert_eq(zone.size(), 4, "território declarado")
	if zone.size() != 4:
		return
	for y: int in range(int(zone[1]), int(zone[1]) + int(zone[3])):
		for x: int in range(int(zone[0]), int(zone[0]) + int(zone[2])):
			assert_true(rows[y][x] != "#", "território atravessa parede em %d,%d" % [x, y])
	var lamps: int = 0
	var entities: Dictionary = (meta as Dictionary).get("entities", {})
	for key: String in entities:
		if String((entities[key] as Dictionary).get("system_id", "")) != "corridor_light":
			continue
		var cell: PackedStringArray = key.split(",")
		var inside: bool = (
			int(cell[0]) >= int(zone[0]) and int(cell[0]) < int(zone[0]) + int(zone[2])
			and int(cell[1]) >= int(zone[1]) and int(cell[1]) < int(zone[1]) + int(zone[3])
		)
		if inside:
			lamps += 1
	assert_eq(lamps, 3, "território = corredor das três lâmpadas da ILUMINAÇÃO DO CORREDOR")


func test_drone_scene_builds_light_and_animations() -> void:
	var drone: Node = load(DRONE_SCENE).instantiate()
	assert_true(drone is Botanico, "cena do drone")
	var sprite: AnimatedSprite2D = drone.get_node("Sprite") as AnimatedSprite2D
	var lamp: PointLight2D = drone.get_node("Lamp") as PointLight2D
	assert_not_null(sprite, "sprite")
	assert_not_null(lamp, "luz")
	drone.free()
