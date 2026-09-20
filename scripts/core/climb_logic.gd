class_name ClimbLogic
extends RefCounted

const ABILITY_ID: StringName = &"magnetic_claws"
const MAGNETIC_GROUP: StringName = &"magnetic"


static func can_grab(
	has_ability: bool,
	touching_magnetic: bool,
	input_x: float,
	facing: int,
	input_up: bool
) -> bool:
	if not has_ability or not touching_magnetic:
		return false
	if input_up:
		return true
	return not is_zero_approx(input_x) and int(signf(input_x)) == facing


static func climb_velocity(input_y: float, speed: float) -> Vector2:
	return Vector2(0.0, clampf(input_y, -1.0, 1.0) * maxf(0.0, speed))


static func jump_off_velocity(facing: int, push: float, jump_speed: float) -> Vector2:
	var direction: int = -1 if facing > 0 else 1
	return Vector2(float(direction) * maxf(0.0, push), -absf(jump_speed))


static func should_release(touching_magnetic: bool, has_ability: bool) -> bool:
	return not touching_magnetic or not has_ability


static func has_ability(abilities: Array) -> bool:
	return abilities.has(ABILITY_ID)
