class_name WanderLogic
extends RefCounted

const ARRIVAL_TOLERANCE: float = 3.0


static func pick_target(anchor: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector2:
	var angle: float = rng.randf_range(0.0, TAU)
	var distance: float = sqrt(rng.randf()) * maxf(radius, 0.0)
	return anchor + Vector2.from_angle(angle) * distance


static func clamp_to(point: Vector2, area: Rect2) -> Vector2:
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return point
	return Vector2(
		clampf(point.x, area.position.x, area.end.x),
		clampf(point.y, area.position.y, area.end.y)
	)


static func step(position: Vector2, target: Vector2, speed: float, delta: float) -> Vector2:
	var travel: float = maxf(speed, 0.0) * maxf(delta, 0.0)
	var offset: Vector2 = target - position
	if offset.length() <= travel:
		return target
	return position + offset.normalized() * travel


static func reached(position: Vector2, target: Vector2, tolerance: float) -> bool:
	return position.distance_to(target) <= tolerance


static func should_retarget(
	time_since: float, retarget_time: float, blocked: bool, arrived: bool
) -> bool:
	return arrived or blocked or time_since >= retarget_time


static func follow_point(player_feet: Vector2, facing: int, lead: float, height: float) -> Vector2:
	var direction: float = -1.0 if facing < 0 else 1.0
	return player_feet + Vector2(direction * lead, -height)


static func should_follow(
	following: bool,
	player_feet: Vector2,
	drone: Vector2,
	territory: Rect2,
	notice_radius: float
) -> bool:
	if territory.size.x > 0.0 and territory.size.y > 0.0 and not territory.has_point(player_feet):
		return false
	if following:
		return true
	return player_feet.distance_to(drone) <= notice_radius


static func should_spray(arrived: bool, chance: float, rng: RandomNumberGenerator) -> bool:
	if not arrived:
		return false
	return rng.randf() < clampf(chance, 0.0, 1.0)


static func territory_rect(zone: Array, tile_size: int) -> Rect2:
	if zone.size() != 4:
		return Rect2()
	var size := float(tile_size)
	return Rect2(
		float(zone[0]) * size, float(zone[1]) * size, float(zone[2]) * size, float(zone[3]) * size
	)
