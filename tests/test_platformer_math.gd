extends TestCase

const STEP: float = 1.0 / 60.0


func test_jump_velocity_is_negative_sqrt() -> void:
	assert_almost_eq(PlatformerMath.jump_velocity(40.0, 980.0), -280.0, 0.01, "v0")


func test_jump_velocity_rejects_invalid() -> void:
	assert_almost_eq(PlatformerMath.jump_velocity(0.0, 980.0), 0.0, 0.0001, "altura zero")
	assert_almost_eq(PlatformerMath.jump_velocity(40.0, 0.0), 0.0, 0.0001, "gravidade zero")


func test_jump_velocity_compensates_the_physics_step() -> void:
	var raw: float = PlatformerMath.jump_velocity(Balance.JUMP_HEIGHT, Balance.GRAVITY)
	var stepped: float = PlatformerMath.jump_velocity(
		Balance.JUMP_HEIGHT, Balance.GRAVITY, STEP
	)
	assert_almost_eq(stepped, raw + Balance.GRAVITY * STEP * 0.5, 0.0001, "meia gravidade")


func test_short_jump_cannot_climb_two_tiles() -> void:
	var initial: float = PlatformerMath.jump_velocity(
		Balance.JUMP_HEIGHT, Balance.GRAVITY, STEP
	)
	var tapped: float = PlatformerMath.apply_jump_cut(
		initial + Balance.GRAVITY * STEP, Balance.JUMP_CUT_MULTIPLIER
	)
	var peak: float = initial * STEP * -1.0 + PlatformerMath.simulate_jump_peak(
		tapped, Balance.GRAVITY, STEP, Balance.MAX_FALL_SPEED
	)
	assert_true(peak < float(Balance.TILE_SIZE * 2), "toque não vence 2 tiles (%.1f px)" % peak)


func test_full_jump_clears_two_tiles() -> void:
	var initial: float = PlatformerMath.jump_velocity(
		Balance.JUMP_HEIGHT, Balance.GRAVITY, STEP
	)
	var peak: float = PlatformerMath.simulate_jump_peak(
		initial, Balance.GRAVITY, STEP, Balance.MAX_FALL_SPEED
	)
	assert_true(peak > float(Balance.TILE_SIZE * 2), "pulo cheio vence 2 tiles (%.1f px)" % peak)


func test_jump_velocity_derived_from_balance() -> void:
	var expected: float = -sqrt(2.0 * Balance.GRAVITY * Balance.JUMP_HEIGHT)
	var actual: float = PlatformerMath.jump_velocity(Balance.JUMP_HEIGHT, Balance.GRAVITY)
	assert_almost_eq(actual, expected, 0.0001, "derivada do Balance")


func test_jump_peak_matches_balance() -> void:
	var initial: float = PlatformerMath.jump_velocity(
		Balance.JUMP_HEIGHT, Balance.GRAVITY, STEP
	)
	var peak: float = PlatformerMath.simulate_jump_peak(
		initial, Balance.GRAVITY, STEP, Balance.MAX_FALL_SPEED
	)
	assert_almost_eq(peak, Balance.JUMP_HEIGHT, 2.0, "pico do pulo completo")


func test_cut_jump_peak_is_much_lower() -> void:
	var initial: float = PlatformerMath.jump_velocity(
		Balance.JUMP_HEIGHT, Balance.GRAVITY, STEP
	)
	var cut: float = PlatformerMath.apply_jump_cut(initial, Balance.JUMP_CUT_MULTIPLIER)
	var peak: float = PlatformerMath.simulate_jump_peak(
		cut, Balance.GRAVITY, STEP, Balance.MAX_FALL_SPEED
	)
	assert_true(peak < Balance.JUMP_HEIGHT * 0.5, "pulo cortado deve ficar abaixo da metade")
	assert_true(peak > 0.0, "pulo cortado ainda sobe")


func test_jump_cut_only_when_rising() -> void:
	assert_almost_eq(PlatformerMath.apply_jump_cut(-200.0, 0.5), -100.0, 0.0001, "subindo")
	assert_almost_eq(PlatformerMath.apply_jump_cut(50.0, 0.5), 50.0, 0.0001, "caindo")
	assert_almost_eq(PlatformerMath.apply_jump_cut(0.0, 0.5), 0.0, 0.0001, "parado")


func test_clamp_fall() -> void:
	assert_almost_eq(PlatformerMath.clamp_fall(900.0, 400.0), 400.0, 0.0001, "queda limitada")
	assert_almost_eq(PlatformerMath.clamp_fall(-300.0, 400.0), -300.0, 0.0001, "subida livre")
	assert_almost_eq(PlatformerMath.clamp_fall(900.0, 0.0), 900.0, 0.0001, "sem limite")


func test_approach_does_not_overshoot() -> void:
	assert_almost_eq(PlatformerMath.approach(100.0, 110.0, 50.0), 110.0, 0.0001, "alvo positivo")
	assert_almost_eq(PlatformerMath.approach(0.0, -110.0, 30.0), -30.0, 0.0001, "alvo negativo")
	assert_almost_eq(PlatformerMath.approach(10.0, 10.0, 5.0), 10.0, 0.0001, "já no alvo")
	assert_almost_eq(PlatformerMath.approach(10.0, 0.0, 0.0), 10.0, 0.0001, "sem passo")


func test_walk_speed_reached_within_budget() -> void:
	var speed: float = 0.0
	var frames: int = 0
	while speed < Balance.WALK_SPEED and frames < 600:
		speed = PlatformerMath.approach(
			speed, Balance.WALK_SPEED, Balance.WALK_ACCEL * STEP
		)
		frames += 1
	assert_almost_eq(speed, Balance.WALK_SPEED, 1.0, "velocidade final")
	assert_true(float(frames) * STEP <= 0.15, "aceleração em até 0,15 s (%d frames)" % frames)


func test_walk_stops_within_budget() -> void:
	var speed: float = Balance.WALK_SPEED
	var frames: int = 0
	while speed > 0.0 and frames < 600:
		speed = PlatformerMath.approach(speed, 0.0, Balance.WALK_DECEL * STEP)
		frames += 1
	assert_almost_eq(speed, 0.0, 0.0001, "velocidade final")
	assert_true(float(frames) * STEP <= 0.12, "freio em até 0,12 s (%d frames)" % frames)
