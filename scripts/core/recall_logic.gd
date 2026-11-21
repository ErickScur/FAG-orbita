class_name RecallLogic
extends RefCounted

var start_x: float = 0.0
var end_x: float = 0.0
var line_count: int = 0
var opened: int = 0

var _flash_left: float = 0.0
var _kick_left: float = 0.0


static func create(from_x: float, to_x: float, lines: int) -> RecallLogic:
	var logic := RecallLogic.new()
	logic.start_x = from_x
	logic.end_x = to_x
	logic.line_count = maxi(lines, 0)
	return logic


func direction() -> float:
	return signf(end_x - start_x) if not is_equal_approx(end_x, start_x) else 1.0


func reset() -> void:
	opened = 0
	_flash_left = 0.0
	_kick_left = 0.0


func is_complete() -> bool:
	return opened >= line_count


func threshold_x(index: int) -> float:
	if line_count <= 1:
		return start_x
	var ratio: float = float(clampi(index, 0, line_count - 1)) / float(line_count - 1)
	return lerpf(start_x, end_x, ratio)


func has_passed(x: float, mark: float) -> bool:
	return (x - mark) * direction() >= 0.0


func next_line_ready(x: float, typing_done: bool) -> bool:
	if is_complete():
		return false
	if opened > 0 and not typing_done:
		return false
	return has_passed(x, threshold_x(opened))


func open_next() -> int:
	if is_complete():
		return -1
	opened += 1
	_flash_left = Balance.RECALL_FLASH_TIME
	_kick_left = Balance.RECALL_FLASH_PUSH_TIME
	return opened - 1


func back_limit() -> float:
	if opened <= 0:
		return start_x
	var mark: float = threshold_x(opened - 1) - direction() * Balance.RECALL_BACKSTEP
	if (mark - start_x) * direction() < 0.0:
		return start_x
	return mark


func push_speed() -> float:
	var speed: float = Balance.RECALL_PUSH_SPEED
	if _kick_left > 0.0:
		speed += Balance.RECALL_FLASH_PUSH
	return -direction() * speed


func push_step(x: float, delta: float) -> float:
	var step: float = push_speed() * delta
	var backward: float = -direction()
	var limit: float = back_limit()
	if (x - limit) * backward >= 0.0:
		return 0.0
	if (x + step - limit) * backward > 0.0:
		return limit - x
	return step


func tick(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	_kick_left = maxf(0.0, _kick_left - delta)


func flash_ratio() -> float:
	if Balance.RECALL_FLASH_TIME <= 0.0:
		return 0.0
	return _flash_left / Balance.RECALL_FLASH_TIME


func is_kicking() -> bool:
	return _kick_left > 0.0
