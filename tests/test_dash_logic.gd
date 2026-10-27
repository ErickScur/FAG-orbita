extends TestCase


func test_can_use_with_charge_and_no_cooldown() -> void:
	assert_true(DashLogic.can_use(100.0, 20.0, 0.0, false), "Carga cheia, sem recarga")


func test_blocked_by_cooldown() -> void:
	assert_false(DashLogic.can_use(100.0, 20.0, 0.5, false), "recarga em curso")


func test_blocked_by_low_charge() -> void:
	assert_false(DashLogic.can_use(10.0, 20.0, 0.0, false), "Carga abaixo do custo")


func test_blocked_by_status() -> void:
	assert_false(DashLogic.can_use(100.0, 20.0, 0.0, true), "DESCARGA bloqueia")


func test_exact_charge_is_enough() -> void:
	assert_true(DashLogic.can_use(20.0, 20.0, 0.0, false), "Carga igual ao custo")


func test_dash_velocity_follows_facing() -> void:
	assert_eq(DashLogic.dash_velocity(-1, 320.0), Vector2(-320.0, 0.0), "para a esquerda")
	assert_eq(DashLogic.dash_velocity(1, 320.0), Vector2(320.0, 0.0), "para a direita")
	assert_eq(DashLogic.dash_velocity(0, 320.0), Vector2(320.0, 0.0), "olhar neutro vai à direita")


func test_dash_has_no_vertical_component() -> void:
	assert_almost_eq(DashLogic.dash_velocity(1, Balance.DASH_SPEED).y, 0.0, 0.0001, "sem gravidade")


func test_air_dash_only_once_per_jump() -> void:
	assert_true(DashLogic.can_dash_now(true, true), "no chão sempre pode")
	assert_true(DashLogic.can_dash_now(false, false), "primeiro dash no ar")
	assert_false(DashLogic.can_dash_now(false, true), "segundo dash no mesmo salto")


func test_tick_counts_down_and_stops_at_zero() -> void:
	assert_almost_eq(DashLogic.tick(0.25, 0.1), 0.15, 0.0001, "desconta o quadro")
	assert_almost_eq(DashLogic.tick(0.05, 0.1), 0.0, 0.0001, "não fica negativo")
	assert_almost_eq(DashLogic.tick(0.25, -1.0), 0.25, 0.0001, "delta negativo não recarrega")


func test_dash_lasts_the_balance_time_at_60_hz() -> void:
	var step: float = 1.0 / 60.0
	var left: float = Balance.DASH_TIME
	var frames: int = 0
	while left > 0.0 and frames < 100:
		left = DashLogic.tick(left, step)
		frames += 1
	assert_eq(frames, DashLogic.frames(Balance.DASH_TIME, step), "jogo e simulação iguais")
	assert_eq(frames, 15, "0,25 s a 60 Hz")


func test_exit_speed_returns_to_walking() -> void:
	assert_almost_eq(DashLogic.exit_speed(320.0, 110.0), 110.0, 0.0001, "para a direita")
	assert_almost_eq(DashLogic.exit_speed(-320.0, 110.0), -110.0, 0.0001, "para a esquerda")
	assert_almost_eq(DashLogic.exit_speed(0.0, 110.0), 0.0, 0.0001, "parado contra a parede")


func test_ground_dash_covers_five_tiles() -> void:
	var reach: float = DashLogic.distance(Balance.DASH_SPEED, Balance.DASH_TIME)
	assert_almost_eq(reach, 5.0 * Balance.TILE_SIZE, 0.001, "320 px/s por 0,25 s = 80 px")


func test_ability_lookup() -> void:
	assert_true(DashLogic.has_ability([&"dash"]), "lista com dash")
	assert_false(DashLogic.has_ability([&"magnetic_claws"]), "lista sem dash")
