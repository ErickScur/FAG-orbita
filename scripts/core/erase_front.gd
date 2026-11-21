class_name EraseFront
extends RefCounted

const AXIS_UP: StringName = &"up"
const AXIS_RIGHT: StringName = &"right"
const AXIS_LEFT: StringName = &"left"

var axis: StringName = AXIS_UP
var region: Rect2i = Rect2i()
var tile: int = 16
var start: float = 0.0
var limit: float = 0.0
var position: float = 0.0


static func create(
	front_axis: StringName, tiles: Rect2i, start_tile: int, limit_tile: int, tile_size: int
) -> EraseFront:
	var front := EraseFront.new()
	front.axis = front_axis
	front.region = tiles
	front.tile = tile_size
	front.start = float(start_tile * tile_size)
	front.limit = float(limit_tile * tile_size)
	front.position = front.start
	return front


static func from_config(config: Dictionary, tile_size: int) -> EraseFront:
	var raw: Array = config.get("region", [0, 0, 0, 0])
	var tiles := Rect2i(int(raw[0]), int(raw[1]), int(raw[2]), int(raw[3]))
	return create(
		StringName(String(config.get("axis", "up"))),
		tiles,
		int(config.get("start", 0)),
		int(config.get("limit", 0)),
		tile_size
	)


func reset() -> void:
	position = start


func direction() -> float:
	if axis == AXIS_RIGHT:
		return 1.0
	return -1.0


func is_done() -> bool:
	return is_equal_approx(position, limit)


func advance(distance: float) -> float:
	position = _clamp_to_limit(position + direction() * maxf(distance, 0.0))
	return position


func follow(point: Vector2, lead: float) -> float:
	var behind: float = coordinate(point) - direction() * lead
	if direction() > 0.0:
		position = maxf(position, behind)
	else:
		position = minf(position, behind)
	position = _clamp_to_limit(position)
	return position


func finish() -> void:
	position = limit


func coordinate(point: Vector2) -> float:
	if axis == AXIS_UP:
		return point.y
	return point.x


func region_px() -> Rect2:
	return Rect2(Vector2(region.position * tile), Vector2(region.size * tile))


func covers(point: Vector2, grace: float) -> bool:
	if not region_px().has_point(point):
		return false
	var value: float = coordinate(point)
	if direction() > 0.0:
		return value < position - grace
	return value > position + grace


func swallowed_rect() -> Rect2:
	var area: Rect2 = region_px()
	match axis:
		AXIS_UP:
			var top: float = clampf(position, area.position.y, area.end.y)
			return Rect2(area.position.x, top, area.size.x, area.end.y - top)
		AXIS_RIGHT:
			var right: float = clampf(position, area.position.x, area.end.x)
			return Rect2(area.position.x, area.position.y, right - area.position.x, area.size.y)
	var left: float = clampf(position, area.position.x, area.end.x)
	return Rect2(left, area.position.y, area.end.x - left, area.size.y)


func is_cell_swallowed(cell: Vector2i) -> bool:
	if not region.has_point(cell):
		return false
	match axis:
		AXIS_UP:
			return float(cell.y * tile) >= position
		AXIS_RIGHT:
			return float((cell.x + 1) * tile) <= position
	return float(cell.x * tile) >= position


func swallowed_cells() -> Array[Vector2i]:
	return _cells_on_lines(_swallowed_lines(position), Vector2i(1, 0))


func newly_swallowed(previous: float) -> Array[Vector2i]:
	return _cells_on_lines(_swallowed_lines(position), _swallowed_lines(previous))


func _swallowed_lines(at: float) -> Vector2i:
	var first: int = 0
	var last: int = -1
	match axis:
		AXIS_UP:
			first = maxi(int(ceil(at / float(tile))), region.position.y)
			last = region.end.y - 1
		AXIS_RIGHT:
			first = region.position.x
			last = mini(int(floor(at / float(tile))) - 1, region.end.x - 1)
		_:
			first = maxi(int(ceil(at / float(tile))), region.position.x)
			last = region.end.x - 1
	return Vector2i(first, last)


func _cells_on_lines(lines: Vector2i, skip: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for line: int in range(lines.x, lines.y + 1):
		if line >= skip.x and line <= skip.y:
			continue
		if axis == AXIS_UP:
			for column: int in range(region.position.x, region.end.x):
				cells.append(Vector2i(column, line))
		else:
			for row: int in range(region.position.y, region.end.y):
				cells.append(Vector2i(line, row))
	return cells


func _clamp_to_limit(value: float) -> float:
	if direction() > 0.0:
		return clampf(value, start, limit)
	return clampf(value, limit, start)
