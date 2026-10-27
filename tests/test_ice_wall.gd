extends TestCase

const WALL_SCENE: String = "res://scenes/world/ice_wall.tscn"
const ISLAND_SCENE: String = "res://scenes/world/cold_island.tscn"
const STEP: float = 1.0 / 60.0

var _nodes: Array[Node] = []
var _abilities_before: Array[StringName] = []


func before_each() -> void:
	_abilities_before = GameState.abilities.duplicate()


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()
	GameState.abilities = _abilities_before


func test_heater_melts_in_half_a_second_and_cold_refreezes() -> void:
	var wall := IceWallLogic.new()
	assert_true(wall.is_solid(), "nasce congelada")
	wall.heated = true
	_run(wall, Balance.ICE_MELT_TIME * 0.5, false)
	assert_true(wall.is_solid(), "derretendo ainda bloqueia")
	assert_eq(wall.frame(), IceWallLogic.FRAME_MELTING_B, "meio derretida")
	_run(wall, Balance.ICE_MELT_TIME * 0.6, false)
	assert_false(wall.is_solid(), "0,5 s: passagem aberta")
	assert_eq(wall.frame(), IceWallLogic.FRAME_EMPTY, "vazia")
	wall.heated = false
	wall.update(STEP, false)
	assert_true(wall.is_solid(), "aquecedor desligado: volta a bloquear na hora")
	_run(wall, Balance.ICE_MELT_TIME + 0.05, false)
	assert_eq(wall.frame(), IceWallLogic.FRAME_SOLID, "recongelada")


func test_wall_never_refreezes_on_top_of_the_player() -> void:
	var wall := IceWallLogic.new()
	wall.heated = true
	wall.settle()
	wall.heated = false
	_run(wall, 2.0, true)
	assert_false(wall.is_solid(), "MU-7 dentro: espera")
	wall.update(STEP, false)
	assert_true(wall.is_solid(), "saiu: recongela")


func test_heated_core_melts_for_good() -> void:
	assert_true(IceWallLogic.melts_on_touch([&"heated_core"]), "com Núcleo Aquecido")
	assert_false(IceWallLogic.melts_on_touch([&"heat_sink"]), "sem ele não")
	var wall := IceWallLogic.new()
	assert_true(wall.melt_forever(), "encostou")
	assert_false(wall.melt_forever(), "só uma vez")
	_run(wall, Balance.ICE_MELT_TIME + 0.05, false)
	assert_false(wall.is_solid(), "derreteu")
	wall.heated = false
	_run(wall, 3.0, false)
	assert_false(wall.is_solid(), "não volta mais")


func test_wall_scene_follows_its_heater_group() -> void:
	var island: ColdIsland = _add(ISLAND_SCENE)
	island.configure({"kind": "warm"})
	island.add_to_group(&"heater_probe")
	var wall: IceWall = _add(WALL_SCENE)
	wall.configure({"heater": "heater_probe"})
	assert_eq(wall.collision_layer, 1, "bloqueia como mundo")
	_tick(wall, 1)
	assert_false(wall.is_solid(), "aquecedor ligado ao carregar: já aberta, sem animação")
	island.set_powered_silent(false)
	_tick(wall, 2)
	assert_true(wall.is_solid(), "desligou: volta a bloquear")
	_tick(wall, 40)
	assert_eq(wall.current_frame(), IceWallLogic.FRAME_SOLID, "recongelada")
	island.set_powered_silent(true)
	_tick(wall, 40)
	assert_false(wall.is_solid(), "religou: derrete")


func test_wall_scene_follows_a_direct_binding() -> void:
	var wall: IceWall = _add(WALL_SCENE)
	wall.configure({"terminal_id": "inf", "system_id": "heating"})
	assert_true(wall.is_in_group(&"powered"), "responde ao terminal")
	wall.set_powered_silent(false)
	_tick(wall, 1)
	assert_true(wall.is_solid(), "sem aquecimento: congelada")
	wall.set_powered(true)
	_tick(wall, 40)
	assert_false(wall.is_solid(), "aquecimento ligado: derreteu")


func test_heated_core_melts_the_whole_column() -> void:
	GameState.abilities = [&"heated_core"]
	var bottom: IceWall = _add(WALL_SCENE)
	var middle: IceWall = _add(WALL_SCENE)
	var top: IceWall = _add(WALL_SCENE)
	var apart: IceWall = _add(WALL_SCENE)
	middle.position.y -= 16.0
	top.position.y -= 32.0
	apart.position.y -= 64.0
	bottom._melt_column()
	assert_true(bottom.is_melted_forever(), "a que o MU-7 tocou")
	assert_true(middle.is_melted_forever(), "a de cima, encostada")
	assert_true(top.is_melted_forever(), "a pilha inteira")
	assert_false(apart.is_melted_forever(), "bloco separado por um vão fica")


func test_reachability_treats_ice_walls_as_open() -> void:
	var room: String = "\n".join([
		"##########",
		"#    I   #",
		"#P   I  r#",
		"##########",
	])
	var result: Dictionary = LevelReachability.analyze(room)
	assert_true(LevelReachability.unreachable_pickups(result).is_empty(), "modelo generoso")


func _tick(wall: IceWall, frames: int) -> void:
	for _index: int in range(frames):
		wall._physics_process(STEP)


func _run(wall: IceWallLogic, seconds: float, occupied: bool) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		wall.update(STEP, occupied)
		elapsed += STEP


func _add(scene_path: String) -> Node:
	var node: Node = load(scene_path).instantiate()
	node.position = Vector2(-4000.0, -4000.0)
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	node.set_physics_process(false)
	_nodes.append(node)
	return node
