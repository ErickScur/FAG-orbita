class_name LightExposure
extends RefCounted

const KEY_POSITION: String = "position"
const KEY_RADIUS: String = "radius"


static func lamp(position: Vector2, radius: float) -> Dictionary:
	return {KEY_POSITION: position, KEY_RADIUS: radius}


static func inside(point: Vector2, entry: Dictionary) -> bool:
	var center: Vector2 = entry.get(KEY_POSITION, Vector2.ZERO)
	var radius: float = float(entry.get(KEY_RADIUS, 0.0))
	return radius > 0.0 and point.distance_to(center) <= radius


static func lamps_reaching(point: Vector2, lamps: Array) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for value: Variant in lamps:
		if value is Dictionary and inside(point, value as Dictionary):
			found.append(value as Dictionary)
	return found


static func is_lit(point: Vector2, flashlight_on: bool, lamps: Array) -> bool:
	if flashlight_on:
		return true
	return not lamps_reaching(point, lamps).is_empty()
