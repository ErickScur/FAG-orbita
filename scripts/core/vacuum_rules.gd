class_name VacuumRules
extends RefCounted

const ABILITY_ID: StringName = &"thruster"
const ALONG_EPSILON: float = 0.001
const FLOOR_NORMAL: float = 0.5


static func has_thruster(abilities: Array) -> bool:
	return abilities.has(ABILITY_ID)


static func can_double_jump(
	thruster: bool,
	used: bool,
	on_floor: bool,
	coyote_left: float,
	climbing: bool,
	blocked: bool,
	charge: float,
	cost: float
) -> bool:
	if not thruster or used or on_floor or climbing or blocked:
		return false
	if coyote_left > 0.0:
		return false
	return charge >= cost


static func can_thrust(thruster: bool, blocked: bool, charge: float, input: Vector2) -> bool:
	if not thruster or blocked or input.is_zero_approx():
		return false
	return charge > 0.0


static func away_from(normal: Vector2) -> Vector2:
	if normal.is_zero_approx():
		return Vector2.UP
	return normal.normalized()


static func is_floor(normal: Vector2) -> bool:
	return away_from(normal).y < -FLOOR_NORMAL


static func push_direction(input: Vector2, normal: Vector2) -> Vector2:
	var away: Vector2 = away_from(normal)
	if input.is_zero_approx():
		return away
	var direction: Vector2 = input.normalized()
	var along: float = direction.dot(away)
	if along < 0.0:
		direction -= away * along
	if along <= ALONG_EPSILON and is_floor(normal):
		direction += away
	if direction.length() < ALONG_EPSILON:
		return away
	return direction.normalized()


static func hits_surface(drift: Vector2, normal: Vector2) -> bool:
	return drift.dot(normal) < -ALONG_EPSILON


static func push_velocity(input: Vector2, normal: Vector2, speed: float) -> Vector2:
	return push_direction(input, normal) * maxf(0.0, speed)


static func clamp_drift(velocity: Vector2, max_speed: float) -> Vector2:
	return velocity.limit_length(maxf(0.0, max_speed))


static func thrust(
	velocity: Vector2, input: Vector2, delta: float, accel: float, top: float
) -> Vector2:
	if input.is_zero_approx():
		return velocity
	var target: Vector2 = input.normalized() * maxf(0.0, top)
	return velocity.move_toward(target, maxf(0.0, accel) * maxf(0.0, delta))


static func thrust_cost(delta: float, drain: float) -> float:
	return maxf(0.0, delta) * maxf(0.0, drain)


static func crossing_damage(distance: float, speed: float, dps: float) -> float:
	if speed <= 0.0:
		return INF
	return maxf(0.0, distance) / speed * maxf(0.0, dps)
