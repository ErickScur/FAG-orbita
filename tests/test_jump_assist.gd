extends TestCase

const STEP: float = 1.0 / 60.0

var _assist: JumpAssist = null


func before_each() -> void:
	_assist = JumpAssist.new(Balance.COYOTE_TIME, Balance.JUMP_BUFFER)


func test_ground_jump_is_immediate() -> void:
	_assist.update(STEP, true)
	_assist.press()
	assert_true(_assist.consume(), "pulo no chão")


func test_no_jump_without_press() -> void:
	_assist.update(STEP, true)
	assert_false(_assist.consume(), "sem apertar não pula")


func test_coyote_allows_late_jump() -> void:
	_assist.update(STEP, true)
	_assist.update(Balance.COYOTE_TIME * 0.5, false)
	_assist.press()
	assert_true(_assist.consume(), "pulo dentro do coyote")


func test_coyote_expires() -> void:
	_assist.update(STEP, true)
	_assist.update(Balance.COYOTE_TIME + 0.02, false)
	_assist.press()
	assert_false(_assist.consume(), "coyote expirado")


func test_buffer_triggers_on_landing() -> void:
	_assist.press()
	_assist.update(Balance.JUMP_BUFFER * 0.4, false)
	_assist.update(STEP, true)
	assert_true(_assist.consume(), "buffer aproveitado no pouso")


func test_buffer_expires() -> void:
	_assist.press()
	_assist.update(Balance.JUMP_BUFFER + 0.02, false)
	_assist.update(STEP, true)
	assert_false(_assist.consume(), "buffer expirado")


func test_consume_resets() -> void:
	_assist.update(STEP, true)
	_assist.press()
	assert_true(_assist.consume(), "primeiro pulo")
	assert_false(_assist.consume(), "segundo pulo sem novo aperto")


func test_cancel_drops_buffer() -> void:
	_assist.update(STEP, true)
	_assist.press()
	_assist.cancel()
	assert_false(_assist.consume(), "buffer cancelado")


func test_update_recharges_coyote_on_floor() -> void:
	_assist.update(Balance.COYOTE_TIME + 0.02, false)
	assert_almost_eq(_assist.coyote_left(), 0.0, 0.0001, "coyote zerado no ar")
	_assist.update(STEP, true)
	assert_almost_eq(_assist.coyote_left(), Balance.COYOTE_TIME, 0.0001, "coyote recarregado")


func test_negative_times_are_clamped() -> void:
	var assist := JumpAssist.new(-1.0, -1.0)
	assert_almost_eq(assist.coyote_time, 0.0, 0.0001, "coyote")
	assert_almost_eq(assist.buffer_time, 0.0, 0.0001, "buffer")
	assist.update(STEP, true)
	assist.press()
	assert_false(assist.consume(), "sem assistência não há pulo bufferizado")
