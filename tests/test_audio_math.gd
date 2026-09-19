extends TestCase


func test_silence_returns_silent_db() -> void:
	assert_almost_eq(AudioMath.linear_to_db_safe(0.0), AudioMath.SILENT_DB, 0.0001, "zero")
	assert_almost_eq(AudioMath.linear_to_db_safe(-1.0), AudioMath.SILENT_DB, 0.0001, "negativo")
	assert_almost_eq(AudioMath.linear_to_db_safe(0.0005), AudioMath.SILENT_DB, 0.0001, "quase zero")


func test_full_volume_is_zero_db() -> void:
	assert_almost_eq(AudioMath.linear_to_db_safe(1.0), 0.0, 0.0001, "cheio")


func test_above_one_is_clamped() -> void:
	assert_almost_eq(AudioMath.linear_to_db_safe(4.0), 0.0, 0.0001, "acima do máximo")


func test_half_volume_is_about_minus_six_db() -> void:
	assert_almost_eq(AudioMath.linear_to_db_safe(0.5), -6.0206, 0.05, "metade")


func test_round_trip_back_to_linear() -> void:
	assert_almost_eq(AudioMath.db_to_linear_safe(AudioMath.linear_to_db_safe(0.8)), 0.8, 0.001, "0.8")
	assert_almost_eq(AudioMath.db_to_linear_safe(AudioMath.SILENT_DB), 0.0, 0.0001, "mudo")


func test_is_silent() -> void:
	assert_true(AudioMath.is_silent(0.0), "zero")
	assert_true(AudioMath.is_silent(0.0009), "quase zero")
	assert_false(AudioMath.is_silent(0.01), "audível")
