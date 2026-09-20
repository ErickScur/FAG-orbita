class_name Sr3Logic
extends RefCounted

const ANIM_WALK: StringName = &"walk"
const ANIM_SHUTDOWN: StringName = &"shutdown"
const ANIM_OFF: StringName = &"off"
const RIGHT: int = 1
const LEFT: int = -1


static func normalize_direction(value: int) -> int:
	return LEFT if value < 0 else RIGHT


static func flip(direction: int) -> int:
	return -normalize_direction(direction)


static func should_turn(floor_ahead: bool, wall_ahead: bool) -> bool:
	return not floor_ahead or wall_ahead


static func walk_velocity(direction: int, speed: float, shut_down: bool) -> float:
	if shut_down or speed <= 0.0:
		return 0.0
	return float(normalize_direction(direction)) * speed


static func probe_offset(direction: int, distance: float) -> float:
	return float(normalize_direction(direction)) * absf(distance)


static func tick_shutdown(remaining: float, delta: float) -> float:
	if remaining <= 0.0:
		return 0.0
	return maxf(0.0, remaining - maxf(0.0, delta))


static func woke_up(before: float, after: float) -> bool:
	return before > 0.0 and after <= 0.0


static func should_restart_animation(
	current: StringName, target: StringName, playing: bool, loops: bool
) -> bool:
	if current != target:
		return true
	return loops and not playing


static func animation_for(remaining: float, total: float, folding_time: float) -> StringName:
	if remaining <= 0.0:
		return ANIM_WALK
	if total - remaining < maxf(0.0, folding_time):
		return ANIM_SHUTDOWN
	return ANIM_OFF
