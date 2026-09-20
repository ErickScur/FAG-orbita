extends TestCase

const SR3_SCENE: String = "res://scenes/enemies/sr3.tscn"
const SPORE_SCENE: String = "res://scenes/enemies/spore_swarm.tscn"
const LAYER_WORLD: int = 1
const LAYER_PLAYER: int = 2
const LAYER_ENEMY: int = 4
const LAYER_HAZARD: int = 16
const LAYER_ONE_WAY: int = 64


func test_sr3_scene_uses_the_enemy_layer_and_ignores_the_player() -> void:
	var node: Node = _instantiate(SR3_SCENE)
	if node == null:
		return
	var body: CharacterBody2D = node
	assert_eq(body.collision_layer, LAYER_ENEMY, "camada do corpo")
	assert_eq(body.collision_mask, LAYER_WORLD, "máscara do corpo (só mundo)")
	assert_true(body.is_in_group(&"beam_target"), "alvo do feixe (F31)")
	node.free()


func test_sr3_hitbox_is_a_damage_area_on_the_enemy_layer() -> void:
	var node: Node = _instantiate(SR3_SCENE)
	if node == null:
		return
	var hitbox: Node = node.get_node_or_null("Hitbox")
	assert_not_null(hitbox, "nó Hitbox")
	if hitbox != null:
		assert_true(hitbox is DamageArea, "Hitbox é DamageArea")
		assert_eq((hitbox as Area2D).collision_layer, LAYER_ENEMY, "camada da hitbox")
	node.free()


func test_sr3_probes_see_the_floor_and_the_walls() -> void:
	var node: Node = _instantiate(SR3_SCENE)
	if node == null:
		return
	var floor_probe: RayCast2D = node.get_node_or_null("FloorProbe")
	var wall_probe: RayCast2D = node.get_node_or_null("WallProbe")
	assert_not_null(floor_probe, "sonda de chão")
	assert_not_null(wall_probe, "sonda de parede")
	if floor_probe != null:
		assert_eq(
			floor_probe.collision_mask,
			LAYER_WORLD | LAYER_ONE_WAY,
			"sonda de chão vê mundo e plataforma fina"
		)
		assert_true(floor_probe.target_position.y > 0.0, "sonda de chão aponta para baixo")
	if wall_probe != null:
		assert_eq(wall_probe.collision_mask, LAYER_WORLD, "sonda de parede vê o mundo")
	node.free()


func test_spore_swarm_is_a_hazard_that_watches_the_player() -> void:
	var node: Node = _instantiate(SPORE_SCENE)
	if node == null:
		return
	assert_true(node is DamageArea, "enxame é DamageArea")
	var area: Area2D = node
	assert_eq(area.collision_layer, LAYER_HAZARD, "camada de perigo")
	assert_eq(area.collision_mask, LAYER_PLAYER, "enxerga o jogador")
	assert_true(node.is_in_group(&"powered"), "reage à energia (ADR-011)")
	node.free()


func test_spore_swarm_starts_with_the_balance_radius() -> void:
	var node: Node = _instantiate(SPORE_SCENE)
	if node == null:
		return
	var shape: CollisionShape2D = node.get_node_or_null("CollisionShape2D")
	assert_not_null(shape, "forma de colisão")
	if shape != null and shape.shape is CircleShape2D:
		assert_almost_eq(
			(shape.shape as CircleShape2D).radius, Balance.SPORE_RADIUS, 0.0001, "raio inicial"
		)
	assert_not_null(node.get_node_or_null("Particles"), "partículas 2D")
	node.free()


func test_level_builder_points_to_the_new_scenes() -> void:
	assert_eq(
		String(LevelBuilder.LEGEND["S"]["scene"]), SR3_SCENE, "legenda da SR-3"
	)
	assert_eq(
		String(LevelBuilder.LEGEND["~"]["scene"]), SPORE_SCENE, "legenda do enxame"
	)
	assert_true(ResourceLoader.exists(SR3_SCENE), "cena da SR-3 existe")
	assert_true(ResourceLoader.exists(SPORE_SCENE), "cena do enxame existe")


func _instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path):
		fail("cena ausente: %s" % path)
		return null
	var scene: PackedScene = load(path)
	if scene == null:
		fail("cena inválida: %s" % path)
		return null
	return scene.instantiate()
