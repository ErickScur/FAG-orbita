extends TestCase

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_can_fire_needs_charge_and_no_discharge() -> void:
	assert_true(BeamLogic.can_fire(25.0, 25.0, false), "Carga igual ao custo")
	assert_false(BeamLogic.can_fire(24.0, 25.0, false), "Carga abaixo do custo")
	assert_false(BeamLogic.can_fire(100.0, 25.0, true), "DESCARGA bloqueia")


func test_ray_follows_facing_and_range() -> void:
	assert_eq(BeamLogic.ray_vector(1, Balance.BEAM_RANGE), Vector2(32.0, 0.0), "à direita")
	assert_eq(BeamLogic.ray_vector(-1, Balance.BEAM_RANGE), Vector2(-32.0, 0.0), "à esquerda")


func test_beam_stops_at_the_hit_point() -> void:
	var origin := Vector2(100.0, 50.0)
	assert_almost_eq(
		BeamLogic.beam_length(origin, Vector2(112.0, 50.0), 32.0), 12.0, 0.001, "corta no alvo"
	)
	assert_almost_eq(BeamLogic.beam_length(origin, null, 32.0), 32.0, 0.001, "errou: alcance cheio")


func test_resolve_target_finds_the_machine_from_its_child_collider() -> void:
	var machine: Node2D = _make(&"beam_target", true)
	var mount := Node2D.new()
	var body := StaticBody2D.new()
	machine.add_child(mount)
	mount.add_child(body)
	assert_eq(BeamLogic.resolve_target(body), machine, "sobe do corpo até a máquina")
	assert_eq(BeamLogic.resolve_target(machine), machine, "a própria máquina")


func test_resolve_target_ignores_walls_and_machines_without_shutdown() -> void:
	var wall: Node2D = _make(&"", false)
	assert_null(BeamLogic.resolve_target(wall), "parede não é alvo")
	var grouped_without_method: Node2D = _make(&"beam_target", false)
	assert_null(BeamLogic.resolve_target(grouped_without_method), "no grupo mas sem shutdown")
	assert_null(BeamLogic.resolve_target(null), "nada atingido")


func test_every_beam_target_scene_can_be_shut_down() -> void:
	for scene_path: String in ["res://scenes/enemies/sr3.tscn", "res://scenes/enemies/cx2.tscn"]:
		var packed: PackedScene = load(scene_path)
		assert_not_null(packed, scene_path)
		if packed == null:
			continue
		var node: Node = packed.instantiate()
		_nodes.append(node)
		assert_true(node.is_in_group(BeamLogic.TARGET_GROUP), "%s no grupo do feixe" % scene_path)
		assert_true(node.has_method(BeamLogic.SHUTDOWN_METHOD), "%s tem shutdown()" % scene_path)


func test_the_mu7_beam_ray_sees_walls_and_enemies_only() -> void:
	var packed: PackedScene = load("res://scenes/player/mu7.tscn")
	var player: Node = packed.instantiate()
	_nodes.append(player)
	var ray: RayCast2D = player.get_node("BeamRay")
	assert_eq(ray.collision_mask, 1 | 4, "camadas world e enemy")
	assert_true(ray.position.y > -12.0, "na altura da SR-3, que tem 10 px")


func _make(group: StringName, with_shutdown: bool) -> Node2D:
	var node := Node2D.new()
	if with_shutdown:
		node.set_script(_shutdown_script())
	if group != &"":
		node.add_to_group(group)
	_nodes.append(node)
	return node


func _shutdown_script() -> GDScript:
	var script := GDScript.new()
	script.source_code = "extends Node2D\n\nfunc shutdown(_duration: float) -> void:\n\treturn\n"
	script.reload()
	return script
