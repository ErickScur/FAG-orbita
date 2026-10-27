extends TestCase

const ICE_SCENE: String = "res://scenes/world/thin_ice.tscn"
const STEP: float = 1.0 / 60.0

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_ice_cracks_when_stepped_and_breaks_after_half_a_second() -> void:
	var ice := ThinIceLogic.new()
	assert_eq(ice.update(STEP, false, false), &"", "ninguém em cima")
	assert_eq(ice.frame(), ThinIceLogic.FRAME_INTACT, "inteiro")
	assert_eq(ice.update(STEP, true, true), &"cracked", "pisou: racha")
	assert_eq(ice.frame(), ThinIceLogic.FRAME_CRACKED, "quadro rachado")
	assert_true(ice.is_solid(), "rachado ainda segura")
	_run(ice, Balance.THIN_ICE_BREAK_TIME * 0.6, false, false)
	assert_eq(ice.frame(), ThinIceLogic.FRAME_BREAKING, "segunda metade: quebrando")
	assert_true(ice.is_solid(), "sair de cima não salva o gelo, mas ainda segura")
	_run(ice, Balance.THIN_ICE_BREAK_TIME * 0.5, false, false)
	assert_eq(ice.state(), ThinIceLogic.State.BROKEN, "0,5 s depois cai")
	assert_false(ice.is_solid(), "sem colisão")
	assert_eq(ice.frame(), ThinIceLogic.FRAME_EMPTY, "vazio")


func test_ice_reforms_only_when_the_space_is_free() -> void:
	var ice := ThinIceLogic.new()
	ice.update(STEP, true, true)
	_run(ice, Balance.THIN_ICE_BREAK_TIME + 0.05, false, false)
	_run(ice, Balance.THIN_ICE_REFORM_TIME - 0.1, false, false)
	assert_false(ice.is_solid(), "ainda não refez")
	_run(ice, 0.5, false, true)
	assert_false(ice.is_solid(), "alguém no espaço: espera")
	assert_eq(ice.update(STEP, false, false), &"reformed", "espaço livre: refaz")
	assert_true(ice.is_solid(), "sólido de novo")
	assert_eq(ice.frame(), ThinIceLogic.FRAME_INTACT, "inteiro de novo")


func test_thin_ice_scene_is_a_solid_world_tile() -> void:
	var ice: ThinIce = _add(ICE_SCENE)
	assert_eq(ice.collision_layer, 1, "camada mundo")
	var shape: CollisionShape2D = ice.get_node("CollisionShape2D")
	assert_eq((shape.shape as RectangleShape2D).size, Vector2(16.0, 16.0), "1 tile")
	assert_eq(ice.current_frame(), ThinIceLogic.FRAME_INTACT, "nasce inteiro")
	assert_eq((ice.get_node("Top") as Area2D).collision_mask, 2, "sensor só do jogador")
	for child: Node in ice.get_children():
		assert_false(child is LightOccluder2D, "gelo fino não faz sombra")


func test_reachability_treats_thin_ice_as_floor() -> void:
	var room: String = "\n".join([
		"##########",
		"#        #",
		"#        #",
		"#P  ___ r#",
		"###   ####",
		"##########",
	])
	var result: Dictionary = LevelReachability.analyze(room)
	assert_true(LevelReachability.can_stand_at(result, Vector2i(5, 2)), "anda em cima do gelo")
	assert_true(LevelReachability.unreachable_pickups(result).is_empty(), "atravessa a ponte")


func _run(ice: ThinIceLogic, seconds: float, stepped: bool, occupied: bool) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		ice.update(STEP, stepped, occupied)
		elapsed += STEP


func _add(scene_path: String) -> Node:
	var node: Node = load(scene_path).instantiate()
	node.position = Vector2(-4000.0, -4000.0)
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	node.set_physics_process(false)
	_nodes.append(node)
	return node
