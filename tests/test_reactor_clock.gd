extends TestCase


func test_decay_normal_90s() -> void:
	var result: float = ReactorClock.step(100.0, 90.0, 90.0, 1.0)
	assert_almost_eq(result, 99.0, 0.0001, "1% a cada 90 s")


func test_decay_multipliers() -> void:
	assert_almost_eq(ReactorClock.step(100.0, 90.0, 90.0, 0.5), 99.5, 0.0001, "fácil")
	assert_almost_eq(ReactorClock.step(100.0, 90.0, 90.0, 1.5), 98.5, 0.0001, "difícil")
	assert_almost_eq(ReactorClock.step(100.0, 90.0, 90.0, 0.0), 100.0, 0.0001, "sem timer")


func test_decay_per_second_guards_interval() -> void:
	assert_almost_eq(ReactorClock.decay_per_second(0.0, 1.0), 0.0, 0.0001, "intervalo zero")
	assert_almost_eq(ReactorClock.decay_per_second(-5.0, 1.0), 0.0, 0.0001, "intervalo negativo")
	assert_almost_eq(ReactorClock.decay_per_second(90.0, 1.0), 1.0 / 90.0, 0.00001, "normal")


func test_step_never_negative() -> void:
	assert_almost_eq(ReactorClock.step(0.2, 90.0, 90.0, 1.0), 0.0, 0.0001, "piso zero")


func test_bonus_caps_at_start() -> void:
	assert_almost_eq(ReactorClock.apply_delta(95.0, 15.0, 100.0), 100.0, 0.0001, "teto")


func test_penalty() -> void:
	assert_almost_eq(ReactorClock.apply_delta(10.0, -3.0, 100.0), 7.0, 0.0001, "morte")
	assert_almost_eq(ReactorClock.apply_delta(2.0, -3.0, 100.0), 0.0, 0.0001, "piso")


func test_critical_threshold() -> void:
	assert_true(ReactorClock.is_critical(24.99, Balance.REACTOR_CRITICAL), "abaixo de 25")
	assert_false(ReactorClock.is_critical(25.0, Balance.REACTOR_CRITICAL), "exatamente 25")


func test_display_ceil() -> void:
	assert_eq(ReactorClock.display_percent(74.2), 75, "74,2 mostra 75")
	assert_eq(ReactorClock.display_percent(0.4), 1, "0,4 mostra 1")
	assert_eq(ReactorClock.display_percent(0.0), 0, "zero mostra 0")
	assert_eq(ReactorClock.display_percent(100.0), 100, "cheio")


func test_bar_ratio() -> void:
	assert_almost_eq(ReactorClock.bar_ratio(50.0, 100.0), 0.5, 0.0001, "metade")
	assert_almost_eq(ReactorClock.bar_ratio(50.0, 0.0), 0.0, 0.0001, "cap zero")


func test_frame_by_frame_matches_bulk() -> void:
	var percent: float = Balance.REACTOR_START
	var delta: float = 1.0 / 60.0
	for frame: int in range(5400):
		percent = ReactorClock.step(percent, delta, Balance.REACTOR_DECAY_INTERVAL, 1.0)
	var bulk: float = ReactorClock.step(
		Balance.REACTOR_START, 90.0, Balance.REACTOR_DECAY_INTERVAL, 1.0
	)
	assert_almost_eq(percent, bulk, 0.001, "acumulado bate com passo único")
