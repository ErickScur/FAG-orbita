class_name JumpAssist
extends RefCounted

var coyote_time: float = 0.0
var buffer_time: float = 0.0

var _coyote_left: float = 0.0
var _buffer_left: float = 0.0


func _init(coyote: float = 0.0, buffer: float = 0.0) -> void:
	coyote_time = maxf(0.0, coyote)
	buffer_time = maxf(0.0, buffer)


func update(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
	_buffer_left = maxf(0.0, _buffer_left - delta)


func press() -> void:
	_buffer_left = buffer_time


func consume() -> bool:
	if _buffer_left <= 0.0 or _coyote_left <= 0.0:
		return false
	_buffer_left = 0.0
	_coyote_left = 0.0
	return true


func cancel() -> void:
	_buffer_left = 0.0


func coyote_left() -> float:
	return _coyote_left


func buffer_left() -> float:
	return _buffer_left
