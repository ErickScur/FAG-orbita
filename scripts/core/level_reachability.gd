class_name LevelReachability
extends RefCounted

const CELL_EMPTY: int = 0
const CELL_SOLID: int = 1
const CELL_ONE_WAY: int = 2
const CELL_MAGNETIC: int = 3
const SURFACE_NONE: int = 0
const SURFACE_SOLID: int = 1
const SURFACE_ONE_WAY: int = 2
const SURFACE_PLANT: int = 3
const SURFACE_PLATFORM: int = 4
const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const PLANT_SCENE: String = "res://scenes/world/grow_plant.tscn"
const PLATFORM_SCENE: String = "res://scenes/world/moving_platform.tscn"
const PICKUP_SCENE: String = "res://scenes/world/collectible.tscn"
const BODY_SHAPE_NODE: String = "CollisionShape2D"
const CLAW_TOP_NODE: String = "ClawProbeTop"
const CLAW_BOTTOM_NODE: String = "ClawProbeBottom"
const CLEARANCE_NODE: String = "OneWayClearance"
const PLANT_TOP_NODE: String = "Top/CollisionShape2D"
const MAGNETIC_SYMBOL: String = "M"
const PLANT_SYMBOL: String = "g"
const PLATFORM_SYMBOL: String = "m"
const PASSABLE_SYMBOLS: String = "|x"
const PICKUP_SYMBOLS: String = "lrckC"
const INTERACT_SYMBOLS: String = "TLED"
const PROP_SYMBOL: String = "o"
const INTERACTIVE_PROP_KEYS: Array[String] = ["scene", "log"]
const MIN_STACK_OVERLAP_COLUMNS: int = 2
const RELEASE_FRAMES: Array[int] = [6, 14, -1]
const CLIMB_SAMPLE_STEP: float = 8.0
const PLATFORM_SAMPLE_STEP: float = 8.0
const MAX_SIM_FRAMES: int = 240
const EPSILON: float = 0.01
const ONE_WAY_MARGIN: float = 0.5
const DEFAULT_TICKS: int = 60
const HINT_RADIUS_TILES: int = 6
const MARK_TOUCHED: String = "."
const MARK_STAND: String = "_"

static var _cached_profile: Dictionary = {}

var _tile: float = 16.0
var _width: int = 0
var _height: int = 0
var _cells: PackedByteArray = PackedByteArray()
var _touched: PackedByteArray = PackedByteArray()
var _plants: Array[Dictionary] = []
var _platforms: Array[Dictionary] = []
var _stands: Dictionary = {}
var _stand_queue: Array[Vector2i] = []
var _climbs: Dictionary = {}
var _climb_queue: Array[Dictionary] = []
var _platforms_reached: Dictionary = {}
var _platform_queue: Array[int] = []
var _rejected: Array[Dictionary] = []
var _jams: Array[Dictionary] = []
var _half_width: float = 7.0
var _body_height: float = 24.0
var _claw_reach: float = 10.0
var _probe_heights: PackedFloat32Array = PackedFloat32Array()
var _clearance: float = 24.0
var _drop_nudge: float = 1.0
var _pickup_half: float = 6.0
var _dt: float = 1.0 / 60.0
var _jump_velocity: float = 0.0
var _wall_jump_velocity: float = 0.0
var _active_platform: int = -1
var _active_top: float = 0.0
var _active_x: float = 0.0


static func analyze(text: String, meta: Dictionary = {}, profile: Dictionary = {}) -> Dictionary:
	var parsed: Dictionary = LevelParser.parse(text, LevelBuilder.entity_chars())
	var solver := LevelReachability.new()
	var used: Dictionary = profile if not profile.is_empty() else default_profile()
	return solver._run(parsed, meta, used)


static func analyze_file(text_path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(text_path)
	var meta: Dictionary = {}
	var meta_path: String = text_path.get_basename() + ".json"
	if FileAccess.file_exists(meta_path):
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if data is Dictionary:
			meta = data
	return analyze(text, meta)


static func default_profile() -> Dictionary:
	if not _cached_profile.is_empty():
		return _cached_profile.duplicate()
	var body: Dictionary = _node_properties(PLAYER_SCENE, BODY_SHAPE_NODE)
	var body_size: Vector2 = _shape_size(body)
	var body_position: Vector2 = body.get("position", Vector2.ZERO)
	var feet: float = body_position.y + body_size.y * 0.5
	var probes := PackedFloat32Array()
	for node_path: String in [CLAW_TOP_NODE, CLAW_BOTTOM_NODE]:
		var probe: Dictionary = _node_properties(PLAYER_SCENE, node_path)
		var offset: Vector2 = probe.get("position", Vector2.ZERO)
		probes.append(feet - offset.y)
	var clearance: Dictionary = _node_properties(PLAYER_SCENE, CLEARANCE_NODE)
	var plant: Dictionary = _node_properties(PLANT_SCENE, PLANT_TOP_NODE)
	var plant_size: Vector2 = _shape_size(plant)
	var plant_position: Vector2 = plant.get("position", Vector2.ZERO)
	var platform: Dictionary = _node_properties(PLATFORM_SCENE, BODY_SHAPE_NODE)
	var platform_size: Vector2 = _shape_size(platform)
	var pickup_size: Vector2 = _shape_size(_node_properties(PICKUP_SCENE, BODY_SHAPE_NODE))
	var ticks: int = int(
		ProjectSettings.get_setting("physics/common/physics_ticks_per_second", DEFAULT_TICKS)
	)
	_cached_profile = {
		"body_half_width": body_size.x * 0.5,
		"body_height": body_size.y,
		"claw_reach": Mu7.CLAW_PROBE_REACH,
		"claw_probe_heights": probes,
		"drop_nudge": Mu7.DROP_NUDGE,
		"clearance": absf((clearance.get("target_position", Vector2.ZERO) as Vector2).y),
		"plant_top_offset": plant_position.y - plant_size.y * 0.5,
		"plant_half_width": plant_size.x * 0.5,
		"platform_top_offset": -platform_size.y * 0.5,
		"platform_half_width": platform_size.x * 0.5,
		"pickup_half": pickup_size.x * 0.5,
		"ticks": maxi(1, ticks),
	}
	return _cached_profile.duplicate()


static func can_stand_at(result: Dictionary, cell: Vector2i) -> bool:
	var tile: int = Balance.TILE_SIZE
	return (result.get("stands", {}) as Dictionary).has(Vector2i(cell.x, (cell.y + 1) * tile))


static func is_touched(result: Dictionary, cell: Vector2i) -> bool:
	var width: int = int(result.get("width", 0))
	var height: int = int(result.get("height", 0))
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return false
	var touched: PackedByteArray = result.get("touched", PackedByteArray())
	return touched[cell.y * width + cell.x] != 0


static func can_interact_with(result: Dictionary, cell: Vector2i) -> bool:
	var tile: float = float(Balance.TILE_SIZE)
	var body_height: float = float(result.get("body_height", 24.0))
	var target := Vector2(cell.x * tile + tile * 0.5, cell.y * tile + tile * 0.5)
	var reach: float = Balance.INTERACT_RANGE + tile * 0.5
	for key: Variant in result.get("stands", {}) as Dictionary:
		var stand: Vector2i = key
		var center := Vector2(stand.x * tile + tile * 0.5, stand.y - body_height * 0.5)
		if center.distance_to(target) <= reach:
			return true
	return false


static func entities(result: Dictionary, symbols: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	var parsed: Dictionary = result.get("parsed", {})
	for entry: Dictionary in parsed.get("entities", []) as Array:
		if symbols.contains(String(entry.get("symbol", ""))):
			found.append(entry)
	return found


static func required_interactables(result: Dictionary) -> Array[Dictionary]:
	var found: Array[Dictionary] = entities(result, INTERACT_SYMBOLS)
	var meta_entities: Dictionary = (result.get("meta", {}) as Dictionary).get("entities", {})
	for entry: Dictionary in entities(result, PROP_SYMBOL):
		var key: String = LevelParser.cell_key(entry.get("cell", Vector2i.ZERO))
		var params: Variant = meta_entities.get(key, {})
		if not (params is Dictionary):
			continue
		for wanted: String in INTERACTIVE_PROP_KEYS:
			if (params as Dictionary).has(wanted):
				found.append(entry)
				break
	return found


static func unreachable_pickups(result: Dictionary) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	for entry: Dictionary in entities(result, PICKUP_SYMBOLS):
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if not is_touched(result, cell):
			missing.append(_report(result, entry))
	return missing


static func unreachable_interactables(result: Dictionary) -> Array[Dictionary]:
	var missing: Array[Dictionary] = []
	for entry: Dictionary in required_interactables(result):
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if not can_interact_with(result, cell):
			missing.append(_report(result, entry))
	return missing


static func describe(item: Dictionary) -> String:
	var cell: Vector2i = item.get("cell", Vector2i.ZERO)
	return "'%s' em (coluna %d, linha %d): %s" % [
		item.get("symbol", "?"), cell.x, cell.y, item.get("reason", "")
	]


static func render(result: Dictionary) -> String:
	var parsed: Dictionary = result.get("parsed", {})
	var width: int = int(result.get("width", 0))
	var height: int = int(result.get("height", 0))
	var tile: int = Balance.TILE_SIZE
	var grid: Dictionary = {}
	for key: Variant in parsed.get("solids", {}) as Dictionary:
		grid[key] = "#"
	for cell: Vector2i in parsed.get("one_ways", []) as Array:
		grid[cell] = "="
	for row: int in range(height):
		for column: int in range(width):
			var cell := Vector2i(column, row)
			if not grid.has(cell) and is_touched(result, cell):
				grid[cell] = MARK_TOUCHED
	for key: Variant in result.get("stands", {}) as Dictionary:
		var stand: Vector2i = key
		if stand.y % tile != 0:
			continue
		var cell := Vector2i(stand.x, stand.y / tile - 1)
		if String(grid.get(cell, MARK_TOUCHED)) == MARK_TOUCHED:
			grid[cell] = MARK_STAND
	for entry: Dictionary in parsed.get("entities", []) as Array:
		grid[entry.get("cell", Vector2i.ZERO)] = String(entry.get("symbol", "?"))
	grid[parsed.get("spawn", Vector2i.ZERO)] = LevelParser.SPAWN
	var lines := PackedStringArray()
	for row: int in range(height):
		var line: String = ""
		for column: int in range(width):
			line += String(grid.get(Vector2i(column, row), " "))
		lines.append(line)
	return "\n".join(lines)


static func _report(result: Dictionary, entry: Dictionary) -> Dictionary:
	var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
	return {
		"symbol": String(entry.get("symbol", "?")),
		"cell": cell,
		"reason": _explain(result, cell),
	}


static func _explain(result: Dictionary, cell: Vector2i) -> String:
	var tile: float = float(Balance.TILE_SIZE)
	var hints := PackedStringArray()
	var target_feet: float = (cell.y + 1) * tile
	var best: Vector2i = Vector2i(-1, -1)
	var best_distance: float = INF
	for key: Variant in result.get("stands", {}) as Dictionary:
		var stand: Vector2i = key
		var distance: float = Vector2(stand.x * tile, stand.y).distance_to(
			Vector2(cell.x * tile, target_feet)
		)
		if distance < best_distance:
			best_distance = distance
			best = stand
	for plant: Dictionary in result.get("plants", []) as Array:
		var base: Vector2i = plant.get("cell", Vector2i.ZERO)
		if not _near(base, cell) or bool(plant.get("reached", false)):
			continue
		hints.append(
			"trepadeira em (%d, %d) nunca embarcada: topo a %d px do pé e o pulo alcança %d px"
			% [base.x, base.y, int(-float(plant.get("offset", 0.0))), int(Balance.JUMP_HEIGHT)]
			+ " (falta patamar de embarque, ADR-F43-003)"
		)
	for jam: Dictionary in result.get("jams", []) as Array:
		var wall: Vector2i = jam.get("cell", Vector2i.ZERO)
		if cell.y <= wall.y and absi(cell.x - wall.x) <= HINT_RADIUS_TILES * 2:
			hints.append(
				"escalada da parede magnética na coluna %d trava na linha %d: a coluna %d"
				% [wall.x, wall.y, int(jam.get("blocking_column", -1))]
				+ " precisa estar livre (chaminé de 2 tiles, ADR-F43-005)"
			)
			break
	for rejected: Dictionary in result.get("rejected", []) as Array:
		var landing: Vector2i = rejected.get("cell", Vector2i.ZERO)
		if _near(landing, cell):
			hints.append(
				"plataforma fina em (%d, %d) só se alcança por salto apertado com %d coluna(s)"
				% [landing.x, landing.y + 1, int(rejected.get("overlap", 0))]
				+ " de sobreposição; precisa de %d (ADR-F43-002)" % MIN_STACK_OVERLAP_COLUMNS
			)
			break
	if best.x >= 0:
		var rise: int = int(float(best.y) - target_feet)
		var row: int = int(ceilf(float(best.y) / tile)) - 1
		hints.append(
			"apoio alcançável mais próximo em (%d, %d), %d px abaixo; pulo alcança %d px"
			% [best.x, row, rise, int(Balance.JUMP_HEIGHT)]
		)
	else:
		hints.append("nenhum apoio alcançável a partir do spawn")
	return "; ".join(hints)


static func _near(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) <= HINT_RADIUS_TILES and absi(a.y - b.y) <= HINT_RADIUS_TILES


static func _node_properties(scene_path: String, node_path: String) -> Dictionary:
	var properties: Dictionary = {}
	if not ResourceLoader.exists(scene_path):
		push_error("LevelReachability: cena ausente %s" % scene_path)
		return properties
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		return properties
	var state: SceneState = scene.get_state()
	for index: int in range(state.get_node_count()):
		var path: String = String(state.get_node_path(index)).trim_prefix("./")
		if path != node_path:
			continue
		for property: int in range(state.get_node_property_count(index)):
			properties[String(state.get_node_property_name(index, property))] = (
				state.get_node_property_value(index, property)
			)
		return properties
	push_error("LevelReachability: nó %s ausente em %s" % [node_path, scene_path])
	return properties


static func _shape_size(properties: Dictionary) -> Vector2:
	var shape: Variant = properties.get("shape", null)
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size
	return Vector2.ZERO


func _run(parsed: Dictionary, meta: Dictionary, profile: Dictionary) -> Dictionary:
	_tile = float(Balance.TILE_SIZE)
	_width = int(parsed.get("width", 0))
	_height = int(parsed.get("height", 0))
	_half_width = float(profile.get("body_half_width", 7.0))
	_body_height = float(profile.get("body_height", 24.0))
	_claw_reach = float(profile.get("claw_reach", 10.0))
	_probe_heights = profile.get("claw_probe_heights", PackedFloat32Array([20.0, 4.0]))
	_clearance = float(profile.get("clearance", 24.0))
	_drop_nudge = float(profile.get("drop_nudge", 1.0))
	_pickup_half = float(profile.get("pickup_half", 6.0))
	_dt = 1.0 / float(profile.get("ticks", DEFAULT_TICKS))
	_jump_velocity = PlatformerMath.jump_velocity(Balance.JUMP_HEIGHT, Balance.GRAVITY, _dt)
	_wall_jump_velocity = -absf(
		PlatformerMath.jump_velocity(Balance.JUMP_HEIGHT, Balance.GRAVITY)
	)
	_build_grid(parsed, meta, profile)
	var spawn: Vector2i = parsed.get("spawn", Vector2i.ZERO)
	var spawn_feet: float = (spawn.y + 1) * _tile
	if _is_stand(spawn.x, spawn_feet):
		_enqueue_stand(spawn.x, spawn_feet)
	else:
		_simulate({"x": _column_center(spawn.x), "fy": spawn_feet, "on_floor": false})
	_drain()
	var plant_reports: Array[Dictionary] = []
	for plant: Dictionary in _plants:
		var top: int = int(roundf(float(plant["top"])))
		var reached: bool = false
		for column: int in range(int(plant["cell"].x) - 1, int(plant["cell"].x) + 2):
			reached = reached or _stands.has(Vector2i(column, top))
		plant_reports.append({
			"cell": plant["cell"], "offset": plant["offset"], "reached": reached
		})
	return {
		"parsed": parsed,
		"meta": meta,
		"width": _width,
		"height": _height,
		"stands": _stands,
		"touched": _touched,
		"platforms_reached": _platforms_reached.keys(),
		"plants": plant_reports,
		"rejected": _rejected,
		"jams": _jams,
		"body_height": _body_height,
	}


func _build_grid(parsed: Dictionary, meta: Dictionary, profile: Dictionary) -> void:
	_cells = PackedByteArray()
	_cells.resize(_width * _height)
	_touched = PackedByteArray()
	_touched.resize(_width * _height)
	for key: Variant in parsed.get("solids", {}) as Dictionary:
		var solid: Vector2i = key
		_cells[solid.y * _width + solid.x] = CELL_SOLID
	for cell: Vector2i in parsed.get("one_ways", []) as Array:
		_cells[cell.y * _width + cell.x] = CELL_ONE_WAY
	var meta_entities: Dictionary = meta.get("entities", {})
	for entry: Dictionary in parsed.get("entities", []) as Array:
		var symbol: String = String(entry.get("symbol", ""))
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if symbol == MAGNETIC_SYMBOL:
			_cells[cell.y * _width + cell.x] = CELL_MAGNETIC
		elif symbol == PLANT_SYMBOL:
			var plant_offset: float = float(profile.get("plant_top_offset", -64.0))
			_plants.append({
				"cell": cell,
				"x": _column_center(cell.x),
				"top": (cell.y + 1) * _tile + plant_offset,
				"half": float(profile.get("plant_half_width", 16.0)),
				"offset": plant_offset,
			})
		elif symbol == PLATFORM_SYMBOL:
			var params: Variant = meta_entities.get(LevelParser.cell_key(cell), {})
			var path: Variant = []
			if params is Dictionary:
				path = (params as Dictionary).get("path", [])
			_platforms.append(_platform_from(cell, path, profile))


func _platform_from(cell: Vector2i, path: Variant, profile: Dictionary) -> Dictionary:
	var origin := Vector2(_column_center(cell.x), cell.y * _tile + _tile * 0.5)
	var offsets: PackedVector2Array = MovingPlatform.points_from(path)
	var points := PackedVector2Array()
	if offsets.size() < 2:
		points.append(origin)
	else:
		for offset: Vector2 in offsets:
			points.append(origin + offset * _tile)
	var top_offset: float = float(profile.get("platform_top_offset", -4.0))
	var samples := PackedVector2Array()
	for index: int in range(points.size()):
		var start: Vector2 = points[index]
		samples.append(start + Vector2(0.0, top_offset))
		if index == points.size() - 1:
			break
		var finish: Vector2 = points[index + 1]
		var steps: int = maxi(1, int(ceilf(start.distance_to(finish) / PLATFORM_SAMPLE_STEP)))
		for step: int in range(1, steps):
			var point: Vector2 = start.lerp(finish, float(step) / float(steps))
			samples.append(point + Vector2(0.0, top_offset))
	var bounds := Rect2(samples[0], Vector2.ZERO)
	for sample: Vector2 in samples:
		bounds = bounds.expand(sample)
	return {
		"cell": cell,
		"samples": samples,
		"half": float(profile.get("platform_half_width", 24.0)),
		"bounds": bounds,
	}


func _drain() -> void:
	while true:
		_active_platform = -1
		if not _stand_queue.is_empty():
			var stand: Vector2i = _stand_queue.pop_back()
			_expand_stand(stand.x, float(stand.y))
		elif not _climb_queue.is_empty():
			_expand_climb(_climb_queue.pop_back())
		elif not _platform_queue.is_empty():
			_expand_platform(_platform_queue.pop_back())
		else:
			return


func _enqueue_stand(column: int, feet: float) -> void:
	var key := Vector2i(column, int(roundf(feet)))
	if _stands.has(key):
		return
	_stands[key] = _support_kind(_column_center(column), feet)
	_stand_queue.append(key)


func _enqueue_platform(index: int) -> void:
	if _platforms_reached.has(index):
		return
	_platforms_reached[index] = true
	_platform_queue.append(index)


func _enqueue_climb(wall: int, side: int, feet: float, actual_x: float) -> void:
	_climb_queue.append({"wall": wall, "side": side, "fy": feet, "x": actual_x})


func _expand_stand(column: int, feet: float) -> void:
	var x: float = _column_center(column)
	_touch(x, feet)
	var segment: Vector2i = _segment_for(column, feet)
	for direction: int in [-1, 1]:
		if _is_stand(column + direction, feet):
			_enqueue_stand(column + direction, feet)
		elif not _overlaps_solid(x + direction * _tile, feet):
			_launch_set(x, feet, direction, false, _is_stand(column - direction, feet), segment)
		_launch_set(x, feet, direction, true, _is_stand(column - direction, feet), segment)
		var wall: int = _magnetic_in_reach(x, feet, direction)
		if wall >= 0:
			_enqueue_climb(wall, -direction, feet, x)
	_simulate({"x": x, "fy": feet, "jump": true, "segment": segment, "start_fy": feet})
	if _one_way_below(x, feet):
		for direction: int in [-1, 0, 1]:
			_simulate({"x": x, "fy": feet, "drop": true, "axis": direction})


func _launch_set(
	x: float, feet: float, direction: int, jump: bool, can_run: bool, segment: Vector2i
) -> void:
	for release: int in RELEASE_FRAMES:
		var spec: Dictionary = {
			"x": x, "fy": feet, "axis": direction, "release": release, "jump": jump,
			"segment": segment, "start_fy": feet,
		}
		_simulate(spec)
		if can_run:
			var running: Dictionary = spec.duplicate()
			running["vx"] = direction * Balance.WALK_SPEED
			_simulate(running)


func _expand_platform(index: int) -> void:
	var platform: Dictionary = _platforms[index]
	var half: float = float(platform["half"])
	for sample: Vector2 in platform["samples"] as PackedVector2Array:
		var first: int = int(ceilf((sample.x - half - _tile * 0.5) / _tile))
		var last: int = int(floorf((sample.x + half - _tile * 0.5) / _tile))
		for column: int in range(first, last + 1):
			var x: float = _column_center(column)
			if _overlaps_solid(x, sample.y):
				continue
			_touch(x, sample.y)
			var base: Dictionary = {
				"x": x, "fy": sample.y, "platform": index, "platform_top": sample.y,
				"platform_x": sample.x,
			}
			for direction: int in [-1, 1]:
				for jump: bool in [false, true]:
					for release: int in RELEASE_FRAMES:
						var spec: Dictionary = base.duplicate()
						spec["axis"] = direction
						spec["release"] = release
						spec["jump"] = jump
						spec["vx"] = direction * Balance.WALK_SPEED
						_simulate(spec)
			var straight: Dictionary = base.duplicate()
			straight["jump"] = true
			_simulate(straight)
			for direction: int in [-1, 0, 1]:
				var drop: Dictionary = base.duplicate()
				drop["drop"] = true
				drop["axis"] = direction
				_simulate(drop)


func _expand_climb(entry: Dictionary) -> void:
	var wall: int = int(entry["wall"])
	var side: int = int(entry["side"])
	var feet: float = float(entry["fy"])
	var face: float = wall * _tile if side < 0 else (wall + 1) * _tile
	var x: float = face + side * _claw_reach
	if _overlaps_solid(x, feet):
		x = float(entry["x"])
		if _overlaps_solid(x, feet):
			return
	var top: float = feet
	var top_blocked: bool = false
	while true:
		var next: float = top - 1.0
		if _overlaps_solid(x, next):
			top_blocked = true
			break
		if not _touching_wall(x, next, wall):
			break
		top = next
	var bottom: float = feet
	var bottom_blocked: bool = false
	while true:
		if _support_kind(x, bottom) != SURFACE_NONE:
			bottom_blocked = true
			break
		var next: float = bottom + 1.0
		if _overlaps_solid(x, next):
			bottom_blocked = true
			break
		if not _touching_wall(x, next, wall):
			break
		bottom = next
	var key := Vector4i(wall, side, int(top), int(bottom))
	if _climbs.has(key):
		return
	_climbs[key] = true
	if top_blocked:
		_record_jam(x, top, wall, side)
	var sample: float = top
	while sample <= bottom:
		_climb_launches(x, sample, wall, side)
		sample += CLIMB_SAMPLE_STEP
	_climb_launches(x, bottom, wall, side)
	if not top_blocked:
		_release_fall(x, top, wall)
	if bottom_blocked:
		var column: int = floori(x / _tile)
		for candidate: int in [column, column + 1, column - 1]:
			if _is_stand(candidate, bottom):
				_enqueue_stand(candidate, bottom)
				break
	else:
		_release_fall(x, bottom, wall)


func _climb_launches(x: float, feet: float, wall: int, side: int) -> void:
	_touch(x, feet)
	var push: float = side * Balance.CLAW_JUMP_PUSH
	for axis: int in [0, side, -side]:
		for release: int in RELEASE_FRAMES:
			if axis == 0 and release >= 0:
				continue
			_simulate({
				"x": x, "fy": feet, "vx": push, "vy": _wall_jump_velocity, "wall_push": push,
				"on_floor": false, "pre_move": true, "axis": axis, "release": release,
				"skip_wall": wall,
			})


func _release_fall(x: float, feet: float, wall: int) -> void:
	for axis: int in [-1, 0, 1]:
		_simulate({"x": x, "fy": feet, "on_floor": false, "axis": axis, "skip_wall": wall})


func _record_jam(x: float, top: float, wall: int, side: int) -> void:
	var far: float = x + side * _half_width
	var column: int = floori((far - side * EPSILON) / _tile)
	var row: int = floori((top - _body_height - 1.0) / _tile)
	if _cell_kind(column, row) == CELL_EMPTY:
		return
	var flush: float = wall * _tile - _half_width
	if side > 0:
		flush = (wall + 1) * _tile + _half_width
	if _overlaps_solid(flush, top - 1.0):
		return
	_jams.append({"cell": Vector2i(wall, row), "blocking_column": column})


func _simulate(spec: Dictionary) -> void:
	var x: float = float(spec.get("x", 0.0))
	var fy: float = float(spec.get("fy", 0.0))
	var vx: float = float(spec.get("vx", 0.0))
	var vy: float = float(spec.get("vy", 0.0))
	var axis_dir: int = int(spec.get("axis", 0))
	var release: int = int(spec.get("release", -1))
	var wall_push: float = float(spec.get("wall_push", 0.0))
	var on_floor: bool = bool(spec.get("on_floor", true))
	var jump: bool = bool(spec.get("jump", false))
	var skip_wall: int = int(spec.get("skip_wall", -1))
	var start_x: float = x
	var airborne: bool = not on_floor
	var one_way_on: bool = true
	var drop_left: float = 0.0
	_active_platform = int(spec.get("platform", -1))
	_active_top = float(spec.get("platform_top", 0.0))
	_active_x = float(spec.get("platform_x", 0.0))
	if bool(spec.get("drop", false)):
		drop_left = Balance.DROP_THROUGH_TIME
		one_way_on = false
		fy += _drop_nudge
		on_floor = false
		airborne = true
	if bool(spec.get("pre_move", false)):
		var moved: Vector2 = _move_x(x, fy, vx * _dt)
		if moved.y != 0.0:
			vx = 0.0
		x = moved.x
		var first: Vector3 = _move_y(x, fy, vy * _dt, one_way_on)
		fy = first.x
		if first.y < 0.0:
			vy = 0.0
	for frame: int in range(MAX_SIM_FRAMES):
		var axis: float = float(axis_dir) if (release < 0 or frame < release) else 0.0
		if not one_way_on:
			drop_left -= _dt
			if drop_left <= 0.0:
				if _clearance_blocked(x, fy):
					drop_left = Balance.DROP_THROUGH_TIME
				else:
					one_way_on = true
		var rate: float = Balance.WALK_ACCEL if axis != 0.0 else Balance.WALK_DECEL
		if not on_floor:
			rate *= Balance.AIR_ACCEL_RATIO
		vx = PlatformerMath.approach(vx, axis * Balance.WALK_SPEED, rate * _dt)
		if wall_push != 0.0:
			if on_floor or axis != 0.0:
				wall_push = 0.0
			elif absf(vx) < absf(wall_push):
				vx = wall_push
		vy = PlatformerMath.clamp_fall(vy + Balance.GRAVITY * _dt, Balance.MAX_FALL_SPEED)
		if jump and frame == 0:
			vy = _jump_velocity
		var moved: Vector2 = _move_x(x, fy, vx * _dt)
		if moved.y != 0.0:
			vx = 0.0
		x = moved.x
		var old_fy: float = fy
		var step: Vector3 = _move_y(x, fy, vy * _dt, one_way_on)
		fy = step.x
		var surface: int = int(step.z)
		if step.y != 0.0:
			vy = 0.0
		if vy > 0.0 and one_way_on and surface == SURFACE_NONE:
			_detect_platforms(x, old_fy, fy)
		on_floor = surface != SURFACE_NONE
		_touch(x, fy)
		if fy > (_height + 2) * _tile:
			return
		if axis != 0.0:
			var direction: int = 1 if axis > 0.0 else -1
			var wall: int = _magnetic_in_reach(x, fy, direction)
			if wall >= 0 and wall != skip_wall:
				_enqueue_climb(wall, -direction, fy, x)
				return
		if not on_floor:
			airborne = true
			continue
		if airborne:
			_land(spec, x, fy, surface)
			return
		if absf(x - start_x) >= _tile:
			_land(spec, x, fy, surface)
			return
		if axis == 0.0 and absf(vx) < EPSILON and frame > 0 and not jump:
			return


func _land(spec: Dictionary, x: float, feet: float, surface: int) -> void:
	if surface == SURFACE_PLATFORM:
		_enqueue_platform(_active_platform)
		return
	var column: int = floori(x / _tile)
	if surface == SURFACE_ONE_WAY and spec.has("segment"):
		var rise: float = float(spec.get("start_fy", feet)) - feet
		if rise > Balance.JUMP_HEIGHT - _tile + EPSILON:
			var landing: Vector2i = _segment_under(x, feet)
			var start: Vector2i = spec["segment"]
			var overlap: int = mini(start.y, landing.y) - maxi(start.x, landing.x) + 1
			if overlap < MIN_STACK_OVERLAP_COLUMNS:
				_rejected.append({
					"cell": Vector2i(column, floori(feet / _tile) - 1),
					"overlap": maxi(0, overlap),
				})
				return
	for candidate: int in [column, column + 1, column - 1]:
		if _is_stand(candidate, feet):
			_enqueue_stand(candidate, feet)
			return


func _move_x(x: float, feet: float, dx: float) -> Vector2:
	if dx == 0.0:
		return Vector2(x, 0.0)
	var target: float = x + dx
	if not _overlaps_solid(target, feet):
		return Vector2(target, 0.0)
	var clamped: float = x
	if dx > 0.0:
		clamped = floori((target + _half_width - EPSILON) / _tile) * _tile - _half_width
	else:
		clamped = (floori((target - _half_width + EPSILON) / _tile) + 1) * _tile + _half_width
	if _overlaps_solid(clamped, feet) or (clamped - x) * dx < 0.0:
		clamped = x
	return Vector2(clamped, 1.0)


func _move_y(x: float, feet: float, dy: float, one_way_on: bool) -> Vector3:
	var target: float = feet + dy
	if dy > 0.0:
		var hit: Vector2 = _landing(x, feet, target, one_way_on)
		if hit.y != SURFACE_NONE:
			return Vector3(hit.x, 1.0, hit.y)
		return Vector3(target, 0.0, SURFACE_NONE)
	if dy < 0.0 and _overlaps_solid(x, target):
		var row: int = floori((target - _body_height + EPSILON) / _tile)
		var pushed: float = (row + 1) * _tile + _body_height
		if pushed > feet or _overlaps_solid(x, pushed):
			pushed = feet
		return Vector3(pushed, -1.0, SURFACE_NONE)
	return Vector3(target, 0.0, SURFACE_NONE)


func _landing(x: float, old_feet: float, new_feet: float, one_way_on: bool) -> Vector2:
	var best: float = INF
	var kind: int = SURFACE_NONE
	var first_column: int = floori((x - _half_width + EPSILON) / _tile)
	var last_column: int = floori((x + _half_width - EPSILON) / _tile)
	var first_row: int = ceili((old_feet - ONE_WAY_MARGIN) / _tile)
	var last_row: int = floori(new_feet / _tile)
	for row: int in range(first_row, last_row + 1):
		var top: float = row * _tile
		var found: int = SURFACE_NONE
		for column: int in range(first_column, last_column + 1):
			var cell: int = _cell_kind(column, row)
			if cell == CELL_SOLID or cell == CELL_MAGNETIC:
				found = SURFACE_SOLID
				break
			if cell == CELL_ONE_WAY and one_way_on:
				found = SURFACE_ONE_WAY
		if found != SURFACE_NONE:
			best = top
			kind = found
			break
	if one_way_on:
		for plant: Dictionary in _plants:
			var plant_top: float = float(plant["top"])
			if plant_top >= best or plant_top < old_feet - ONE_WAY_MARGIN or plant_top > new_feet:
				continue
			if absf(x - float(plant["x"])) < _half_width + float(plant["half"]):
				best = plant_top
				kind = SURFACE_PLANT
		if _active_platform >= 0:
			var half: float = float(_platforms[_active_platform]["half"])
			var inside: bool = absf(x - _active_x) < _half_width + half
			if inside and _active_top < best and _active_top >= old_feet - ONE_WAY_MARGIN:
				if _active_top <= new_feet:
					best = _active_top
					kind = SURFACE_PLATFORM
	return Vector2(best, kind)


func _detect_platforms(x: float, old_feet: float, new_feet: float) -> void:
	for index: int in range(_platforms.size()):
		if _platforms_reached.has(index):
			continue
		var platform: Dictionary = _platforms[index]
		var half: float = float(platform["half"]) + _half_width
		var bounds: Rect2 = platform["bounds"]
		if x <= bounds.position.x - half or x >= bounds.end.x + half:
			continue
		if new_feet < bounds.position.y or old_feet - ONE_WAY_MARGIN > bounds.end.y:
			continue
		var samples: PackedVector2Array = platform["samples"]
		for sample_index: int in range(samples.size()):
			var a: Vector2 = samples[sample_index]
			var b: Vector2 = samples[mini(sample_index + 1, samples.size() - 1)]
			var low: float = minf(a.y, b.y)
			var high: float = maxf(a.y, b.y)
			if maxf(old_feet - ONE_WAY_MARGIN, low) > minf(new_feet, high):
				continue
			if absf(x - a.x) < half or absf(x - b.x) < half:
				_enqueue_platform(index)
				break


func _support_kind(x: float, feet: float) -> int:
	var hit: Vector2 = _landing(x, feet, feet + EPSILON, true)
	if hit.y == SURFACE_NONE or absf(hit.x - feet) > EPSILON:
		return SURFACE_NONE
	return int(hit.y)


func _is_stand(column: int, feet: float) -> bool:
	if column < 0 or column >= _width:
		return false
	var x: float = _column_center(column)
	if _overlaps_solid(x, feet):
		return false
	var saved: int = _active_platform
	_active_platform = -1
	var kind: int = _support_kind(x, feet)
	_active_platform = saved
	return kind != SURFACE_NONE


func _segment_for(column: int, feet: float) -> Vector2i:
	for plant: Dictionary in _plants:
		if absf(float(plant["top"]) - feet) < EPSILON:
			var base: int = (plant["cell"] as Vector2i).x
			if absi(base - column) <= 1:
				return Vector2i(base - 1, base + 1)
	return _segment_under(_column_center(column), feet)


func _segment_under(x: float, feet: float) -> Vector2i:
	var row: int = roundi(feet / _tile)
	var column: int = floori(x / _tile)
	if not _is_surface(column, row):
		var left: int = floori((x - _half_width + EPSILON) / _tile)
		var right: int = floori((x + _half_width - EPSILON) / _tile)
		column = left if _is_surface(left, row) else right
	var first: int = column
	while _is_surface(first - 1, row):
		first -= 1
	var last: int = column
	while _is_surface(last + 1, row):
		last += 1
	return Vector2i(first, last)


func _is_surface(column: int, row: int) -> bool:
	if column < 0 or column >= _width:
		return false
	var below: int = _cell_kind(column, row)
	if below == CELL_EMPTY:
		return false
	var above: int = _cell_kind(column, row - 1)
	return above == CELL_EMPTY or above == CELL_ONE_WAY


func _one_way_below(x: float, feet: float) -> bool:
	var row: int = roundi(feet / _tile)
	if absf(row * _tile - feet) < EPSILON and _cell_kind(floori(x / _tile), row) == CELL_ONE_WAY:
		return true
	for plant: Dictionary in _plants:
		if absf(float(plant["top"]) - feet) < EPSILON:
			if absf(x - float(plant["x"])) <= float(plant["half"]):
				return true
	return false


func _clearance_blocked(x: float, feet: float) -> bool:
	var column: int = floori(x / _tile)
	var first: int = floori((feet - _clearance) / _tile)
	var last: int = floori((feet - EPSILON) / _tile)
	for row: int in range(first, last + 1):
		if _cell_kind(column, row) == CELL_ONE_WAY:
			return true
	for plant: Dictionary in _plants:
		var top: float = float(plant["top"])
		if top >= feet - _clearance and top <= feet:
			if absf(x - float(plant["x"])) <= float(plant["half"]):
				return true
	return false


func _magnetic_in_reach(x: float, feet: float, direction: int) -> int:
	var reach_end: float = x + direction * _claw_reach
	var first: int = floori(x / _tile)
	var last: int = floori((reach_end - direction * EPSILON) / _tile)
	for height: float in _probe_heights:
		var row: int = floori((feet - height) / _tile)
		var column: int = first
		while true:
			var kind: int = _cell_kind(column, row)
			if kind == CELL_MAGNETIC:
				return column
			if kind == CELL_SOLID or column == last:
				break
			column += direction
	return -1


func _touching_wall(x: float, feet: float, wall: int) -> bool:
	for height: float in _probe_heights:
		if _cell_kind(wall, floori((feet - height) / _tile)) == CELL_MAGNETIC:
			return true
	return false


func _overlaps_solid(x: float, feet: float) -> bool:
	var first_column: int = floori((x - _half_width + EPSILON) / _tile)
	var last_column: int = floori((x + _half_width - EPSILON) / _tile)
	var first_row: int = floori((feet - _body_height + EPSILON) / _tile)
	var last_row: int = floori((feet - EPSILON) / _tile)
	for row: int in range(first_row, last_row + 1):
		for column: int in range(first_column, last_column + 1):
			var kind: int = _cell_kind(column, row)
			if kind == CELL_SOLID or kind == CELL_MAGNETIC:
				return true
	return false


func _touch(x: float, feet: float) -> void:
	var first_column: int = maxi(0, floori((x - _half_width) / _tile))
	var last_column: int = mini(_width - 1, floori((x + _half_width) / _tile))
	var first_row: int = maxi(0, floori((feet - _body_height) / _tile))
	var last_row: int = mini(_height - 1, floori(feet / _tile))
	for row: int in range(first_row, last_row + 1):
		var center_y: float = row * _tile + _tile * 0.5
		if feet <= center_y - _pickup_half or feet - _body_height >= center_y + _pickup_half:
			continue
		for column: int in range(first_column, last_column + 1):
			var center_x: float = _column_center(column)
			if x + _half_width <= center_x - _pickup_half:
				continue
			if x - _half_width >= center_x + _pickup_half:
				continue
			_touched[row * _width + column] = 1


func _cell_kind(column: int, row: int) -> int:
	if column < 0 or row < 0 or column >= _width or row >= _height:
		return CELL_SOLID
	return _cells[row * _width + column]


func _column_center(column: int) -> float:
	return column * _tile + _tile * 0.5
