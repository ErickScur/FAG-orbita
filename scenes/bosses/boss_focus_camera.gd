class_name BossFocusCamera
extends Camera2D

signal released()

var _home: Camera2D = null
var _player: Node2D = null
var _from: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _ease_in: float = 0.0
var _hold: float = 0.0
var _ease_out: float = 0.0
var _elapsed: float = 0.0
var _done: bool = false


func _process(delta: float) -> void:
	if _done:
		return
	if not is_instance_valid(_home):
		release()
		return
	_elapsed += delta
	var point: Vector2 = _target
	if _elapsed < _ease_in:
		point = _from.lerp(_target, smoothstep(0.0, 1.0, _elapsed / _ease_in))
	elif _elapsed >= _ease_in + _hold:
		var back: float = _elapsed - _ease_in - _hold
		if back >= _ease_out:
			release()
			return
		point = _target.lerp(home_center(), smoothstep(0.0, 1.0, back / _ease_out))
	global_position = point.round()
	if is_instance_valid(_player) and _player.has_method(&"shake_offset"):
		offset = (_player.call(&"shake_offset") as Vector2).round()


func start(
	home: Camera2D, player: Node2D, target: Vector2, ease_in: float, hold: float, ease_out: float
) -> void:
	_home = home
	_player = player
	_ease_in = maxf(0.001, ease_in)
	_hold = maxf(0.0, hold)
	_ease_out = maxf(0.001, ease_out)
	_elapsed = 0.0
	_done = false
	limit_left = home.limit_left
	limit_top = home.limit_top
	limit_right = home.limit_right
	limit_bottom = home.limit_bottom
	_from = home_center()
	_target = ArenaFraming.clamp_center(target, _limits(), _screen())
	global_position = _from
	make_current()


func target() -> Vector2:
	return _target


func is_running() -> bool:
	return not _done


func home_center() -> Vector2:
	if not is_instance_valid(_home):
		return global_position
	var home_limits := Rect2(
		Vector2(_home.limit_left, _home.limit_top),
		Vector2(_home.limit_right - _home.limit_left, _home.limit_bottom - _home.limit_top)
	)
	return ArenaFraming.clamp_center(_home.global_position, home_limits, _screen())


func release() -> void:
	if _done:
		return
	_done = true
	if is_instance_valid(_home) and _home.is_inside_tree():
		_home.make_current()
		if is_instance_valid(_player) and _player.has_method(&"snap_camera"):
			_player.call(&"snap_camera")
	released.emit()
	queue_free()


func _limits() -> Rect2:
	return Rect2(
		Vector2(limit_left, limit_top),
		Vector2(limit_right - limit_left, limit_bottom - limit_top)
	)


func _screen() -> Vector2:
	if not is_inside_tree():
		return Vector2(
			ProjectSettings.get_setting("display/window/size/viewport_width", 384),
			ProjectSettings.get_setting("display/window/size/viewport_height", 216)
		)
	return get_viewport_rect().size
