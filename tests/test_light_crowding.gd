extends TestCase

const LEVELS_DIR: String = "res://data/levels/"
const PLAYABLE_LEVELS: PackedStringArray = ["core_hub", "greenhouse"]
const TILE_SIZE: int = 16
const WINDOW_PX: int = 256
const WINDOW_STEP_PX: int = 32
const MAX_LIGHTS_PER_WINDOW: int = 12
const MAGNETIC_SYMBOL: String = "M"
const RADIUS_BY_SYMBOL: Dictionary = {
	"@": 96.0,
	"g": 56.0,
	"m": 24.0,
	"E": 80.0,
	"S": 40.0,
}


func test_no_level_window_is_light_crowded() -> void:
	for level_id: String in PLAYABLE_LEVELS:
		var lights: Array[Dictionary] = _lights(level_id)
		var worst: Dictionary = _worst_window(level_id, lights)
		assert_true(
			int(worst.get("count", 0)) <= MAX_LIGHTS_PER_WINDOW,
			"%s: %d luzes na janela de %d px em %s (máximo %d)" % [
				level_id,
				int(worst.get("count", 0)),
				WINDOW_PX,
				str(worst.get("cell", Vector2i.ZERO)),
				MAX_LIGHTS_PER_WINDOW
			]
		)


func test_magnetic_walls_share_one_glow_per_segment() -> void:
	for level_id: String in PLAYABLE_LEVELS:
		var runs: Array[int] = _magnetic_runs(level_id)
		for length: int in runs:
			var glows: int = _segments_for(length)
			assert_true(
				glows <= maxi(1, length / Balance.MAGNETIC_GLOW_SEGMENT_TILES + 1),
				"%s: trecho de %d tiles acende %d luzes" % [level_id, length, glows]
			)
			assert_true(
				glows < length or length <= Balance.MAGNETIC_GLOW_SEGMENT_TILES,
				"%s: trecho de %d tiles não fundiu o brilho" % [level_id, length]
			)


func _segments_for(length: int) -> int:
	return int(ceilf(float(length) / float(Balance.MAGNETIC_GLOW_SEGMENT_TILES)))


func _worst_window(level_id: String, lights: Array[Dictionary]) -> Dictionary:
	var grid: Dictionary = _grid(level_id)
	var width: int = int(grid.get("width", 0)) * TILE_SIZE
	var height: int = int(grid.get("height", 0)) * TILE_SIZE
	var half: float = float(WINDOW_PX) * 0.5
	var worst: int = 0
	var worst_cell := Vector2i.ZERO
	var top: int = 0
	while top < height:
		var left: int = 0
		while left < width:
			var center := Vector2(float(left) + half, float(top) + half)
			var count: int = 0
			for light: Dictionary in lights:
				var position: Vector2 = light.get("position", Vector2.ZERO)
				var extent: Vector2 = light.get("extent", Vector2.ZERO)
				if absf(position.x - center.x) >= half + extent.x:
					continue
				if absf(position.y - center.y) >= half + extent.y:
					continue
				count += 1
			if count > worst:
				worst = count
				worst_cell = Vector2i(left / TILE_SIZE, top / TILE_SIZE)
			left += WINDOW_STEP_PX
		top += WINDOW_STEP_PX
	return {"count": worst, "cell": worst_cell}


func _lights(level_id: String) -> Array[Dictionary]:
	var grid: Dictionary = _grid(level_id)
	var rows: PackedStringArray = grid.get("rows", PackedStringArray())
	var entities: Dictionary = _meta(level_id).get("entities", {})
	var found: Array[Dictionary] = []
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			var symbol: String = row[x]
			if not RADIUS_BY_SYMBOL.has(symbol):
				continue
			var entity: Dictionary = entities.get("%d,%d" % [x, y], {})
			var radius: float = float(entity.get("radius", RADIUS_BY_SYMBOL[symbol]))
			found.append({
				"position": Vector2(float(x * TILE_SIZE) + 8.0, float(y * TILE_SIZE) + 8.0),
				"extent": Vector2(radius, radius),
			})
	found.append_array(_magnetic_lights(level_id))
	return found


func _magnetic_lights(level_id: String) -> Array[Dictionary]:
	var columns: Dictionary = _magnetic_columns(level_id)
	var found: Array[Dictionary] = []
	for x: int in columns:
		for run: Array in _runs(columns[x]):
			var index: int = 0
			while index < run.size():
				var span: int = mini(Balance.MAGNETIC_GLOW_SEGMENT_TILES, run.size() - index)
				var top: int = int(run[index])
				var half_height: float = (
					float(span) + Balance.MAGNETIC_GLOW_SEGMENT_OVERLAP
				) * float(TILE_SIZE) * 0.5
				found.append({
					"position": Vector2(
						float(x * TILE_SIZE) + 8.0,
						float(top * TILE_SIZE) + 8.0 + float(span - 1) * float(TILE_SIZE) * 0.5
					),
					"extent": Vector2(Balance.MAGNETIC_GLOW_RADIUS, half_height),
				})
				index += Balance.MAGNETIC_GLOW_SEGMENT_TILES
	return found


func _magnetic_runs(level_id: String) -> Array[int]:
	var lengths: Array[int] = []
	var columns: Dictionary = _magnetic_columns(level_id)
	for x: int in columns:
		for run: Array in _runs(columns[x]):
			lengths.append(run.size())
	return lengths


func _magnetic_columns(level_id: String) -> Dictionary:
	var grid: Dictionary = _grid(level_id)
	var rows: PackedStringArray = grid.get("rows", PackedStringArray())
	var columns: Dictionary = {}
	for y: int in range(rows.size()):
		var row: String = rows[y]
		for x: int in range(row.length()):
			if row[x] != MAGNETIC_SYMBOL:
				continue
			if not columns.has(x):
				columns[x] = []
			columns[x].append(y)
	return columns


func _runs(rows: Array) -> Array:
	var result: Array = []
	var current: Array = []
	for value: int in rows:
		if current.is_empty() or value == int(current[current.size() - 1]) + 1:
			current.append(value)
			continue
		result.append(current)
		current = [value]
	if not current.is_empty():
		result.append(current)
	return result


func _grid(level_id: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".txt")
	var rows := PackedStringArray()
	var width: int = 0
	for line: String in text.split("\n"):
		if line.is_empty():
			continue
		rows.append(line)
		width = maxi(width, line.length())
	return {"rows": rows, "width": width, "height": rows.size()}


func _meta(level_id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(LEVELS_DIR + level_id + ".json")
	)
	return parsed if parsed is Dictionary else {}
