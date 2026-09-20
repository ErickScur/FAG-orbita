extends TestCase


func test_no_ability_no_grab() -> void:
	assert_false(ClimbLogic.can_grab(false, true, 1.0, 1, false), "sem garras não gruda")


func test_no_wall_no_grab() -> void:
	assert_false(ClimbLogic.can_grab(true, false, 1.0, 1, true), "sem parede não gruda")


func test_grab_pressing_into_wall() -> void:
	assert_true(ClimbLogic.can_grab(true, true, 1.0, 1, false), "andando contra a parede")


func test_no_grab_pressing_away_from_wall() -> void:
	assert_false(ClimbLogic.can_grab(true, true, -1.0, 1, false), "andando para longe")


func test_grab_pressing_up() -> void:
	assert_true(ClimbLogic.can_grab(true, true, 0.0, 1, true), "segurando para cima")


func test_no_grab_without_input() -> void:
	assert_false(ClimbLogic.can_grab(true, true, 0.0, 1, false), "sem direção não gruda")


func test_grab_works_facing_left() -> void:
	assert_true(ClimbLogic.can_grab(true, true, -1.0, -1, false), "parede à esquerda")


func test_climb_up_is_negative_y() -> void:
	assert_eq(ClimbLogic.climb_velocity(-1.0, 60.0), Vector2(0.0, -60.0), "subida")


func test_climb_down_is_positive_y() -> void:
	assert_eq(ClimbLogic.climb_velocity(1.0, 60.0), Vector2(0.0, 60.0), "descida")


func test_idle_on_wall() -> void:
	assert_eq(ClimbLogic.climb_velocity(0.0, 60.0), Vector2.ZERO, "parado na parede")


func test_climb_uses_balance_speed() -> void:
	assert_almost_eq(
		ClimbLogic.climb_velocity(-1.0, Balance.CLAW_CLIMB_SPEED).y,
		-Balance.CLAW_CLIMB_SPEED,
		0.0001,
		"velocidade do GDD-P"
	)


func test_jump_off_pushes_away() -> void:
	assert_eq(
		ClimbLogic.jump_off_velocity(1, 110.0, 280.0), Vector2(-110.0, -280.0), "solta à esquerda"
	)


func test_jump_off_from_left_wall() -> void:
	assert_eq(
		ClimbLogic.jump_off_velocity(-1, 110.0, 280.0), Vector2(110.0, -280.0), "solta à direita"
	)


func test_jump_off_is_always_upward() -> void:
	assert_true(
		ClimbLogic.jump_off_velocity(1, Balance.CLAW_JUMP_PUSH, -280.0).y < 0.0, "sobe sempre"
	)


func test_release_when_wall_ends() -> void:
	assert_true(ClimbLogic.should_release(false, true), "sem parede solta")


func test_release_when_ability_lost() -> void:
	assert_true(ClimbLogic.should_release(true, false), "sem garras solta")


func test_keeps_climbing_with_wall_and_ability() -> void:
	assert_false(ClimbLogic.should_release(true, true), "segue grudado")


func test_has_ability_reads_the_array() -> void:
	assert_false(ClimbLogic.has_ability([]), "lista vazia")
	assert_true(ClimbLogic.has_ability([ClimbLogic.ABILITY_ID]), "com a habilidade")
