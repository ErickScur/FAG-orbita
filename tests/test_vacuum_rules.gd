extends TestCase


func test_thruster_is_an_ability() -> void:
	assert_true(VacuumRules.has_thruster([&"dash", &"thruster"]), "propulsor instalado")
	assert_false(VacuumRules.has_thruster([&"dash"]), "sem propulsor")


func test_double_jump_needs_the_thruster_and_air() -> void:
	assert_true(
		VacuumRules.can_double_jump(true, false, false, 0.0, false, false, 100.0, 15.0),
		"no ar, com propulsor e Carga"
	)
	assert_false(
		VacuumRules.can_double_jump(false, false, false, 0.0, false, false, 100.0, 15.0),
		"sem propulsor"
	)
	assert_false(
		VacuumRules.can_double_jump(true, false, true, 0.0, false, false, 100.0, 15.0),
		"no chão é pulo comum"
	)
	assert_false(
		VacuumRules.can_double_jump(true, false, false, 0.05, false, false, 100.0, 15.0),
		"dentro do coyote time é pulo comum"
	)


func test_double_jump_once_per_jump_and_costs_charge() -> void:
	assert_false(
		VacuumRules.can_double_jump(true, true, false, 0.0, false, false, 100.0, 15.0),
		"segundo pulo duplo no mesmo salto"
	)
	assert_false(
		VacuumRules.can_double_jump(true, false, false, 0.0, false, false, 14.0, 15.0),
		"Carga abaixo do custo"
	)
	assert_true(
		VacuumRules.can_double_jump(true, false, false, 0.0, false, false, 15.0, 15.0),
		"Carga igual ao custo"
	)


func test_discharge_and_claws_block_the_double_jump() -> void:
	assert_false(
		VacuumRules.can_double_jump(true, false, false, 0.0, false, true, 100.0, 15.0),
		"DESCARGA bloqueia o propulsor (GDD-2.6.2-F)"
	)
	assert_false(
		VacuumRules.can_double_jump(true, false, false, 0.0, true, false, 100.0, 15.0),
		"agarrado na parede pula da parede"
	)


func test_push_without_arrows_goes_away_from_the_surface() -> void:
	assert_eq(VacuumRules.push_direction(Vector2.ZERO, Vector2.UP), Vector2.UP, "do piso, para cima")
	assert_eq(
		VacuumRules.push_direction(Vector2.ZERO, Vector2.LEFT), Vector2.LEFT, "da parede direita"
	)
	assert_eq(
		VacuumRules.push_direction(Vector2.ZERO, Vector2.DOWN), Vector2.DOWN, "do teto, para baixo"
	)


func test_push_along_the_floor_leaves_it_diagonally() -> void:
	var direction: Vector2 = VacuumRules.push_direction(Vector2.RIGHT, Vector2.UP)
	assert_almost_eq(direction.x, sqrt(0.5), 0.001, "metade para a direita")
	assert_almost_eq(direction.y, -sqrt(0.5), 0.001, "metade para longe do piso")


func test_push_from_a_wall_can_slide_along_it() -> void:
	assert_eq(
		VacuumRules.push_direction(Vector2.UP, Vector2.LEFT), Vector2.UP, "sobe rente à parede"
	)
	assert_eq(
		VacuumRules.push_direction(Vector2.RIGHT, Vector2.DOWN),
		Vector2.RIGHT,
		"desliza pelo teto"
	)
	assert_eq(
		VacuumRules.push_direction(Vector2.RIGHT, Vector2.LEFT),
		Vector2.LEFT,
		"seta para dentro da parede vira afastar"
	)
	var corner: Vector2 = VacuumRules.push_direction(Vector2(1, -1), Vector2.LEFT)
	assert_eq(corner, Vector2.UP, "diagonal contra a parede vira só a componente livre")


func test_push_into_the_surface_is_folded_out() -> void:
	assert_eq(
		VacuumRules.push_direction(Vector2.DOWN, Vector2.UP), Vector2.UP, "seta para dentro do piso"
	)
	var folded: Vector2 = VacuumRules.push_direction(Vector2(1, 1), Vector2.UP)
	assert_true(folded.y < 0.0, "baixo+direita no piso ainda sai do piso")
	assert_true(folded.x > 0.0, "e mantém a direita")


func test_push_with_arrows_follows_them() -> void:
	var direction: Vector2 = VacuumRules.push_direction(Vector2(1, -1), Vector2.UP)
	assert_almost_eq(direction.angle(), Vector2(1, -1).angle(), 0.001, "diagonal pedida")
	assert_almost_eq(
		VacuumRules.push_velocity(Vector2.UP, Vector2.UP, Balance.VACUUM_PUSH_SPEED).length(),
		Balance.VACUUM_PUSH_SPEED,
		0.001,
		"impulso com a velocidade do Balance"
	)


func test_drift_keeps_velocity_but_has_a_ceiling() -> void:
	var slow := Vector2(60.0, -30.0)
	assert_eq(VacuumRules.clamp_drift(slow, Balance.VACUUM_MAX_SPEED), slow, "abaixo do teto")
	var fast := Vector2(400.0, 0.0)
	assert_almost_eq(
		VacuumRules.clamp_drift(fast, Balance.VACUUM_MAX_SPEED).length(),
		Balance.VACUUM_MAX_SPEED,
		0.001,
		"queda rápida entra no vácuo no teto"
	)


func test_thrust_steers_toward_the_input() -> void:
	var start := Vector2(100.0, 0.0)
	var next: Vector2 = VacuumRules.thrust(start, Vector2.UP, 0.1, 320.0, 120.0)
	assert_true(next.y < 0.0, "ganha subida")
	assert_true(next.x < start.x, "freia a deriva lateral")
	var settled: Vector2 = start
	for step: int in range(120):
		settled = VacuumRules.thrust(settled, Vector2.UP, 1.0 / 60.0, 320.0, 120.0)
	assert_almost_eq(settled.x, 0.0, 0.001, "acaba só na direção pedida")
	assert_almost_eq(settled.y, -120.0, 0.001, "na velocidade do propulsor")


func test_no_input_means_pure_drift() -> void:
	var start := Vector2(40.0, 20.0)
	assert_eq(VacuumRules.thrust(start, Vector2.ZERO, 0.5, 320.0, 120.0), start, "deriva")
	assert_false(VacuumRules.can_thrust(true, false, 100.0, Vector2.ZERO), "sem seta não gasta")
	assert_false(VacuumRules.can_thrust(false, false, 100.0, Vector2.UP), "sem propulsor")
	assert_false(VacuumRules.can_thrust(true, true, 100.0, Vector2.UP), "DESCARGA")
	assert_false(VacuumRules.can_thrust(true, false, 0.0, Vector2.UP), "sem Carga")
	assert_true(VacuumRules.can_thrust(true, false, 1.0, Vector2.UP), "com Carga")


func test_thrust_cost_scales_with_time() -> void:
	assert_almost_eq(VacuumRules.thrust_cost(0.5, Balance.THRUSTER_DRAIN), 3.0, 0.001, "6/s")
	assert_almost_eq(VacuumRules.thrust_cost(-1.0, 6.0), 0.0, 0.001, "delta negativo")


func test_a_long_crossing_is_survivable_but_hurts() -> void:
	var damage: float = VacuumRules.crossing_damage(
		20.0 * Balance.TILE_SIZE, Balance.VACUUM_PUSH_SPEED, Balance.VACUUM_DPS
	)
	assert_true(damage > 10.0, "20 tiles à deriva custam mais que um toque de SR-3")
	assert_true(damage < float(Balance.INTEGRITY_MAX) * 0.25, "e menos de uma célula")


func test_only_drifting_into_a_surface_anchors() -> void:
	assert_true(VacuumRules.hits_surface(Vector2(0, -100), Vector2.DOWN), "bate no teto")
	assert_true(VacuumRules.hits_surface(Vector2(70, -70), Vector2.LEFT), "bate na parede")
	assert_false(VacuumRules.hits_surface(Vector2(100, 0), Vector2.DOWN), "desliza rente ao teto")
	assert_false(VacuumRules.hits_surface(Vector2.ZERO, Vector2.LEFT), "parado não ancora de novo")
