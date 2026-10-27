extends TestCase

const V9_SCENE: String = "res://scenes/enemies/v9.tscn"
const STEP: float = 1.0 / 60.0

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_vision_depends_on_light() -> void:
	assert_true(V9Logic.sees(Balance.V9_VISION_RANGE, true, true), "iluminado: 96 px")
	assert_false(V9Logic.sees(Balance.V9_VISION_RANGE + 1.0, true, true), "além de 96 px")
	assert_false(V9Logic.sees(40.0, false, true), "no escuro a 40 px não vê")
	assert_true(V9Logic.sees(Balance.V9_DARK_VISION, false, true), "no escuro só de perto")
	assert_false(V9Logic.sees(10.0, true, false), "parede corta a visão")


func test_dash_is_heard_within_the_radius() -> void:
	assert_true(V9Logic.hears(Balance.V9_HEAR_RADIUS, true), "dash a 128 px")
	assert_false(V9Logic.hears(Balance.V9_HEAR_RADIUS + 1.0, true), "dash longe")
	assert_false(V9Logic.hears(10.0, false), "andando não faz barulho")


func test_detection_warns_before_chasing() -> void:
	var logic := V9Logic.new()
	assert_eq(logic.state(), V9Logic.State.PATROL, "começa patrulhando")
	assert_eq(logic.update(STEP, false, false, false), V9Logic.EVENT_NONE, "nada visto")
	assert_eq(logic.update(STEP, true, false, false), V9Logic.EVENT_ALERTED, "viu: alerta")
	assert_eq(logic.state(), V9Logic.State.ALERT, "parada no alerta")
	_run(logic, Balance.V9_ALERT_TIME - 0.05, false, false, false)
	assert_eq(logic.state(), V9Logic.State.ALERT, "o alerta dura o tempo de leitura")
	var event: StringName = logic.update(STEP, false, false, true)
	assert_ne(event, V9Logic.EVENT_LATCHED, "não gruda no alerta")
	_run(logic, 0.1, false, false, false)
	assert_eq(logic.state(), V9Logic.State.CHASE, "depois do aviso persegue")


func test_dash_noise_also_alerts() -> void:
	var logic := V9Logic.new()
	assert_eq(logic.update(STEP, false, true, false), V9Logic.EVENT_ALERTED, "ouviu o dash")


func test_chase_ends_when_the_target_is_lost() -> void:
	var logic: V9Logic = _chasing()
	_run(logic, Balance.V9_LOSE_TIME * 0.5, false, false, false)
	assert_eq(logic.state(), V9Logic.State.CHASE, "meio segundo no escuro ainda persegue")
	logic.update(STEP, true, false, false)
	_run(logic, Balance.V9_LOSE_TIME - 0.05, false, false, false)
	assert_eq(logic.state(), V9Logic.State.CHASE, "ver de novo zera a contagem")
	_run(logic, 0.1, false, false, false)
	assert_eq(logic.state(), V9Logic.State.PATROL, "1 s sem ver: volta ao trilho")


func test_chase_gives_up_after_the_limit() -> void:
	var logic: V9Logic = _chasing()
	_run(logic, Balance.V9_CHASE_TIME - 0.1, true, false, false)
	assert_eq(logic.state(), V9Logic.State.CHASE, "ainda dentro dos 8 s")
	_run(logic, 0.2, true, false, false)
	assert_eq(logic.state(), V9Logic.State.COOLDOWN, "8 s: desiste e descansa")
	_run(logic, Balance.V9_COOLDOWN - 0.3, true, false, false)
	assert_eq(logic.state(), V9Logic.State.COOLDOWN, "no descanso não vê ninguém")
	_run(logic, 0.4, false, false, false)
	assert_eq(logic.state(), V9Logic.State.PATROL, "volta a patrulhar")


func test_latch_holds_then_releases_into_cooldown() -> void:
	var logic: V9Logic = _chasing()
	assert_eq(logic.update(STEP, true, false, true), V9Logic.EVENT_LATCHED, "contato gruda")
	assert_true(logic.is_latched(), "grudada")
	_run(logic, Balance.V9_LATCH_TIME - 0.05, true, false, true)
	assert_true(logic.is_latched(), "fica 1,5 s")
	var released: bool = false
	for _index: int in range(10):
		released = released or logic.update(STEP, true, false, true) == V9Logic.EVENT_RELEASED
	assert_true(released, "solta")
	assert_eq(logic.state(), V9Logic.State.COOLDOWN, "espera antes de grudar de novo")
	logic.update(STEP, true, false, true)
	assert_false(logic.is_latched(), "no descanso o contato não gruda")


func test_latch_drain_never_goes_negative() -> void:
	assert_almost_eq(V9Logic.latch_drain(1.0, 100.0), Balance.V9_LATCH_DRAIN, 0.001, "10/s")
	assert_almost_eq(V9Logic.latch_drain(1.0, 3.0), 3.0, 0.001, "só o que resta")
	assert_almost_eq(V9Logic.latch_drain(1.0, 0.0), 0.0, 0.001, "sem Carga, nada")
	var total: float = Balance.V9_LATCH_DRAIN * Balance.V9_LATCH_TIME
	assert_almost_eq(total, 15.0, 0.001, "um agarrão custa 15 de Carga")


func test_beam_shutdown_and_terminal_power() -> void:
	var logic: V9Logic = _chasing()
	logic.update(STEP, true, false, true)
	assert_true(logic.shutdown(Balance.BEAM_SHUTDOWN_TIME), "feixe desliga")
	assert_eq(logic.state(), V9Logic.State.SHUTDOWN, "caída")
	assert_false(logic.is_latched(), "solta o MU-7")
	assert_true(logic.is_grounded(), "no chão")
	_run(logic, Balance.BEAM_SHUTDOWN_TIME - 0.1, true, false, true)
	assert_eq(logic.state(), V9Logic.State.SHUTDOWN, "inerte enquanto dura")
	_run(logic, 0.2, false, false, false)
	assert_eq(logic.state(), V9Logic.State.PATROL, "acorda e volta ao trilho")
	logic.set_powered(false)
	assert_eq(logic.state(), V9Logic.State.OFF, "terminal desliga")
	assert_eq(logic.update(STEP, true, true, true), V9Logic.EVENT_NONE, "desligada não reage")
	assert_false(logic.shutdown(1.0), "feixe numa V-9 desligada não faz nada")
	logic.set_powered(true)
	assert_eq(logic.state(), V9Logic.State.PATROL, "religada patrulha")


func test_light_exposure_counts_flashlight_and_lit_lamps() -> void:
	var lamps: Array = [LightExposure.lamp(Vector2(100.0, 0.0), 48.0)]
	assert_true(LightExposure.is_lit(Vector2.ZERO, true, []), "lanterna acesa")
	assert_false(LightExposure.is_lit(Vector2.ZERO, false, lamps), "longe da lâmpada")
	assert_true(LightExposure.is_lit(Vector2(60.0, 0.0), false, lamps), "dentro do raio")
	assert_eq(LightExposure.lamps_reaching(Vector2(60.0, 0.0), lamps).size(), 1, "uma lâmpada")
	var dead: Array = [LightExposure.lamp(Vector2.ZERO, 0.0)]
	assert_false(LightExposure.is_lit(Vector2.ZERO, false, dead), "raio zero não ilumina")


func test_v9_scene_is_a_beam_target_on_the_enemy_layer() -> void:
	var v9: V9 = _add_v9({"path": [[0, 0], [4, 0]], "terminal_id": "x", "system_id": "y"})
	assert_true(v9.is_in_group(&"beam_target"), "alvo do feixe")
	assert_true(v9.is_in_group(&"powered"), "responde ao terminal")
	assert_eq(v9.terminal_id, &"x", "terminal do JSON")
	var body: StaticBody2D = v9.get_node("BeamBody")
	assert_eq(body.collision_layer, 4, "corpo na camada inimigo para o raio do feixe")
	assert_eq(BeamLogic.resolve_target(body), v9, "o feixe acha a V-9 pelo corpo")
	var lights: int = 0
	for child: Node in v9.get_children():
		if child is PointLight2D:
			lights += 1
	assert_eq(lights, 1, "uma luz só, a lente")


func test_v9_scene_powers_down_and_wakes() -> void:
	var v9: V9 = _add_v9({})
	assert_true(v9.lens_enabled(), "lente acesa patrulhando")
	assert_eq(v9.current_animation(), V9.ANIM_PATROL, "anima a patrulha")
	v9.set_powered_silent(false)
	assert_false(v9.lens_enabled(), "desligada apaga")
	assert_eq(v9.current_animation(), V9.ANIM_OFF, "quadro desligado")
	v9.set_powered_silent(true)
	v9.shutdown(Balance.BEAM_SHUTDOWN_TIME)
	assert_true(v9.is_shut_down(), "feixe derruba")
	assert_eq(v9.current_animation(), V9.ANIM_OFF, "caída")


func test_v9_follows_its_track_in_tiles() -> void:
	var v9: V9 = _add_v9({"path": [[0, 0], [3, 0]]})
	var start: Vector2 = v9.position
	v9._fly_track(1.0)
	assert_almost_eq(v9.position.x - start.x, Balance.V9_PATROL_SPEED, 0.01, "30 px/s no trilho")


func _chasing() -> V9Logic:
	var logic := V9Logic.new()
	logic.update(STEP, true, false, false)
	_run(logic, Balance.V9_ALERT_TIME + 0.05, true, false, false)
	assert_eq(logic.state(), V9Logic.State.CHASE, "preparação: perseguindo")
	return logic


func _run(logic: V9Logic, seconds: float, sees: bool, heard: bool, touching: bool) -> void:
	var elapsed: float = 0.0
	while elapsed < seconds:
		logic.update(STEP, sees, heard, touching)
		elapsed += STEP


func _add_v9(params: Dictionary) -> V9:
	var v9: V9 = load(V9_SCENE).instantiate()
	v9.position = Vector2(400.0, -4000.0)
	v9.configure(params)
	(Engine.get_main_loop() as SceneTree).root.add_child(v9)
	v9.set_physics_process(false)
	_nodes.append(v9)
	return v9
