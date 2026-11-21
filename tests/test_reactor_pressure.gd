extends TestCase

const PHASE_MINUTES: Array[float] = [5.0, 10.0, 12.0, 12.0, 15.0, 8.0, 7.0]
const PHASE_RESTORES: Array[bool] = [false, true, true, true, true, true, false]
const SLOW_PACE: float = 1.5
const STEP_SECONDS: float = 1.0


func test_normal_pace_feels_the_clock_but_finishes() -> void:
	var run: Dictionary = _campaign(1.0, 1.0)
	var lowest: float = float(run["min"])
	assert_true(lowest < 80.0, "o Normal desce de 80%% em algum setor (%.1f)" % lowest)
	assert_true(float(run["min"]) > Balance.REACTOR_CRITICAL, "ritmo da GDD não entra em crítico")
	assert_true(float(run["end"]) < 90.0, "chega ao fim sem folga (%.1f)" % run["end"])


func test_slow_player_reaches_the_reactor_under_pressure() -> void:
	var run: Dictionary = _campaign(SLOW_PACE, 1.0)
	assert_true(float(run["end"]) > 0.0, "lento ainda termina no Normal")
	var ending: float = float(run["end"])
	assert_true(ending < 50.0, "lento chega ao Reator abaixo de 50%% (%.1f)" % ending)


func test_easy_keeps_slack_and_hard_squeezes() -> void:
	var easy: Dictionary = _campaign(1.0, Balance.difficulty_reactor_multiplier(&"easy"))
	var hard: Dictionary = _campaign(1.0, Balance.difficulty_reactor_multiplier(&"hard"))
	var normal: Dictionary = _campaign(1.0, 1.0)
	assert_true(float(easy["min"]) > float(normal["min"]), "fácil sobra mais que normal")
	assert_true(float(hard["min"]) < float(normal["min"]), "difícil aperta mais que normal")
	assert_true(float(hard["end"]) > 0.0, "difícil no ritmo da GDD ainda termina")


func test_no_timer_never_moves() -> void:
	var run: Dictionary = _campaign(SLOW_PACE, 0.0)
	assert_almost_eq(float(run["min"]), Balance.REACTOR_START, 0.0001, "sem timer não cai")


func _campaign(pace: float, multiplier: float) -> Dictionary:
	var percent: float = Balance.REACTOR_START
	var lowest: float = percent
	for index: int in range(PHASE_MINUTES.size()):
		var seconds: float = PHASE_MINUTES[index] * 60.0 * pace
		var elapsed: float = 0.0
		while elapsed < seconds:
			percent = ReactorClock.step(
				percent, STEP_SECONDS, Balance.REACTOR_DECAY_INTERVAL, multiplier
			)
			elapsed += STEP_SECONDS
		lowest = minf(lowest, percent)
		if PHASE_RESTORES[index]:
			percent = ReactorClock.apply_delta(
				percent, Balance.REACTOR_SECTOR_BONUS, Balance.REACTOR_START
			)
	return {"end": percent, "min": lowest}
