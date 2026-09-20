extends TestCase


func test_amplitude_keeps_the_strongest_request() -> void:
	assert_almost_eq(ScreenShake.amplitude_for(2.0, 4.0), 4.0, 0.0001, "mais forte vence")
	assert_almost_eq(ScreenShake.amplitude_for(4.0, 2.0), 4.0, 0.0001, "mais fraco não reduz")
	assert_almost_eq(ScreenShake.amplitude_for(0.0, -3.0), 0.0, 0.0001, "negativo vira zero")


func test_remaining_never_goes_below_zero() -> void:
	assert_almost_eq(ScreenShake.remaining_after(0.2, 0.05), 0.15, 0.0001, "desconta")
	assert_almost_eq(ScreenShake.remaining_after(0.02, 0.5), 0.0, 0.0001, "trava em zero")


func test_falloff_is_quadratic() -> void:
	assert_almost_eq(ScreenShake.falloff(0.25, 0.25), 1.0, 0.0001, "início")
	assert_almost_eq(ScreenShake.falloff(0.125, 0.25), 0.25, 0.0001, "metade")
	assert_almost_eq(ScreenShake.falloff(0.0, 0.25), 0.0, 0.0001, "fim")
	assert_almost_eq(ScreenShake.falloff(0.1, 0.0), 0.0, 0.0001, "duração nula")


func test_offset_is_zero_when_the_shake_ended() -> void:
	assert_eq(
		ScreenShake.offset(4.0, 0.0, 0.25, 0.0, 24.0), Vector2.ZERO, "sem tempo restante"
	)
	assert_eq(ScreenShake.offset(0.0, 0.25, 0.25, 0.0, 24.0), Vector2.ZERO, "sem amplitude")


func test_offset_stays_inside_the_amplitude_and_on_whole_pixels() -> void:
	var elapsed: float = 0.0
	while elapsed < 0.25:
		var value: Vector2 = ScreenShake.offset(4.0, 0.25 - elapsed, 0.25, elapsed, 24.0)
		assert_true(absf(value.x) <= 4.0, "x dentro da amplitude")
		assert_true(absf(value.y) <= 4.0, "y dentro da amplitude")
		assert_almost_eq(value.x, roundf(value.x), 0.0001, "x inteiro")
		assert_almost_eq(value.y, roundf(value.y), 0.0001, "y inteiro")
		elapsed += 1.0 / 60.0


func test_land_amplitude_needs_a_hard_fall() -> void:
	assert_almost_eq(ScreenShake.land_amplitude(100.0, 260.0, 2.0), 0.0, 0.0001, "queda curta")
	assert_almost_eq(ScreenShake.land_amplitude(260.0, 260.0, 2.0), 2.0, 0.0001, "no limite")
	assert_almost_eq(ScreenShake.land_amplitude(400.0, 260.0, 2.0), 2.0, 0.0001, "queda alta")
