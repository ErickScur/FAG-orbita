extends TestCase

const CX2_SCENE: String = "res://scenes/enemies/cx2.tscn"
const STEP: float = 1.0 / 60.0

var _logic: Cx2Logic = null


func before_each() -> void:
	_logic = Cx2Logic.new()


func test_sweep_starts_centered_and_reaches_both_ends() -> void:
	var arc: float = Balance.CX2_SWEEP_ARC
	var speed: float = Balance.CX2_SWEEP_SPEED
	var quarter: float = arc / speed
	assert_almost_eq(Cx2Logic.sweep_offset(0.0, arc, speed), 0.0, 0.001, "começa no centro")
	assert_almost_eq(Cx2Logic.sweep_offset(quarter, arc, speed), arc, 0.001, "ponta direita")
	assert_almost_eq(Cx2Logic.sweep_offset(quarter * 2.0, arc, speed), 0.0, 0.001, "volta")
	assert_almost_eq(Cx2Logic.sweep_offset(quarter * 3.0, arc, speed), -arc, 0.001, "outra ponta")
	assert_almost_eq(Cx2Logic.sweep_offset(quarter * 4.0, arc, speed), 0.0, 0.001, "período")


func test_sweep_never_leaves_the_arc() -> void:
	var t: float = 0.0
	while t < 20.0:
		var offset: float = Cx2Logic.sweep_offset(t, Balance.CX2_SWEEP_ARC, Balance.CX2_SWEEP_SPEED)
		assert_true(absf(offset) <= Balance.CX2_SWEEP_ARC + 0.001, "dentro do arco em %s" % t)
		t += 0.37


func test_cone_contains_points_inside_angle_and_range() -> void:
	var origin := Vector2.ZERO
	var half: float = Balance.CX2_CONE_HALF_ANGLE
	var reach: float = Balance.CX2_RANGE
	assert_true(Cx2Logic.in_cone(origin, 90.0, half, reach, Vector2(0, 50)), "logo abaixo")
	var edge: Vector2 = Cx2Logic.direction(90.0 + half - 1.0) * 60.0
	assert_true(Cx2Logic.in_cone(origin, 90.0, half, reach, edge), "perto da borda")
	var outside: Vector2 = Cx2Logic.direction(90.0 + half + 2.0) * 60.0
	assert_false(Cx2Logic.in_cone(origin, 90.0, half, reach, outside), "fora do ângulo")
	assert_false(Cx2Logic.in_cone(origin, 90.0, half, reach, Vector2(0, reach + 1.0)), "longe")
	assert_false(Cx2Logic.in_cone(origin, 90.0, half, reach, Vector2(0, -20)), "atrás da torre")


func test_mounts_aim_into_the_room() -> void:
	assert_almost_eq(Cx2Logic.mount_aim(Cx2Logic.MOUNT_CEILING), 90.0, 0.001, "teto mira baixo")
	assert_almost_eq(Cx2Logic.mount_aim(Cx2Logic.MOUNT_WALL_LEFT), 0.0, 0.001, "esquerda")
	assert_almost_eq(Cx2Logic.mount_aim(Cx2Logic.MOUNT_WALL_RIGHT), 180.0, 0.001, "direita")
	assert_eq(Cx2Logic.normalize_mount(&"floor"), Cx2Logic.MOUNT_CEILING, "montagem inválida")
	for mount: StringName in [Cx2Logic.MOUNT_WALL_LEFT, Cx2Logic.MOUNT_WALL_RIGHT]:
		var down := Vector2(0, 1).rotated(deg_to_rad(Cx2Logic.mount_rotation(mount)))
		var aim: Vector2 = Cx2Logic.direction(Cx2Logic.mount_aim(mount))
		assert_true(down.distance_to(aim) < 0.001, "sprite girado aponta a mira: %s" % mount)
		assert_true(
			Cx2Logic.mount_base(mount).distance_to(-aim) < 0.001, "base fica na parede: %s" % mount
		)


func test_lock_only_grows_with_line_of_sight() -> void:
	var fired: bool = _run(Balance.CX2_LOCK_TIME * 0.5, true)
	assert_false(fired, "meia trava não dispara")
	assert_eq(_logic.phase(), Cx2Logic.Phase.LOCK, "travando")
	assert_true(_logic.lock_ratio() > 0.4, "trava subiu")
	_logic.update(STEP, false)
	assert_almost_eq(_logic.lock_ratio(), 0.0, 0.0001, "perdeu a visão, zera")
	assert_eq(_logic.phase(), Cx2Logic.Phase.SCAN, "volta a varrer")
	assert_false(_run(Balance.CX2_LOCK_TIME * 0.6, true), "recomeça do zero")


func test_fires_after_lock_time_then_cools_down() -> void:
	assert_false(_run(Balance.CX2_LOCK_TIME - 0.05, true), "antes do tempo de trava")
	assert_true(_run(0.2, true), "dispara com a trava completa")
	assert_eq(_logic.phase(), Cx2Logic.Phase.COOLDOWN, "recarrega")
	assert_false(_run(Balance.CX2_COOLDOWN - 0.4, true), "não trava durante a recarga")
	assert_eq(_logic.phase(), Cx2Logic.Phase.COOLDOWN, "ainda recarregando")
	assert_almost_eq(_logic.lock_ratio(), 0.0, 0.0001, "trava parada na recarga")
	_run(0.5, false)
	assert_eq(_logic.phase(), Cx2Logic.Phase.SCAN, "recarga acabou")
	assert_true(_run(Balance.CX2_LOCK_TIME + 0.1, true), "dispara de novo")


func test_sweep_freezes_while_locking() -> void:
	_run(0.5, false)
	var before: float = _logic.aim_angle()
	_run(Balance.CX2_LOCK_TIME * 0.8, true)
	assert_almost_eq(_logic.aim_angle(), before, 0.0001, "cone para em cima do alvo")
	_run(0.2, false)
	assert_ne(_logic.aim_angle(), before, "volta a varrer")


func test_powered_off_never_fires() -> void:
	_run(Balance.CX2_LOCK_TIME * 0.5, true)
	_logic.set_powered(false)
	assert_eq(_logic.phase(), Cx2Logic.Phase.OFF, "desligada")
	assert_false(_run(Balance.CX2_LOCK_TIME * 3.0, true), "desligada não dispara")
	_logic.set_powered(true)
	assert_almost_eq(_logic.lock_ratio(), 0.0, 0.0001, "religada começa sem trava")


func test_beam_shutdown_silences_and_wakes_up_alone() -> void:
	_run(Balance.CX2_LOCK_TIME * 0.5, true)
	assert_true(_logic.shutdown(Balance.BEAM_SHUTDOWN_TIME), "acordada desliga")
	assert_eq(_logic.phase(), Cx2Logic.Phase.SHUTDOWN, "desligada pelo feixe")
	assert_almost_eq(_logic.lock_ratio(), 0.0, 0.0001, "trava zerada")
	assert_false(_run(Balance.BEAM_SHUTDOWN_TIME - 0.5, true), "não dispara desligada")
	assert_true(_logic.is_shut_down(), "ainda desligada antes do fim")
	_run(0.6, false)
	assert_false(_logic.is_shut_down(), "volta sozinha")
	assert_eq(_logic.phase(), Cx2Logic.Phase.SCAN, "volta a varrer")


func test_beam_shutdown_extends_but_does_not_restart() -> void:
	assert_true(_logic.shutdown(2.0), "primeiro feixe")
	assert_false(_logic.shutdown(1.0), "segundo feixe não reanuncia")
	assert_almost_eq(_logic.shutdown_remaining(), 2.0, 0.0001, "fica o maior tempo")
	assert_false(_logic.shutdown(0.0), "duração nula ignorada")


func test_terminal_power_wins_over_the_beam_timer() -> void:
	_logic.shutdown(1.0)
	_logic.set_powered(false)
	assert_eq(_logic.phase(), Cx2Logic.Phase.OFF, "desligada pelo terminal tem prioridade")
	_run(1.5, true)
	assert_eq(_logic.phase(), Cx2Logic.Phase.OFF, "o fim do feixe não religa a torre")
	_logic.set_powered(true)
	assert_eq(_logic.phase(), Cx2Logic.Phase.SCAN, "religada pelo terminal varre")


func test_scan_frame_follows_the_sweep() -> void:
	var arc: float = Balance.CX2_SWEEP_ARC
	assert_eq(Cx2Logic.scan_frame(arc, arc, 4), 0, "giro horário: cabeça à esquerda")
	assert_eq(Cx2Logic.scan_frame(-arc, arc, 4), 3, "giro anti-horário: cabeça à direita")
	assert_eq(Cx2Logic.scan_frame(arc * 0.2, arc, 4), 1, "perto do centro, lado esquerdo")
	assert_eq(Cx2Logic.scan_frame(-arc * 0.2, arc, 4), 2, "perto do centro, lado direito")


func test_cone_polygon_follows_hit_distances() -> void:
	var distances := PackedFloat32Array([10.0, 20.0, 30.0])
	var points: PackedVector2Array = Cx2Logic.cone_polygon(Vector2.ZERO, 0.0, 10.0, distances)
	assert_eq(points.size(), 4, "origem + um ponto por raio")
	assert_almost_eq(points[2].length(), 20.0, 0.001, "raio do meio corta na parede")
	assert_almost_eq(points[2].angle(), 0.0, 0.001, "raio do meio na mira")


func test_scene_is_powered_and_turns_off() -> void:
	var node: Node = _instantiate()
	if node == null:
		return
	var tower: Cx2 = node
	assert_true(tower.is_in_group(&"powered"), "grupo powered")
	tower.configure({"mount": "wall_left", "terminal_id": "lab", "system_id": "towers"})
	assert_eq(tower.mount, Cx2Logic.MOUNT_WALL_LEFT, "montagem lida do JSON")
	assert_eq(tower.terminal_id, &"lab", "terminal lido do JSON")
	assert_almost_eq(tower.aim_angle(), 0.0, 0.001, "parede esquerda mira à direita")
	tower.set_powered_silent(false)
	assert_eq(tower.phase(), Cx2Logic.Phase.OFF, "desligada pelo terminal")
	assert_eq(tower.current_animation(), Cx2.ANIM_OFF, "quadro desligado")
	assert_false((tower.get_node("Cone") as Polygon2D).visible, "cone apagado")
	assert_false((tower.get_node("ConeLight") as PointLight2D).enabled, "luz apagada")
	tower.set_powered_silent(true)
	assert_eq(tower.phase(), Cx2Logic.Phase.SCAN, "religada varre")
	node.free()


func test_scene_is_a_beam_target_and_goes_dark() -> void:
	var node: Node = _instantiate()
	if node == null:
		return
	var tower: Cx2 = node
	assert_true(tower.is_in_group(BeamLogic.TARGET_GROUP), "grupo do feixe")
	var body: Node = tower.get_node("Mount/BeamBody")
	assert_eq(BeamLogic.resolve_target(body), tower, "o corpo do feixe leva à torre")
	tower.shutdown(Balance.BEAM_SHUTDOWN_TIME)
	assert_true(tower.is_shut_down(), "desligada pelo feixe")
	assert_eq(tower.current_animation(), Cx2.ANIM_OFF, "quadro desligado")
	assert_false((tower.get_node("Cone") as Polygon2D).visible, "cone apagado")
	assert_false((tower.get_node("ConeLight") as PointLight2D).enabled, "luz apagada")
	assert_true(tower.powered, "o terminal continua mandando energia")
	node.free()


func test_base_angle_overrides_the_mount() -> void:
	var node: Node = _instantiate()
	if node == null:
		return
	var tower: Cx2 = node
	tower.configure({"mount": "ceiling", "base_angle": 120.0})
	assert_almost_eq(tower.aim_angle(), 120.0, 0.001, "ângulo explícito")
	node.free()


func _run(duration: float, sees: bool) -> bool:
	var fired: bool = false
	for _index: int in range(roundi(duration / STEP)):
		if _logic.update(STEP, sees):
			fired = true
	return fired


func _instantiate() -> Node:
	var packed: PackedScene = load(CX2_SCENE)
	assert_not_null(packed, "cena da CX-2")
	if packed == null:
		return null
	var node: Node = packed.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(node)
	return node
