class_name ProtocolLuto
extends Node2D

const PLAYER_GROUP: StringName = &"player"
const NETWORK_GROUP: StringName = &"energy_network"
const POWERED_GROUP: StringName = &"powered"
const ENTITY_PREFIX: String = "entity:"
const LOGS_DIR: String = "res://data/logs/"
const META_KEY: String = "protocol"
const LUTO_DIALOGUE: StringName = &"mem_luto"
const WARNING_SFX: StringName = &"ui_error"
const SWAP_SFX: StringName = &"power_off"
const HIT_SFX: StringName = &"damage"
const SIGNAL_SFX: StringName = &"log_pickup"
const BLINK_HZ: float = 10.0
const BLINK_COLOR: Color = Color("ff5fa8")
const OCCLUDER_REBUILD_TIME: float = 0.25
const BODY_CENTER: Vector2 = Vector2(0, -12)
const HEADER_SEPARATOR: String = " · "
const EYE_ABOVE: float = 104.0
const EYE_MARGIN: float = 112.0
const EYE_TRAIL: float = 96.0
const EYE_CONTENT_HALF_HEIGHT: float = 28.0
const HUD_BAND_BOTTOM: float = 40.0
const FRAME_UNKNOWN: int = -1
const FRAME_LEVEL: int = 0
const FRAME_HALL: int = 1

var _level: Node2D = null
var _solid: TileMapLayer = null
var _background: TileMapLayer = null
var _entities: Node2D = null
var _ambient: CanvasModulate = null
var _config: Dictionary = {}
var _protocol: MemoryProtocol = null
var _firewall: FirewallLogic = null
var _recall: RecallLogic = null
var _fronts: Dictionary = {}
var _fields: Dictionary = {}
var _erased: Dictionary = {}
var _erased_cells: Dictionary = {}
var _hidden: Dictionary = {}
var _settling: Array[int] = []
var _solids: Dictionary = {}
var _occluders_dirty: bool = false
var _occluder_wait: float = 0.0
var _delay_left: float = 0.0
var _sessions: Dictionary = {}
var _blinking: Array[Node] = []
var _blink_clock: float = 0.0
var _lines: PackedStringArray = []
var _log_id: StringName = &""
var _log_open: bool = false
var _eye: LutoEye = null
var _tint: MemoryTint = null
var _overlay: MemoryOverlay = null
var _signal: EarthSignal = null
var _ambient_tween: Tween = null
var _ready_done: bool = false
var _frame_state: int = FRAME_UNKNOWN


func _ready() -> void:
	_setup.call_deferred()


func _physics_process(delta: float) -> void:
	if not _ready_done or _protocol == null or _protocol.is_done():
		return
	var player: CharacterBody2D = _player()
	if player == null or bool(player.call(&"is_dead")):
		return
	_settle(delta)
	match _protocol.phase:
		MemoryProtocol.Phase.DORMANT:
			_try_start(player)
		MemoryProtocol.Phase.ASCENT:
			_step_ascent(player, delta)
		MemoryProtocol.Phase.FIREWALL:
			_step_firewall(player, delta)
		MemoryProtocol.Phase.RECALL:
			_step_recall(player, delta)
	_frame_camera(player)
	_drift_eye(player, delta)
	_tick_occluders(delta)


func protocol() -> MemoryProtocol:
	return _protocol


func phase() -> int:
	return int(_protocol.phase) if _protocol != null else -1


func completed_phases() -> int:
	return _protocol.completed if _protocol != null else 0


func front_position(which: int) -> float:
	var front: EraseFront = _fronts.get(which, null)
	return front.position if front != null else 0.0


func erased_count() -> int:
	return _erased_cells.size()


func pending_swap() -> String:
	return String(_firewall.pending()) if _firewall != null else ""


func recall_opened() -> int:
	return _recall.opened if _recall != null else 0


func overlay_line() -> String:
	return _overlay.current_line() if _overlay != null else ""


func desaturation() -> float:
	return _tint.amount if _tint != null else 0.0


func final_log_collected() -> bool:
	return _log_id != &"" and GameState.logs_collected.has(_log_id)


func signal_visible() -> bool:
	return _signal != null and _signal.visible


func is_hall_framed() -> bool:
	return _frame_state == FRAME_HALL


func eye_screen_top() -> float:
	if _eye == null:
		return -1.0
	var view: Transform2D = get_viewport().get_canvas_transform()
	return (view * _eye.global_position).y - EYE_CONTENT_HALF_HEIGHT


func eye_clear_of_hud() -> bool:
	if _eye == null or not _eye.visible:
		return true
	return eye_screen_top() >= HUD_BAND_BOTTOM


func _setup() -> void:
	_level = get_parent() as Node2D
	if _level == null or not _level.has_method(&"meta_value"):
		push_warning("ProtocolLuto: fora de uma fase")
		return
	var raw: Variant = _level.call(&"meta_value", META_KEY)
	if not (raw is Dictionary):
		push_warning("ProtocolLuto: fase sem bloco 'protocol'")
		return
	_config = raw
	_solid = _level.get_node_or_null(^"Solid") as TileMapLayer
	_background = _level.get_node_or_null(^"Background") as TileMapLayer
	_entities = _level.get_node_or_null(^"Entities") as Node2D
	_ambient = _level.get_node_or_null(^"CanvasModulate") as CanvasModulate
	var restored: bool = GameState.sectors_restored.has(MemoryProtocol.SECTOR_ID)
	_protocol = MemoryProtocol.create(MemoryProtocol.saved_progress(GameState.flags), restored)
	_firewall = FirewallLogic.create(
		StringName(String(_config.get("luto_system", ""))), Balance.FIREWALL_SWAP_DELAY
	)
	_read_solids()
	_build_fronts()
	_build_eye()
	_tint = MemoryTint.new()
	_tint.name = "MemoryTint"
	add_child(_tint)
	_overlay = MemoryOverlay.new()
	_overlay.name = "MemoryOverlay"
	add_child(_overlay)
	for erased_phase: int in _protocol.phases_already_erased():
		_erase_whole_phase(erased_phase)
	_apply_stage(true)
	_place_eye()
	EventBus.energy_changed.connect(_on_energy_changed)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.sector_restored.connect(_on_sector_restored)
	EventBus.sector_cutscene_started.connect(_on_cutscene_started)
	EventBus.sector_cutscene_finished.connect(_on_cutscene_finished)
	AudioManager.stop_music()
	_ready_done = true


func _read_solids() -> void:
	if _solid == null:
		return
	for cell: Vector2i in _solid.get_used_cells():
		if _solid.get_cell_atlas_coords(cell) == LevelBuilder.ONE_WAY_TILE:
			continue
		_solids[cell] = true


func _build_fronts() -> void:
	for which: int in MemoryProtocol.PHASE_ORDER:
		var block: Dictionary = _phase_config(which)
		if block.is_empty():
			continue
		var front: EraseFront = EraseFront.from_config(block, Balance.TILE_SIZE)
		_fronts[which] = front
		var field := StaticField.new()
		field.name = "Static_%s" % MemoryProtocol.key_of(which)
		field.front = front
		add_child(field)
		_fields[which] = field
		_erased[which] = []
		_hidden[which] = []


func _build_eye() -> void:
	_eye = LutoEye.new()
	_eye.name = "LutoEye"
	add_child(_eye)
	_eye.visible = false


func _phase_config(which: int) -> Dictionary:
	var value: Variant = _config.get(MemoryProtocol.key_of(which), {})
	return value if value is Dictionary else {}


func _player() -> CharacterBody2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(PLAYER_GROUP) as CharacterBody2D


func _frozen(player: CharacterBody2D) -> bool:
	return bool(player.call(&"is_input_locked"))


func _rect_px(value: Variant) -> Rect2:
	if not (value is Array) or (value as Array).size() < 4:
		return Rect2()
	var raw: Array = value
	var tile: float = float(Balance.TILE_SIZE)
	return Rect2(
		float(raw[0]) * tile, float(raw[1]) * tile, float(raw[2]) * tile, float(raw[3]) * tile
	)


func _inside(value: Variant, point: Vector2) -> bool:
	return _rect_px(value).has_point(point)


func _feet(player: CharacterBody2D) -> Vector2:
	return player.global_position - Vector2(0, 1)


func _try_start(player: CharacterBody2D) -> void:
	var upcoming: MemoryProtocol.Phase = _protocol.next_phase()
	if upcoming == MemoryProtocol.Phase.DONE:
		return
	var block: Dictionary = _phase_config(upcoming)
	if _protocol.try_start(_inside(block.get("trigger", []), _feet(player))):
		_begin_phase(upcoming)


func _begin_phase(which: int) -> void:
	var front: EraseFront = _fronts.get(which, null)
	if front != null:
		front.reset()
	_delay_left = Balance.MEMORY_FRONT_DELAY
	_settling.erase(int(which))
	_apply_stage(false)
	_place_eye()
	match which:
		MemoryProtocol.Phase.ASCENT:
			DialogueManager.play(LUTO_DIALOGUE)
		MemoryProtocol.Phase.FIREWALL:
			_firewall.cancel()
			_sessions.clear()
		MemoryProtocol.Phase.RECALL:
			_begin_recall()


func _step_ascent(player: CharacterBody2D, delta: float) -> void:
	if _frozen(player):
		return
	var front: EraseFront = _fronts[MemoryProtocol.Phase.ASCENT]
	var previous: float = front.position
	if _delay_left > 0.0:
		_delay_left -= delta
	else:
		front.advance(Balance.MEMORY_ASCENT_SPEED * delta)
		front.follow(player.global_position, Balance.MEMORY_ASCENT_LEAD)
	_swallow(MemoryProtocol.Phase.ASCENT, previous)
	if front.covers(_feet(player), Balance.MEMORY_HIT_GRACE):
		_memory_hit(MemoryProtocol.Phase.ASCENT, player)
		return
	if _inside(_phase_config(MemoryProtocol.Phase.ASCENT).get("finish", []), _feet(player)):
		_complete(MemoryProtocol.Phase.ASCENT)


func _step_firewall(player: CharacterBody2D, delta: float) -> void:
	_watch_sessions()
	var target: StringName = _firewall.tick(delta)
	if target != &"":
		_perform_swap(target)
	_update_blink(delta)
	if _frozen(player):
		return
	var front: EraseFront = _fronts[MemoryProtocol.Phase.FIREWALL]
	var previous: float = front.position
	if _delay_left > 0.0:
		_delay_left -= delta
	else:
		front.advance(Balance.MEMORY_SWEEP_SPEED * delta)
	_swallow(MemoryProtocol.Phase.FIREWALL, previous)
	var body: Vector2 = player.global_position + BODY_CENTER
	if front.covers(body, Balance.MEMORY_HIT_GRACE) or _in_void(_feet(player)):
		_memory_hit(MemoryProtocol.Phase.FIREWALL, player)
		return
	if _inside(_phase_config(MemoryProtocol.Phase.FIREWALL).get("finish", []), _feet(player)):
		_complete(MemoryProtocol.Phase.FIREWALL)


func _step_recall(player: CharacterBody2D, delta: float) -> void:
	if _recall == null or _frozen(player):
		return
	_recall.tick(delta)
	var x: float = player.global_position.x
	if _recall.next_line_ready(x, _overlay.is_typing_done()):
		var index: int = _recall.open_next()
		if index >= 0 and index < _lines.size():
			_overlay.show_line(_lines[index])
			_overlay.pick_memory()
			player.call(&"shake", Balance.SHAKE_DAMAGE)
			_eye.flinch()
	var step: float = _recall.push_step(x, delta)
	if not is_zero_approx(step):
		player.move_and_collide(Vector2(step, 0.0))
	_overlay.set_flash(_recall.flash_ratio())
	var front: EraseFront = _fronts[MemoryProtocol.Phase.RECALL]
	var previous: float = front.position
	front.follow(player.global_position, Balance.RECALL_TRAIL)
	_swallow(MemoryProtocol.Phase.RECALL, previous)
	if _recall.is_complete() and _overlay.is_typing_done():
		_complete(MemoryProtocol.Phase.RECALL)


func _begin_recall() -> void:
	var block: Dictionary = _phase_config(MemoryProtocol.Phase.RECALL)
	_log_id = StringName(String(block.get("log", "")))
	var data: Dictionary = _log_data(_log_id)
	_lines = LogCatalog.lines_of(data)
	var tile: float = float(Balance.TILE_SIZE)
	var half: float = tile * 0.5
	_recall = RecallLogic.create(
		float(block.get("line_start", 0)) * tile + half,
		float(block.get("line_end", 0)) * tile + half,
		_lines.size()
	)
	GameState.register_pickup(PickupRules.KIND_LOG, _log_id)
	EventBus.log_opened.emit(_log_id)
	_log_open = true
	var header: String = String(data.get("title", ""))
	var subtitle: String = String(data.get("subtitle", ""))
	if not subtitle.is_empty():
		header += HEADER_SEPARATOR + subtitle
	_overlay.open(header)


func _log_data(log_id: StringName) -> Dictionary:
	var level_id: String = String(_level.get(&"level_id"))
	var path: String = LOGS_DIR + level_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return {}
	for value: Variant in (parsed as Dictionary).get("logs", []) as Array:
		if value is Dictionary and StringName(String((value as Dictionary).get("id", ""))) == log_id:
			return value
	return {}


func _close_log() -> void:
	if not _log_open:
		return
	_log_open = false
	EventBus.log_closed.emit(_log_id)


func _complete(which: int) -> void:
	_protocol.complete_current()
	GameState.flags[MemoryProtocol.FLAG_KEY] = _protocol.completed
	if not _settling.has(int(which)):
		_settling.append(int(which))
	match which:
		MemoryProtocol.Phase.FIREWALL:
			_firewall.cancel()
			_stop_blink()
			_eye.release()
		MemoryProtocol.Phase.RECALL:
			_close_log()
			_eye.close_eye()
	_apply_stage(false)
	_place_eye()


func _settle(delta: float) -> void:
	for value: int in _settling.duplicate():
		var which: int = value as MemoryProtocol.Phase
		var front: EraseFront = _fronts.get(which, null)
		if front == null or front.is_done() or which == MemoryProtocol.Phase.RECALL:
			_settling.erase(value)
			continue
		var previous: float = front.position
		front.advance(Balance.MEMORY_ASCENT_SPEED * 2.0 * delta)
		_swallow(value, previous)


func _swallow(which: int, previous: float) -> void:
	var front: EraseFront = _fronts.get(which, null)
	if front == null or is_equal_approx(previous, front.position):
		return
	var cells: Array[Vector2i] = front.newly_swallowed(previous)
	if cells.is_empty():
		return
	var solid_cells: Array[Vector2i] = []
	for cell: Vector2i in cells:
		if _erase_cell(which, cell):
			solid_cells.append(cell)
	var field: StaticField = _fields.get(which, null)
	if field != null:
		field.burst(solid_cells)
	_hide_entities(which, front)


func _erase_cell(which: int, cell: Vector2i) -> bool:
	if _solid == null:
		return false
	if _erased_cells.has(cell):
		return false
	_erased_cells[cell] = true
	var record: Dictionary = {
		"cell": cell,
		"solid_source": _solid.get_cell_source_id(cell),
		"solid": _solid.get_cell_atlas_coords(cell),
		"back_source": _background.get_cell_source_id(cell) if _background != null else -1,
		"back": _background.get_cell_atlas_coords(cell) if _background != null else Vector2i(-1, -1),
	}
	(_erased[which] as Array).append(record)
	var had_solid: bool = int(record["solid_source"]) != -1
	if had_solid:
		_solid.erase_cell(cell)
		if _solids.erase(cell):
			_occluders_dirty = true
	if _background != null:
		_background.erase_cell(cell)
	return had_solid


func _erase_whole_phase(which: int) -> void:
	var front: EraseFront = _fronts.get(which, null)
	if front == null:
		return
	var previous: float = front.start
	front.finish()
	for cell: Vector2i in front.newly_swallowed(previous):
		_erase_cell(which, cell)
	_hide_entities(which, front)
	_rebuild_occluders()


func _restore_phase(which: int) -> void:
	for value: Variant in _erased.get(which, []) as Array:
		var record: Dictionary = value
		var cell: Vector2i = record["cell"]
		_erased_cells.erase(cell)
		if int(record["solid_source"]) != -1:
			_solid.set_cell(cell, int(record["solid_source"]), record["solid"])
			if record["solid"] != LevelBuilder.ONE_WAY_TILE:
				_solids[cell] = true
				_occluders_dirty = true
		if _background != null and int(record["back_source"]) != -1:
			_background.set_cell(cell, int(record["back_source"]), record["back"])
	_erased[which] = []
	for node: Variant in _hidden.get(which, []) as Array:
		if is_instance_valid(node):
			(node as Node).process_mode = Node.PROCESS_MODE_INHERIT
			(node as CanvasItem).visible = true
	_hidden[which] = []
	var front: EraseFront = _fronts.get(which, null)
	if front != null:
		front.reset()
	var field: StaticField = _fields.get(which, null)
	if field != null:
		field.clear_bursts()
	_settling.erase(int(which))


func _hide_entities(which: int, front: EraseFront) -> void:
	if _entities == null:
		return
	var hidden: Array = _hidden[which]
	var tile: float = float(Balance.TILE_SIZE)
	for child: Node in _entities.get_children():
		var item := child as Node2D
		if item == null or hidden.has(item) or not item.visible:
			continue
		var cell := Vector2i(
			int(floor(item.position.x / tile)), int(floor((item.position.y - 1.0) / tile))
		)
		if not front.is_cell_swallowed(cell):
			continue
		item.visible = false
		item.process_mode = Node.PROCESS_MODE_DISABLED
		hidden.append(item)


func _tick_occluders(delta: float) -> void:
	if not _occluders_dirty:
		return
	_occluder_wait -= delta
	if _occluder_wait > 0.0:
		return
	_rebuild_occluders()


func _rebuild_occluders() -> void:
	_occluders_dirty = false
	_occluder_wait = OCCLUDER_REBUILD_TIME
	if _solid == null:
		return
	LevelBuilder.build_occluders({"solids": _solids}, _solid)


func _memory_hit(which: int, player: CharacterBody2D) -> void:
	AudioManager.play_sfx(HIT_SFX)
	GameState.apply_damage(Balance.MEMORY_HIT_DAMAGE)
	player.call(&"shake", Balance.SHAKE_DAMAGE)
	_overlay.pick_memory()
	_overlay.set_flash(1.0)
	var tween: Tween = create_tween()
	tween.tween_method(_overlay.set_flash, 1.0, 0.0, Balance.RECALL_FLASH_TIME)
	_abort(which)
	if GameState.is_dead():
		return
	var dock: Node2D = _entity(String(_phase_config(which).get("dock", "")))
	if dock == null:
		return
	if dock.has_method(&"spawn_position"):
		player.global_position = dock.call(&"spawn_position")
	else:
		player.global_position = dock.global_position
	player.velocity = Vector2.ZERO
	player.call(&"snap_camera")


func _abort(which: int) -> void:
	_protocol.abort_current()
	_restore_phase(which)
	if which == MemoryProtocol.Phase.FIREWALL:
		_firewall.cancel()
		_stop_blink()
		_sessions.clear()
	_eye.release()
	_rebuild_occluders()
	_apply_stage(false)
	_place_eye()


func _in_void(point: Vector2) -> bool:
	for rect: Variant in _phase_config(MemoryProtocol.Phase.FIREWALL).get("void", []) as Array:
		if _inside(rect, point):
			return true
	return false


func _watch_sessions() -> void:
	for value: Variant in _config.get("consoles", []) as Array:
		var console_id: String = String(value)
		var console: Node = _entity(console_id)
		if console == null or not console.has_method(&"is_open"):
			continue
		var open: bool = bool(console.call(&"is_open"))
		var was_open: bool = bool(_sessions.get(console_id, false))
		_sessions[console_id] = open
		if open and not was_open:
			_firewall.begin_session()
		elif was_open and not open:
			var target: StringName = _firewall.end_session()
			if target != &"":
				_start_warning(target)


func _start_warning(target: StringName) -> void:
	_stop_blink()
	_blinking = _bound_nodes(target)
	_blink_clock = 0.0
	AudioManager.play_sfx(WARNING_SFX)
	var target_node: Node2D = _nearest_to_player(_blinking)
	if target_node != null:
		_eye.aim(target_node.global_position)


func _nearest_to_player(nodes: Array[Node]) -> Node2D:
	var player: CharacterBody2D = _player()
	var best: Node2D = null
	var best_distance: float = INF
	for node: Node in nodes:
		var item := node as Node2D
		if item == null:
			continue
		var distance: float = 0.0
		if player != null:
			distance = item.global_position.distance_squared_to(player.global_position)
		if best == null or distance < best_distance:
			best = item
			best_distance = distance
	return best


func _update_blink(delta: float) -> void:
	if _blinking.is_empty():
		return
	_blink_clock += delta
	var lit: bool = int(_blink_clock * BLINK_HZ) % 2 == 0
	for node: Node in _blinking:
		if is_instance_valid(node) and node is CanvasItem:
			(node as CanvasItem).modulate = BLINK_COLOR if lit else Color.WHITE


func _stop_blink() -> void:
	for node: Node in _blinking:
		if is_instance_valid(node) and node is CanvasItem:
			(node as CanvasItem).modulate = Color.WHITE
	_blinking.clear()


func _perform_swap(target: StringName) -> void:
	var network: EnergyNetwork = _network()
	var terminal: StringName = StringName(String(_config.get("terminal", "")))
	_stop_blink()
	_eye.release()
	if network == null:
		return
	var plan: Array[StringName] = FirewallLogic.swap_plan(
		network.grid(terminal), target, _firewall.luto_system
	)
	if plan.is_empty():
		return
	_firewall.begin_acting()
	for system_id: StringName in plan:
		network.toggle(terminal, system_id)
	_firewall.end_acting()
	AudioManager.play_sfx(SWAP_SFX)


func _bound_nodes(system_id: StringName) -> Array[Node]:
	var result: Array[Node] = []
	var terminal: StringName = StringName(String(_config.get("terminal", "")))
	for node: Node in get_tree().get_nodes_in_group(POWERED_GROUP):
		if StringName(String(node.get(&"terminal_id"))) != terminal:
			continue
		if StringName(String(node.get(&"system_id"))) != system_id:
			continue
		result.append(node)
	return result


func _network() -> EnergyNetwork:
	return get_tree().get_first_node_in_group(NETWORK_GROUP) as EnergyNetwork


func _entity(entity_id: String) -> Node2D:
	if entity_id.is_empty():
		return null
	for node: Node in get_tree().get_nodes_in_group(StringName(ENTITY_PREFIX + entity_id)):
		if node is Node2D:
			return node
	return null


func _apply_stage(instant: bool) -> void:
	_tint.set_amount(_protocol.desaturation(), instant)
	var colors: Variant = _config.get("ambient", {})
	if _ambient == null or not (colors is Dictionary):
		return
	var text: String = String((colors as Dictionary).get(_protocol.ambient_key(), ""))
	if text.is_empty():
		return
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	if instant:
		_ambient.color = Color(text)
		return
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient, ^"color", Color(text), Balance.MEMORY_COLOR_FADE_TIME)


func _place_eye() -> void:
	if _eye == null:
		return
	var stage: MemoryProtocol.Phase = _protocol.stage()
	if stage == MemoryProtocol.Phase.DORMANT or stage == MemoryProtocol.Phase.DONE:
		_eye.visible = false
		return
	var at: Vector2 = _eye_cell(stage)
	if at == Vector2.ZERO:
		_eye.visible = false
		return
	_eye.place(at)
	_eye.visible = true
	if _protocol.awaits_node():
		_eye.close_eye()


func _drift_eye(player: CharacterBody2D, delta: float) -> void:
	if _eye == null or not _eye.visible or _protocol.awaits_node():
		return
	var base: Vector2 = _eye_cell(_protocol.stage())
	var target: Vector2 = base
	match _protocol.phase:
		MemoryProtocol.Phase.ASCENT:
			target = Vector2(base.x, maxf(base.y, player.global_position.y - EYE_ABOVE))
		MemoryProtocol.Phase.FIREWALL:
			var area: Rect2 = (_fronts[MemoryProtocol.Phase.FIREWALL] as EraseFront).region_px()
			var margin: float = EYE_MARGIN
			var behind: float = player.global_position.x - EYE_TRAIL
			target.x = clampf(behind, area.position.x + margin, area.end.x - margin)
		_:
			return
	_eye.drift_to(target, delta)


func _frame_camera(player: CharacterBody2D) -> void:
	var wanted: int = FRAME_HALL if _wants_hall_frame(player) else FRAME_LEVEL
	if wanted == _frame_state:
		return
	_frame_state = wanted
	if not player.has_method(&"set_camera_limits") or not _level.has_method(&"camera_rect"):
		return
	var rect: Rect2i = _level.call(&"camera_rect")
	if wanted == FRAME_HALL:
		var rows: Array = _phase_config(MemoryProtocol.Phase.FIREWALL).get("camera", []) as Array
		var tile: float = float(Balance.TILE_SIZE)
		var top: int = int(float(rows[0]) * tile)
		var bottom: int = int(float(rows[1]) * tile)
		rect = Rect2i(rect.position.x, top, rect.size.x, bottom - top)
	player.call(&"set_camera_limits", rect)


func _wants_hall_frame(player: CharacterBody2D) -> bool:
	if _protocol.next_phase() != MemoryProtocol.Phase.FIREWALL:
		return false
	var block: Dictionary = _phase_config(MemoryProtocol.Phase.FIREWALL)
	var rows: Variant = block.get("camera", [])
	if not (rows is Array) or (rows as Array).size() < 2:
		return false
	return _inside(block.get("frame", []), _feet(player))


func _eye_cell(stage: int) -> Vector2:
	var cell: Variant = _phase_config(stage).get("eye", [])
	if not (cell is Array) or (cell as Array).size() < 2:
		return Vector2.ZERO
	var tile: float = float(Balance.TILE_SIZE)
	var raw: Array = cell
	return Vector2(float(raw[0]) * tile + tile * 0.5, float(raw[1]) * tile + tile * 0.5)


func _on_energy_changed(terminal_id: StringName, system_id: StringName, on: bool) -> void:
	if _firewall == null:
		return
	if terminal_id != StringName(String(_config.get("terminal", ""))):
		return
	_firewall.note_change(system_id, on)


func _on_player_respawned() -> void:
	_frame_state = FRAME_UNKNOWN
	if _protocol == null or not _protocol.is_active():
		return
	var which: int = _protocol.phase
	if which == MemoryProtocol.Phase.RECALL:
		return
	_abort(which)


func _on_sector_restored(sector_id: StringName) -> void:
	if sector_id != MemoryProtocol.SECTOR_ID or _protocol == null:
		return
	_close_log()
	_protocol.finish()
	GameState.flags[MemoryProtocol.FLAG_KEY] = _protocol.completed
	GameState.flags[MemoryProtocol.EARTH_FLAG] = true
	GameState.unlock_ability(MemoryProtocol.ROOT_ABILITY)
	_firewall.cancel()
	_stop_blink()
	_overlay.close()
	_eye.close_eye()


func _on_cutscene_started(sector_id: StringName) -> void:
	if sector_id != MemoryProtocol.SECTOR_ID:
		return
	for which: int in MemoryProtocol.PHASE_ORDER:
		_restore_phase(which)
	_rebuild_occluders()
	for field: Variant in _fields.values():
		var item := field as StaticField
		if item != null:
			item.front.reset()
	_tint.set_amount(0.0, false)
	var tween: Tween = create_tween()
	tween.tween_property(_eye, ^"modulate:a", 0.0, Balance.MEMORY_COLOR_FADE_TIME)


func _on_cutscene_finished(sector_id: StringName) -> void:
	if sector_id != MemoryProtocol.SECTOR_ID or _signal != null:
		return
	_signal = EarthSignal.new()
	_signal.name = "EarthSignal"
	add_child(_signal)
	AudioManager.play_sfx(SIGNAL_SFX)
