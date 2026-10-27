class_name FreezeRules
extends RefCounted

const ABILITY_ID: StringName = &"heated_core"


static func has_heated_core(abilities: Array) -> bool:
	return abilities.has(ABILITY_ID)


static func freezes(in_cold: bool, warmed: bool, has_core: bool) -> bool:
	return in_cold and not warmed and not has_core


static func walk_speed(multiplier: float) -> float:
	return Balance.WALK_SPEED * maxf(0.0, multiplier)


static func jump_height(multiplier: float) -> float:
	return Balance.JUMP_HEIGHT * maxf(0.0, multiplier)


static func is_braking(axis: float, current: float) -> bool:
	if is_zero_approx(axis):
		return true
	return not is_zero_approx(current) and signf(axis) != signf(current)


static func horizontal_rate(axis: float, current: float, on_floor: bool, slippery: bool) -> float:
	var rate: float = Balance.WALK_ACCEL if not is_zero_approx(axis) else Balance.WALK_DECEL
	if not on_floor:
		return rate * Balance.AIR_ACCEL_RATIO
	if slippery and is_braking(axis, current):
		return rate * Balance.FREEZE_DECEL_MULT
	return rate
