class_name BeamLogic
extends RefCounted

const ABILITY_ID: StringName = &"beam"
const TARGET_GROUP: StringName = &"beam_target"
const SHUTDOWN_METHOD: StringName = &"shutdown"
const MAX_PARENT_HOPS: int = 4


static func has_ability(abilities: Array) -> bool:
	return abilities.has(ABILITY_ID)


static func can_fire(charge: float, cost: float, blocked: bool) -> bool:
	if blocked:
		return false
	return charge >= cost


static func ray_vector(facing: int, reach: float) -> Vector2:
	var direction: int = -1 if facing < 0 else 1
	return Vector2(direction * maxf(0.0, reach), 0.0)


static func beam_length(origin: Vector2, hit_point: Variant, reach: float) -> float:
	if not (hit_point is Vector2):
		return maxf(0.0, reach)
	return minf(origin.distance_to(hit_point as Vector2), maxf(0.0, reach))


static func resolve_target(collider: Object) -> Node:
	if not (collider is Node):
		return null
	var node: Node = collider
	for _hop: int in range(MAX_PARENT_HOPS + 1):
		if node == null:
			return null
		if node.is_in_group(TARGET_GROUP) and node.has_method(SHUTDOWN_METHOD):
			return node
		node = node.get_parent()
	return null
