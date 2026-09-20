class_name PathFollower
extends RefCounted

var points: PackedVector2Array = PackedVector2Array()
var speed: float = 0.0
var wait_time: float = 0.0

var _target: int = 0
var _direction: int = 1
var _wait_left: float = 0.0


func _init(
	p_points: PackedVector2Array = PackedVector2Array(),
	p_speed: float = 0.0,
	p_wait: float = 0.0
) -> void:
	points = p_points
	speed = maxf(0.0, p_speed)
	wait_time = maxf(0.0, p_wait)
	_target = 1 if points.size() > 1 else 0
	_direction = 1
	_wait_left = 0.0


func step(from: Vector2, delta: float) -> Vector2:
	if points.size() < 2 or speed <= 0.0 or delta <= 0.0:
		return from
	if _wait_left > 0.0:
		_wait_left = maxf(0.0, _wait_left - delta)
		if _wait_left > 0.0:
			return from
		_advance_target()
		return from
	var goal: Vector2 = points[_target]
	var offset: Vector2 = goal - from
	var travel: float = speed * delta
	if offset.length() <= travel or is_zero_approx(offset.length()):
		_wait_left = wait_time
		if _wait_left <= 0.0:
			_advance_target()
		return goal
	return from + offset.normalized() * travel


func is_waiting() -> bool:
	return _wait_left > 0.0


func progress_index() -> int:
	return _target


func direction() -> int:
	return _direction


func _advance_target() -> void:
	var last: int = points.size() - 1
	if _target >= last:
		_direction = -1
	elif _target <= 0:
		_direction = 1
	_target = clampi(_target + _direction, 0, last)
