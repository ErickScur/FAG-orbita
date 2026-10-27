class_name Cx2Logic
extends RefCounted

enum Phase { SCAN, LOCK, COOLDOWN, OFF, SHUTDOWN }

const MOUNT_CEILING: StringName = &"ceiling"
const MOUNT_WALL_LEFT: StringName = &"wall_left"
const MOUNT_WALL_RIGHT: StringName = &"wall_right"
const MOUNT_AIM: Dictionary = {
	MOUNT_CEILING: 90.0,
	MOUNT_WALL_LEFT: 0.0,
	MOUNT_WALL_RIGHT: 180.0,
}
const MOUNT_ROTATION: Dictionary = {
	MOUNT_CEILING: 0.0,
	MOUNT_WALL_LEFT: -90.0,
	MOUNT_WALL_RIGHT: 90.0,
}
const MOUNT_BASE: Dictionary = {
	MOUNT_CEILING: Vector2(0.0, -1.0),
	MOUNT_WALL_LEFT: Vector2(-1.0, 0.0),
	MOUNT_WALL_RIGHT: Vector2(1.0, 0.0),
}

var powered: bool = true
var base_angle: float = 90.0
var lock_time: float = Balance.CX2_LOCK_TIME
var cooldown_time: float = Balance.CX2_COOLDOWN
var sweep_arc: float = Balance.CX2_SWEEP_ARC
var sweep_speed: float = Balance.CX2_SWEEP_SPEED

var _sweep_time: float = 0.0
var _lock: float = 0.0
var _cooldown: float = 0.0
var _shutdown_left: float = 0.0


static func normalize_mount(mount: StringName) -> StringName:
	return mount if MOUNT_AIM.has(mount) else MOUNT_CEILING


static func mount_aim(mount: StringName) -> float:
	return float(MOUNT_AIM[normalize_mount(mount)])


static func mount_rotation(mount: StringName) -> float:
	return float(MOUNT_ROTATION[normalize_mount(mount)])


static func mount_base(mount: StringName) -> Vector2:
	return MOUNT_BASE[normalize_mount(mount)]


static func sweep_offset(elapsed: float, arc: float, speed: float) -> float:
	if arc <= 0.0 or speed <= 0.0:
		return 0.0
	var period: float = 4.0 * arc / speed
	var t: float = fposmod(elapsed, period) * speed
	if t <= arc:
		return t
	if t <= 3.0 * arc:
		return 2.0 * arc - t
	return t - 4.0 * arc


static func scan_frame(offset: float, arc: float, frames: int) -> int:
	if frames <= 1 or arc <= 0.0:
		return 0
	var ratio: float = clampf((arc - offset) / (arc * 2.0), 0.0, 1.0)
	return roundi(ratio * float(frames - 1))


static func direction(angle_degrees: float) -> Vector2:
	return Vector2.RIGHT.rotated(deg_to_rad(angle_degrees))


static func in_cone(
	origin: Vector2, aim_degrees: float, half_angle: float, reach: float, point: Vector2
) -> bool:
	var offset: Vector2 = point - origin
	var distance: float = offset.length()
	if distance > reach:
		return false
	if is_zero_approx(distance):
		return true
	var gap: float = absf(rad_to_deg(direction(aim_degrees).angle_to(offset)))
	return gap <= half_angle


static func cone_polygon(
	origin: Vector2, aim_degrees: float, half_angle: float, distances: PackedFloat32Array
) -> PackedVector2Array:
	var points := PackedVector2Array([origin])
	var count: int = distances.size()
	if count < 2:
		return points
	for index: int in range(count):
		var ratio: float = float(index) / float(count - 1)
		var angle: float = aim_degrees - half_angle + ratio * half_angle * 2.0
		points.append(origin + direction(angle) * distances[index])
	return points


func update(delta: float, sees_target: bool) -> bool:
	if _shutdown_left > 0.0:
		_shutdown_left = maxf(0.0, _shutdown_left - maxf(0.0, delta))
		_lock = 0.0
		return false
	if not powered:
		_lock = 0.0
		return false
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
		_sweep_time += delta
		_lock = 0.0
		return false
	if not sees_target:
		_lock = 0.0
		_sweep_time += delta
		return false
	_lock += delta
	if _lock < lock_time:
		return false
	_lock = 0.0
	_cooldown = cooldown_time
	return true


func set_powered(on: bool) -> void:
	powered = on
	if on:
		return
	_lock = 0.0
	_cooldown = 0.0


func shutdown(duration: float) -> bool:
	if duration <= 0.0:
		return false
	var was_awake: bool = not is_shut_down()
	_shutdown_left = maxf(_shutdown_left, duration)
	_lock = 0.0
	_cooldown = 0.0
	return was_awake


func is_shut_down() -> bool:
	return _shutdown_left > 0.0


func shutdown_remaining() -> float:
	return _shutdown_left


func aim_angle() -> float:
	return base_angle + current_sweep()


func current_sweep() -> float:
	return sweep_offset(_sweep_time, sweep_arc, sweep_speed)


func phase() -> Phase:
	if not powered:
		return Phase.OFF
	if _shutdown_left > 0.0:
		return Phase.SHUTDOWN
	if _cooldown > 0.0:
		return Phase.COOLDOWN
	if _lock > 0.0:
		return Phase.LOCK
	return Phase.SCAN


func lock_ratio() -> float:
	if lock_time <= 0.0:
		return 0.0
	return clampf(_lock / lock_time, 0.0, 1.0)


func cooldown_left() -> float:
	return _cooldown
