extends TestCase

const STEP: float = 0.5


func test_the_fight_waits_for_the_player() -> void:
	var logic := ArgosLogic.new()
	assert_eq(logic.state, ArgosLogic.State.IDLE, "nasce parado")
	assert_false(logic.tick(200.0), "parado não estoura")
	assert_almost_eq(logic.time_left, Balance.ARGOS_TIME, 0.001, "relógio cheio")
	assert_eq(logic.lit_segments(), Balance.ARGOS_SEGMENTS, "todas as lâmpadas acesas")
	assert_false(logic.overload(&"c1"), "acoplador antes da luta não conta")


func test_ninety_seconds_then_failure() -> void:
	var logic := ArgosLogic.new()
	assert_true(logic.start(), "começa")
	assert_false(logic.start(), "não começa duas vezes")
	var elapsed: float = 0.0
	var failed: bool = false
	while elapsed < Balance.ARGOS_TIME + 1.0 and not failed:
		failed = logic.tick(STEP)
		elapsed += STEP
	assert_true(failed, "o tempo acaba")
	assert_almost_eq(elapsed, Balance.ARGOS_TIME, STEP, "aos 90 s")
	assert_eq(logic.state, ArgosLogic.State.FAILED, "estado de falha")
	assert_false(logic.tick(STEP), "a falha avisa uma vez")
	assert_eq(logic.lit_segments(), 0, "lâmpadas apagadas")


func test_three_couplers_defeat_argos() -> void:
	var logic := ArgosLogic.new()
	logic.start()
	assert_eq(logic.phase(), 1, "fase 1")
	assert_true(logic.overload(&"c1"), "primeiro")
	assert_false(logic.overload(&"c1"), "o mesmo não conta duas vezes")
	assert_eq(logic.phase(), 2, "fase 2")
	assert_true(logic.overload(&"c2"), "segundo")
	assert_eq(logic.phase(), 3, "fase 3")
	assert_false(logic.is_defeated(), "ainda de pé com dois")
	assert_true(logic.overload(&"c3"), "terceiro")
	assert_true(logic.is_defeated(), "ARGOS cai no terceiro")
	assert_eq(logic.overloaded_count(), Balance.ARGOS_COUPLERS, "três queimados")
	assert_false(logic.tick(Balance.ARGOS_TIME * 2.0), "vencido não falha por tempo")


func test_reset_cleans_the_encounter_but_not_a_victory() -> void:
	var logic := ArgosLogic.new()
	logic.start()
	logic.overload(&"c1")
	logic.tick(40.0)
	assert_true(logic.fail(), "morreu na luta")
	logic.reset()
	assert_eq(logic.state, ArgosLogic.State.IDLE, "volta a esperar")
	assert_eq(logic.overloaded_count(), 0, "acopladores limpos")
	assert_almost_eq(logic.time_left, Balance.ARGOS_TIME, 0.001, "relógio cheio de novo")
	assert_eq(logic.phase(), 1, "fase 1 de novo")
	logic.start()
	for coupler: StringName in [&"a", &"b", &"c"]:
		logic.overload(coupler)
	logic.reset()
	assert_true(logic.is_defeated(), "vitória não volta atrás")


func test_each_coupler_speeds_up_the_reactor() -> void:
	var logic := ArgosLogic.new()
	logic.start()
	assert_almost_eq(logic.speed_scale(), 1.0, 0.001, "ritmo base")
	logic.overload(&"a")
	assert_almost_eq(logic.speed_scale(), 1.0 + Balance.ARGOS_PHASE_SPEEDUP, 0.001, "fase 2")
	logic.overload(&"b")
	assert_almost_eq(
		logic.speed_scale(), 1.0 + 2.0 * Balance.ARGOS_PHASE_SPEEDUP, 0.001, "fase 3"
	)


func test_one_segment_goes_dark_every_ten_seconds() -> void:
	var step: float = Balance.ARGOS_TIME / float(Balance.ARGOS_SEGMENTS)
	assert_eq(ArgosLogic.segments_for(Balance.ARGOS_TIME), Balance.ARGOS_SEGMENTS, "cheio")
	assert_eq(
		ArgosLogic.segments_for(Balance.ARGOS_TIME - step),
		Balance.ARGOS_SEGMENTS - 1,
		"10 s depois, uma a menos"
	)
	assert_eq(ArgosLogic.segments_for(step * 0.5), 1, "a última fica até o fim")
	assert_eq(ArgosLogic.segments_for(0.0), 0, "zero apaga tudo")


func test_the_alarm_hurries_at_the_end() -> void:
	assert_almost_eq(
		ArgosLogic.alarm_interval(Balance.ARGOS_TIME), Balance.ARGOS_ALARM_INTERVAL, 0.001, "calmo"
	)
	assert_almost_eq(
		ArgosLogic.alarm_interval(Balance.ARGOS_ALARM_FAST_TIME - 1.0),
		Balance.ARGOS_ALARM_FAST_INTERVAL,
		0.001,
		"acelera nos últimos 20 s"
	)


func test_lifts_rest_low_rise_rest_high_and_fall() -> void:
	var cycle: float = Balance.ARGOS_LIFT_CYCLE
	var hold: float = Balance.ARGOS_LIFT_HOLD
	assert_almost_eq(ArgosLogic.lift_ratio(0.0, 0.0), 0.0, 0.001, "começa embaixo")
	assert_almost_eq(ArgosLogic.lift_ratio(cycle * hold * 0.5, 0.0), 0.0, 0.001, "parada embaixo")
	assert_almost_eq(ArgosLogic.lift_ratio(cycle * 0.6, 0.0), 1.0, 0.001, "parada em cima")
	var rising: float = ArgosLogic.lift_ratio(cycle * (hold + 0.15), 0.0)
	assert_true(rising > 0.0 and rising < 1.0, "subindo no meio (%.2f)" % rising)
	assert_almost_eq(
		ArgosLogic.lift_ratio(cycle * 0.3, 0.0),
		ArgosLogic.lift_ratio(cycle * 1.3, 0.0),
		0.001,
		"ciclo se repete"
	)
	assert_almost_eq(
		ArgosLogic.lift_ratio(0.0, 0.5), ArgosLogic.lift_ratio(cycle * 0.5, 0.0), 0.001,
		"meio ciclo de defasagem"
	)
	for index: int in range(60):
		var ratio: float = ArgosLogic.lift_ratio(cycle * float(index) / 60.0, 0.0)
		assert_true(ratio >= 0.0 and ratio <= 1.0, "dentro do trilho em %d" % index)


func test_the_heat_clock_runs_faster_in_later_phases() -> void:
	var calm := ArgosLogic.new()
	var angry := ArgosLogic.new()
	angry.start()
	angry.overload(&"a")
	angry.overload(&"b")
	calm.tick(1.0)
	angry.tick(1.0)
	assert_true(angry.heat_clock > calm.heat_clock, "o calor acelera")
	assert_almost_eq(calm.heat_clock, 1.0, 0.001, "parado corre no ritmo base")
