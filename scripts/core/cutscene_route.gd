class_name CutsceneRoute
extends RefCounted

const EPSILON: float = 0.001


static func order_points(
	start: Vector2, finish: Vector2, points: Array[Vector2], spacing: float, limit: int
) -> Array[Vector2]:
	var axis: Vector2 = finish - start
	var sorted: Array[Vector2] = points.duplicate()
	if axis.length_squared() <= EPSILON:
		sorted.sort_custom(
			func(a: Vector2, b: Vector2) -> bool:
				return a.distance_squared_to(start) < b.distance_squared_to(start)
		)
	else:
		sorted.sort_custom(
			func(a: Vector2, b: Vector2) -> bool:
				return axis.dot(a - start) < axis.dot(b - start)
		)
	var kept: Array[Vector2] = []
	var previous: Vector2 = start
	for point: Vector2 in sorted:
		if point.distance_to(previous) < spacing:
			continue
		if point.distance_to(finish) < spacing:
			continue
		kept.append(point)
		previous = point
	return _thin_to_limit(kept, limit)


static func build(
	start: Vector2, finish: Vector2, points: Array[Vector2], spacing: float, limit: int
) -> Array[Vector2]:
	var path: Array[Vector2] = [start]
	path.append_array(order_points(start, finish, points, spacing, limit))
	if finish.distance_to(path[path.size() - 1]) > EPSILON:
		path.append(finish)
	return path


static func length(path: Array[Vector2]) -> float:
	var total: float = 0.0
	for index: int in range(1, path.size()):
		total += path[index - 1].distance_to(path[index])
	return total


static func point_at(path: Array[Vector2], distance: float) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	if distance <= 0.0:
		return path[0]
	var walked: float = 0.0
	for index: int in range(1, path.size()):
		var segment: float = path[index - 1].distance_to(path[index])
		if segment <= EPSILON:
			continue
		if walked + segment >= distance:
			return path[index - 1].lerp(path[index], (distance - walked) / segment)
		walked += segment
	return path[path.size() - 1]


static func point_at_ratio(path: Array[Vector2], ratio: float) -> Vector2:
	return point_at(path, length(path) * clampf(ratio, 0.0, 1.0))


static func ease_in_out(value: float) -> float:
	var t: float = clampf(value, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


static func duration_for(
	path_length: float, speed: float, minimum: float, maximum: float
) -> float:
	if speed <= 0.0:
		return maximum
	return clampf(path_length / speed, minimum, maximum)


static func snap(point: Vector2) -> Vector2:
	return Vector2(roundf(point.x), roundf(point.y))


static func can_release_control(elapsed: float, grace: float, any_pressed: bool) -> bool:
	return not any_pressed or elapsed >= grace


static func is_on_screen(camera: Vector2, point: Vector2, half_size: Vector2) -> bool:
	return absf(point.x - camera.x) <= half_size.x and absf(point.y - camera.y) <= half_size.y


static func _thin_to_limit(points: Array[Vector2], limit: int) -> Array[Vector2]:
	if limit <= 0 or points.size() <= limit:
		return points
	var result: Array[Vector2] = []
	if limit == 1:
		result.append(points[points.size() - 1])
		return result
	var step: float = float(points.size() - 1) / float(limit - 1)
	for index: int in range(limit):
		result.append(points[int(roundf(float(index) * step))])
	return result
