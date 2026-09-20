extends TestCase


func test_turns_at_ledge() -> void:
	assert_true(Sr3Logic.should_turn(false, false), "sem chão à frente")


func test_turns_at_wall() -> void:
	assert_true(Sr3Logic.should_turn(true, true), "parede à frente")


func test_keeps_walking_with_floor_and_no_wall() -> void:
	assert_false(Sr3Logic.should_turn(true, false), "caminho livre")


func test_flip_inverts_direction() -> void:
	assert_eq(Sr3Logic.flip(Sr3Logic.RIGHT), Sr3Logic.LEFT, "direita vira esquerda")
	assert_eq(Sr3Logic.flip(Sr3Logic.LEFT), Sr3Logic.RIGHT, "esquerda vira direita")
	assert_eq(Sr3Logic.flip(0), Sr3Logic.LEFT, "zero conta como direita")


func test_normalize_direction() -> void:
	assert_eq(Sr3Logic.normalize_direction(3), Sr3Logic.RIGHT, "positivo")
	assert_eq(Sr3Logic.normalize_direction(-3), Sr3Logic.LEFT, "negativo")
	assert_eq(Sr3Logic.normalize_direction(0), Sr3Logic.RIGHT, "zero")


func test_probe_offset_follows_direction() -> void:
	assert_almost_eq(Sr3Logic.probe_offset(1, 10.0), 10.0, 0.0001, "à direita")
	assert_almost_eq(Sr3Logic.probe_offset(-1, 10.0), -10.0, 0.0001, "à esquerda")


func test_walk_velocity_uses_balance_speed() -> void:
	assert_almost_eq(
		Sr3Logic.walk_velocity(1, Balance.SR3_SPEED, false),
		Balance.SR3_SPEED,
		0.0001,
		"andando para a direita"
	)
	assert_almost_eq(
		Sr3Logic.walk_velocity(-1, Balance.SR3_SPEED, false),
		-Balance.SR3_SPEED,
		0.0001,
		"andando para a esquerda"
	)


func test_walk_velocity_is_zero_when_shut_down() -> void:
	assert_almost_eq(
		Sr3Logic.walk_velocity(1, Balance.SR3_SPEED, true), 0.0, 0.0001, "desligada não anda"
	)


func test_shutdown_counts_down_and_never_goes_negative() -> void:
	var left: float = Sr3Logic.tick_shutdown(Balance.BEAM_SHUTDOWN_TIME, 1.0)
	assert_almost_eq(left, Balance.BEAM_SHUTDOWN_TIME - 1.0, 0.0001, "um segundo depois")
	assert_almost_eq(Sr3Logic.tick_shutdown(0.5, 2.0), 0.0, 0.0001, "não fica negativo")
	assert_almost_eq(Sr3Logic.tick_shutdown(0.0, 1.0), 0.0, 0.0001, "já estava ligada")


func test_wakes_up_only_on_the_frame_the_timer_ends() -> void:
	assert_false(Sr3Logic.woke_up(4.0, 3.0), "ainda desligada")
	assert_true(Sr3Logic.woke_up(0.2, 0.0), "acordou")
	assert_false(Sr3Logic.woke_up(0.0, 0.0), "nunca esteve desligada")


func test_animation_follows_the_shutdown_timeline() -> void:
	var total: float = Balance.BEAM_SHUTDOWN_TIME
	assert_eq(
		Sr3Logic.animation_for(total, total, 0.4), Sr3Logic.ANIM_SHUTDOWN, "dobrando as pernas"
	)
	assert_eq(Sr3Logic.animation_for(total - 1.0, total, 0.4), Sr3Logic.ANIM_OFF, "desligada")
	assert_eq(Sr3Logic.animation_for(0.0, total, 0.4), Sr3Logic.ANIM_WALK, "voltou a patrulhar")
