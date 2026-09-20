extends TestCase

const STEP: float = 1.0 / 60.0


func test_scale_for_radius() -> void:
	assert_almost_eq(LightMath.scale_for_radius(48.0, 256.0), 0.375, 0.0001, "raio pequeno")
	assert_almost_eq(LightMath.scale_for_radius(128.0, 256.0), 1.0, 0.0001, "raio grande")
	assert_almost_eq(LightMath.scale_for_radius(48.0, 0.0), 0.0, 0.0001, "textura inválida")
	assert_almost_eq(LightMath.scale_for_radius(0.0, 256.0), 0.0, 0.0001, "raio zero")


func test_radius_for_scale_is_the_inverse() -> void:
	var scale_on: float = LightMath.scale_for_radius(Balance.VISION_RADIUS_ON, LightMath.TEXTURE_SIZE)
	assert_almost_eq(
		LightMath.radius_for_scale(scale_on, LightMath.TEXTURE_SIZE),
		Balance.VISION_RADIUS_ON,
		0.0001,
		"volta ao raio"
	)


func test_drain_for() -> void:
	assert_almost_eq(LightMath.drain_for(0.5, 1.0), 0.5, 0.0001, "meio segundo")
	assert_almost_eq(LightMath.drain_for(-1.0, 1.0), 0.0, 0.0001, "delta negativo")
	assert_almost_eq(LightMath.drain_for(0.5, 0.0), 0.0, 0.0001, "sem drenagem")


func test_drain_sums_one_charge_per_second() -> void:
	var total: float = 0.0
	for index: int in range(60):
		total += LightMath.drain_for(STEP, Balance.FLASHLIGHT_DRAIN)
	assert_almost_eq(total, 1.0, 0.001, "1 Carga por segundo")


func test_can_enable() -> void:
	assert_false(LightMath.can_enable(0.0, 1.0), "sem carga")
	assert_false(LightMath.can_enable(0.5, 1.0), "carga insuficiente")
	assert_true(LightMath.can_enable(5.0, 1.0), "carga suficiente")
	assert_true(LightMath.can_enable(1.0, 1.0), "carga exata")


func test_radius_constants_match_gdd() -> void:
	assert_almost_eq(Balance.VISION_RADIUS_OFF, 48.0, 0.0001, "visão sem lanterna")
	assert_almost_eq(Balance.VISION_RADIUS_ON, 128.0, 0.0001, "visão com lanterna")
	assert_almost_eq(Balance.FLASHLIGHT_DRAIN, 1.0, 0.0001, "drenagem da lanterna")


func test_light_fade_time_is_short() -> void:
	assert_true(Balance.LIGHT_FADE_TIME > 0.0, "fade positivo")
	assert_true(Balance.LIGHT_FADE_TIME < Balance.SCENE_FADE_TIME, "fade menor que o de cena")
