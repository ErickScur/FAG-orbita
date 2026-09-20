extends TestCase

const WALL_SCENE: String = "res://scenes/world/magnetic_wall.tscn"
const PLATFORM_SCENE: String = "res://scenes/world/moving_platform.tscn"
const PLANT_SCENE: String = "res://scenes/world/grow_plant.tscn"
const LAYER_WORLD: int = 1
const LAYER_ONE_WAY: int = 64
const PLAYER_MASK: int = 65


func test_magnetic_wall_is_solid_and_climbable() -> void:
	var node: Node = _instantiate(WALL_SCENE)
	if node == null:
		return
	var body: StaticBody2D = node
	assert_eq(body.collision_layer, LAYER_WORLD, "camada do mundo")
	assert_true(node.is_in_group(ClimbLogic.MAGNETIC_GROUP), "grupo magnetic")
	var shape: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	assert_not_null(shape, "forma de colisão")
	if shape != null and shape.shape is RectangleShape2D:
		assert_eq(
			(shape.shape as RectangleShape2D).size,
			Vector2(float(Balance.TILE_SIZE), float(Balance.TILE_SIZE)),
			"um tile"
		)
	node.free()


func test_player_mask_reaches_walls_and_one_way() -> void:
	assert_eq(PLAYER_MASK & LAYER_WORLD, LAYER_WORLD, "o jogador colide com a parede")
	assert_eq(PLAYER_MASK & LAYER_ONE_WAY, LAYER_ONE_WAY, "o jogador pisa em plataforma fina")


func test_moving_platform_is_one_way_and_powered() -> void:
	var node: Node = _instantiate(PLATFORM_SCENE)
	if node == null:
		return
	var body: AnimatableBody2D = node
	assert_eq(body.collision_layer, LAYER_ONE_WAY, "camada one_way")
	assert_true(body.sync_to_physics, "carrega o jogador sem tremer")
	assert_true(node.is_in_group(&"powered"), "reage à energia (ADR-011)")
	var shape: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	assert_not_null(shape, "forma de colisão")
	if shape != null:
		assert_true(shape.one_way_collision, "atravessa por baixo")
	node.free()


func test_moving_platform_reads_the_path_from_the_level_json() -> void:
	var node: Node = _instantiate(PLATFORM_SCENE)
	if node == null:
		return
	var platform: MovingPlatform = node
	platform.configure({
		"terminal_id": "greenhouse",
		"system_id": "lift_platform",
		"path": [[0, 0], [0, -10]],
		"speed": 32,
		"wait": 1.0,
	})
	assert_eq(platform.terminal_id, &"greenhouse", "terminal")
	assert_eq(platform.system_id, &"lift_platform", "sistema")
	assert_eq(platform.path_tiles.size(), 2, "dois pontos")
	assert_eq(platform.path_tiles[1], Vector2(0.0, -10.0), "sobe dez tiles")
	node.free()


func test_moving_platform_points_are_converted_to_pixels() -> void:
	var points: PackedVector2Array = MovingPlatform.points_from([[0, 0], [0, -10], [4, -10]])
	assert_eq(points.size(), 3, "três pontos")
	assert_eq(points[2], Vector2(4.0, -10.0), "offset em tiles")


func test_grow_plant_top_is_one_way_and_starts_disabled() -> void:
	var node: Node = _instantiate(PLANT_SCENE)
	if node == null:
		return
	assert_true(node.is_in_group(&"powered"), "reage à energia (ADR-011)")
	var top: StaticBody2D = node.get_node_or_null("Top")
	assert_not_null(top, "topo da planta")
	if top != null:
		assert_eq(top.collision_layer, LAYER_ONE_WAY, "camada one_way")
	var shape: CollisionShape2D = node.get_node_or_null("Top/CollisionShape2D")
	assert_not_null(shape, "forma do topo")
	if shape != null:
		assert_true(shape.disabled, "só vira plataforma quando adulta")
		assert_true(shape.one_way_collision, "pisável só por cima")
		if shape.shape is RectangleShape2D:
			assert_eq(
				(shape.shape as RectangleShape2D).size, Vector2(32.0, 4.0), "topo de 32 px"
			)
	node.free()


func test_grow_plant_flag_id_uses_the_entity_id() -> void:
	var node: Node = _instantiate(PLANT_SCENE)
	if node == null:
		return
	var plant: GrowPlant = node
	plant.configure({"terminal_id": "greenhouse", "system_id": "grow_light", "id": "gh_plant_1"})
	assert_eq(plant.plant_id, &"gh_plant_1", "id vindo do JSON da fase")
	assert_eq(plant.flag_id(), "plant_gh_plant_1", "flag de progresso permanente")
	node.free()


func test_level_builder_points_to_the_new_scenes() -> void:
	assert_eq(String(LevelBuilder.LEGEND["M"]["scene"]), WALL_SCENE, "legenda da parede")
	assert_eq(String(LevelBuilder.LEGEND["m"]["scene"]), PLATFORM_SCENE, "legenda da plataforma")
	assert_eq(String(LevelBuilder.LEGEND["g"]["scene"]), PLANT_SCENE, "legenda da planta")
	assert_true(ResourceLoader.exists(WALL_SCENE), "cena da parede existe")
	assert_true(ResourceLoader.exists(PLATFORM_SCENE), "cena da plataforma existe")
	assert_true(ResourceLoader.exists(PLANT_SCENE), "cena da planta existe")


func test_grow_plant_comes_back_grown_from_the_save() -> void:
	var node: Node = _instantiate(PLANT_SCENE)
	if node == null:
		return
	var plant: GrowPlant = node
	GameState.flags["plant_gh_plant_1"] = true
	plant.configure({"id": "gh_plant_1"})
	assert_true(plant.is_grown(), "a planta adulta volta adulta do save")
	GameState.flags.erase("plant_gh_plant_1")
	node.free()


func test_grow_plant_without_flag_starts_as_a_sprout() -> void:
	var node: Node = _instantiate(PLANT_SCENE)
	if node == null:
		return
	var plant: GrowPlant = node
	GameState.flags.erase("plant_gh_plant_2")
	plant.configure({"id": "gh_plant_2"})
	assert_false(plant.is_grown(), "sem flag nasce broto")
	node.free()


func _instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path):
		fail("cena ausente: %s" % path)
		return null
	var scene: PackedScene = load(path)
	if scene == null:
		fail("cena inválida: %s" % path)
		return null
	return scene.instantiate()
