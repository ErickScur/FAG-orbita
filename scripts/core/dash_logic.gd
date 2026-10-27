class_name DashLogic
extends RefCounted

const ABILITY_ID: StringName = &"dash"
const END_EPSILON: float = 0.0001


static func has_ability(abilities: Array) -> bool:
	return abilities.has(ABILITY_ID)


static func can_use(charge: float, cost: float, cooldown_left: float, blocked: bool) -> bool:
	if blocked or cooldown_left > 0.0:
		return false
	return charge >= cost


static func can_dash_now(on_floor: bool, air_dash_used: bool) -> bool:
	return on_floor or not air_dash_used


static func dash_velocity(facing: int, speed: float) -> Vector2:
	var direction: int = -1 if facing < 0 else 1
	return Vector2(direction * speed, 0.0)


static func tick(left: float, delta: float) -> float:
	var next: float = left - maxf(0.0, delta)
	if next <= END_EPSILON:
		return 0.0
	return next


static func exit_speed(velocity_x: float, cap: float) -> float:
	return clampf(velocity_x, -absf(cap), absf(cap))


static func distance(speed: float, duration: float) -> float:
	return maxf(0.0, speed) * maxf(0.0, duration)


static func frames(duration: float, step: float) -> int:
	if step <= 0.0 or duration <= 0.0:
		return 0
	return maxi(1, ceili(duration / step - END_EPSILON))
