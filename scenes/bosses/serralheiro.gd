class_name Serralheiro
extends Node2D

enum ClawFrame { OPEN, PLATE, WELD, OFF }

const TROLLEY_SHEET: String = "res://assets/sprites/bosses/serralheiro_trolley.png"
const UPPER_TEXTURE: String = "res://assets/sprites/bosses/serralheiro_upper.png"
const LOWER_TEXTURE: String = "res://assets/sprites/bosses/serralheiro_lower.png"
const CLAW_SHEET: String = "res://assets/sprites/bosses/serralheiro_claw.png"
const BAY_SHEET: String = "res://assets/sprites/world/lock_bay.png"
const RAIL_TEXTURE: String = "res://assets/sprites/world/lock_rail.png"
const LAMP_SHEET: String = "res://assets/sprites/world/lock_lamp.png"
const PLATE_TEXTURE: String = "res://assets/sprites/world/lock_plate.png"
const HATCH_TEXTURE: String = "res://assets/sprites/world/lock_hatch.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const GATE_SCENE: String = "res://scenes/world/lock_gate.tscn"
const VACUUM_SCENE: String = "res://scenes/world/vacuum_zone.tscn"
const SR3_SCENE: String = "res://scenes/enemies/sr3.tscn"
const DEFEATED_FLAG: String = "lock_serralheiro_down"
const SECTOR_ID: StringName = &"docks"
const VICTORY_DIALOGUE: StringName = &"lock_down"
const SPAWN_GROUP: StringName = &"lock_spawn"
const PLAYER_GROUP: StringName = &"player"
const ENTITY_PREFIX: String = "entity:"
const GATE_ID: StringName = &"lock_gate_floor"
const HATCH_ID: StringName = &"lock_hatch_entry"
const VENT_ID: StringName = &"lock_vent"
const PLAYER_MASK: int = 2
const SETTLE_FRAMES: int = 2
const OFF_FOREVER: float = 1.0e9
const TROLLEY_FRAME: Vector2i = Vector2i(64, 40)
const CLAW_FRAME: Vector2i = Vector2i(48, 48)
const BAY_FRAME: Vector2i = Vector2i(32, 32)
const TROLLEY_DROP: float = 22.0
const SHOULDER_DROP: float = 13.0
const SEGMENT_LENGTH: float = 72.0
const REACH_SLACK: float = 6.0
const CLAW_PLATE_DROP: float = 46.0
const IDLE_WRIST_DROP: float = 18.0
const OFF_WRIST_DROP: float = 120.0
const VENT_WRIST_DROP: float = 8.0
const WRIST_SPEED: float = 220.0
const OFF_WRIST_SPEED: float = 40.0
const ROD_WIDTH: float = 4.0
const ROD_EDGE_WIDTH: float = 6.0
const ROD_COLOR: Color = Color("8c96a0")
const ROD_EDGE: Color = Color("0e1218")
const EYE_COLOR: Color = Color("ffb46a")
const EYE_RADIUS: float = 96.0
const EYE_ENERGY: float = 1.0
const EYE_PULSE_HZ: float = 6.0
const WELD_COLOR: Color = Color("ff8a3a")
const WELD_RADIUS: float = 64.0
const WELD_ENERGY: float = 1.3
const SPARK_COLOR: Color = Color("fff2c0")
const LAMP_AMBER: Color = Color(1.0, 0.7, 0.32)
const LAMP_BLINK_HZ: float = 3.0
const LAMP_BLINK_LEFT: int = 2
const SHAKE_PIXELS: float = 2.0
const BAY_OPEN_TIME: float = 0.8
const SPAWN_DROP: float = 30.0
const PLATE_FALL: float = 40.0
const PLATE_FALL_TIME: float = 0.7
const HATCH_FLY: Vector2 = Vector2(18.0, 72.0)
const HATCH_FLY_TIME: float = 0.8
const NODE_LAMP_SIZE: float = 4.0
const NODE_LAMP_GAP: float = 4.0
const NODE_LAMP_HEIGHT: float = 38.0
const NODE_LAMP_OFF: Color = Color("ff4a3a")
const NODE_LAMP_ON: Color = Color("5fe8ff")
const NODE_LAMP_EDGE: Color = Color("0e1218")
const VICTORY_DELAY: float = 1.2
const CAMERA_FLOOR_MARGIN: float = 8.0
const CAMERA_WALL: float = 80.0
const LEVEL_GROUP: StringName = &"level"
const Z_RAIL: int = -6
const Z_BAY: int = -5
const Z_LAMP: int = -5
const Z_UPPER: int = -4
const Z_LOWER: int = -3
const Z_CLAW: int = -1
const Z_TROLLEY: int = -1
const Z_SPARKS: int = 1
const Z_PLATE: int = 1

@export var serralheiro_id: StringName = &""

var _params: Dictionary = {}
var _fight: LockEncounter = LockEncounter.new()
var _coupler_ids: Array[StringName] = []
var _couplers: Dictionary = {}
var _node: Interactable = null
var _node_id: String = ""
var _gate: LockGate = null
var _hatch: LockGate = null
var _vent: VacuumZone = null
var _vent_hatch: Sprite2D = null
var _vent_home: Vector2 = Vector2.ZERO
var _bays: Array[Sprite2D] = []
var _bay_points: Array[Vector2] = []
var _bay_open: Array[float] = []
var _lamps: Array[Sprite2D] = []
var _rail: Node2D = null
var _trolley: Sprite2D = null
var _upper: Sprite2D = null
var _lower: Sprite2D = null
var _rod_edge: Line2D = null
var _rod: Line2D = null
var _claw: Sprite2D = null
var _eye: PointLight2D = null
var _weld: PointLight2D = null
var _sparks: CPUParticles2D = null
var _node_plate: Node2D = null
var _plate_sprite: Sprite2D = null
var _trigger: Area2D = null
var _arena: Rect2 = Rect2()
var _rail_top: float = 0.0
var _rail_left: float = 0.0
var _rail_right: float = 0.0
var _wrist_drop: float = IDLE_WRIST_DROP
var _settle: int = 0
var _wired: bool = false
var _purge_accumulator: float = 0.0
var _clock: float = 0.0
var _node_released: bool = false


func _ready() -> void:
	add_to_group(&"serralheiro")
	_arena = _tile_rect(_params.get("arena", []), Rect2(global_position, Vector2.ONE))
	var rail: Array = _params.get("rail", [])
	_rail_left = _tile_x(rail, 0, _arena.position.x)
	_rail_right = _tile_x(rail, 1, _arena.end.x - Balance.TILE_SIZE) + Balance.TILE_SIZE
	_rail_top = _arena.position.y
	_build_rail()
	_build_lamps()
	_build_bays()
	_build_arm()
	_build_gates()
	_build_vent()
	_build_trigger()
	_fight.setup({}, global_position.x, {}, _bays.size())
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	_refresh_arm(0.0)


func _physics_process(delta: float) -> void:
	if not _wired:
		_settle += 1
		if _settle >= SETTLE_FRAMES:
			_wire()
		return
	_enforce_node_lock()
	var player: Node2D = _player()
	var player_x: float = player.global_position.x if player != null else _fight.arm_x
	var holding: Dictionary = {}
	for id: StringName in _coupler_ids:
		var coupler: Coupler = _couplers.get(id, null)
		holding[id] = coupler != null and coupler.is_held()
	var clock_running: bool = not GameState.is_timer_frozen()
	var events: Array[Dictionary] = _fight.tick(
		delta, player_x, holding, _alive_spawns(), clock_running
	)
	for event: Dictionary in events:
		_apply(event)
	_sync_couplers()
	if _fight.phase == LockEncounter.Phase.CONTAINED:
		_purge(delta, player)


func _process(delta: float) -> void:
	_clock += delta
	_refresh_arm(delta)
	_refresh_lamps()
	_refresh_bays(delta)


func configure(params: Dictionary) -> void:
	_params = params.duplicate(true)
	serralheiro_id = StringName(String(params.get("id", serralheiro_id)))
	_node_id = String(params.get("node", _node_id))
	_coupler_ids.clear()
	for value: Variant in params.get("couplers", []) as Array:
		_coupler_ids.append(StringName(String(value)))


func phase_name() -> String:
	return String(LockEncounter.Phase.keys()[_fight.phase])


func is_awake() -> bool:
	return _fight.is_running()


func is_defeated() -> bool:
	return _fight.is_defeated()


func powered_count() -> int:
	return _fight.powered_count()


func time_left() -> float:
	return _fight.time_left


func alive_spawns() -> int:
	return _alive_spawns()


func is_node_unlocked() -> bool:
	return _node != null and _node.enabled


func is_gate_closed() -> bool:
	return _gate != null and _gate.is_closed()


func is_entry_sealed() -> bool:
	return _hatch != null and _hatch.is_closed()


func is_coupler_sealed(coupler_id: String) -> bool:
	return _fight.is_sealed(StringName(coupler_id))


func is_coupler_powered(coupler_id: String) -> bool:
	return _fight.is_powered(StringName(coupler_id))


func is_vented() -> bool:
	return _vent != null and _vent.is_active()


func encounter() -> LockEncounter:
	return _fight


func _wire() -> void:
	_wired = true
	var positions: Dictionary = {}
	for id: StringName in _coupler_ids:
		var coupler: Coupler = _find_entity(String(id)) as Coupler
		if coupler == null:
			push_warning("Serralheiro: acoplador '%s' ausente" % id)
			continue
		_couplers[id] = coupler
		positions[id] = coupler.global_position.x
	_node = _find_entity(_node_id) as Interactable
	var anchors: Dictionary = {}
	if _gate != null:
		anchors[LockEncounter.STAGE_GATE] = _gate.world_rect().get_center().x
	if _vent_hatch != null:
		anchors[LockEncounter.STAGE_VENT] = _vent_home.x
	_fight.setup(positions, global_position.x, anchors, _bays.size())
	_build_node_plate()
	if _was_defeated():
		_fight.defeat_instantly()
		_show_defeated(false)
		return
	_apply_reset()


func _was_defeated() -> bool:
	if bool(GameState.flags.get(DEFEATED_FLAG, false)):
		return true
	return GameState.sectors_restored.has(SECTOR_ID)


func _apply(event: Dictionary) -> void:
	var type: StringName = StringName(event.get("type", &""))
	var id: StringName = StringName(String(event.get("id", "")))
	match type:
		LockEncounter.EVENT_SEAL_ENTRY:
			_on_wake()
		LockEncounter.EVENT_ARMED:
			for coupler: Coupler in _couplers.values():
				coupler.set_armed(true)
		LockEncounter.EVENT_WINDUP:
			AudioManager.play_sfx(&"claw_grab")
		LockEncounter.EVENT_SEAL:
			AudioManager.play_sfx(&"door_close")
			_shake(Balance.SHAKE_LAND)
		LockEncounter.EVENT_UNSEAL:
			AudioManager.play_sfx(&"door_open")
		LockEncounter.EVENT_CHARGE_LOST:
			AudioManager.play_sfx(&"power_off")
		LockEncounter.EVENT_POWERED:
			_on_powered(id)
		LockEncounter.EVENT_STAGGER:
			AudioManager.play_sfx(&"terminal_breaker")
			_burst_sparks()
		LockEncounter.EVENT_STAGE:
			_on_stage(int(event.get("stage", 0)))
		LockEncounter.EVENT_SPAWN:
			_spawn(int(event.get("bay", 0)))
		LockEncounter.EVENT_DEFEATED:
			_on_defeated()
		LockEncounter.EVENT_CONTAINED:
			_on_contained()
		LockEncounter.EVENT_RESET:
			_apply_reset()


func _on_wake() -> void:
	if _hatch != null:
		_hatch.close()
	for coupler: Coupler in _couplers.values():
		coupler.set_armed(true)
	AudioManager.play_sfx(&"power_on")
	_shake(Balance.SHAKE_SECTOR)
	_burst_sparks()


func _on_powered(id: StringName) -> void:
	var coupler: Coupler = _couplers.get(id, null)
	if coupler == null:
		return
	coupler.set_powered(true)
	Fx.burst(self, Fx.POWER_PULSE, coupler.global_position + Vector2(0, -16), Fx.PULSE_TINT)
	_shake(Balance.SHAKE_SECTOR)
	if _node_plate != null:
		_node_plate.queue_redraw()


func _on_stage(stage: int) -> void:
	_burst_sparks()
	_shake(Balance.SHAKE_SECTOR)
	if stage == LockEncounter.STAGE_GATE and _gate != null:
		_gate.close()
	elif stage == LockEncounter.STAGE_VENT:
		_open_vent()


func _on_contained() -> void:
	AudioManager.play_sfx(&"power_off")
	_shake(Balance.SHAKE_SECTOR)
	if _gate != null:
		_gate.close()
	_open_vent()


func _on_defeated() -> void:
	GameState.flags[DEFEATED_FLAG] = true
	AudioManager.play_sfx(&"power_off")
	_burst_sparks()
	_shake(Balance.SHAKE_SECTOR)
	_show_defeated(true)
	SaveManager.save_game()
	var timer: SceneTreeTimer = get_tree().create_timer(VICTORY_DELAY)
	timer.timeout.connect(_play_victory)


func _play_victory() -> void:
	if not is_inside_tree():
		return
	DialogueManager.play(VICTORY_DIALOGUE)


func _show_defeated(animated: bool) -> void:
	for spawn: Node in _spawns():
		if spawn.has_method(&"shutdown"):
			spawn.call(&"shutdown", OFF_FOREVER)
	if _gate != null:
		if animated:
			_gate.open()
		else:
			_gate.set_closed_silent(false)
	if _hatch != null:
		if animated:
			_hatch.open()
		else:
			_hatch.set_closed_silent(false)
	_close_vent()
	for coupler: Coupler in _couplers.values():
		coupler.set_armed(false)
		if not coupler.is_powered():
			coupler.set_powered_silent(true)
	_release_node(animated)
	_eye.enabled = false
	_trolley.frame = 1
	if not animated:
		_wrist_drop = OFF_WRIST_DROP


func _apply_reset() -> void:
	for spawn: Node in _spawns():
		spawn.queue_free()
	if _gate != null:
		_gate.set_closed_silent(false)
	if _hatch != null:
		_hatch.set_closed_silent(false)
	_close_vent()
	if _vent_hatch != null:
		_vent_hatch.position = to_local(_vent_home)
		_vent_hatch.rotation = 0.0
		_vent_hatch.modulate = Color.WHITE
	for coupler: Coupler in _couplers.values():
		coupler.set_armed(false)
		coupler.set_powered_silent(false)
		coupler.set_charge(0.0)
	for index: int in range(_bay_open.size()):
		_bay_open[index] = 0.0
	_purge_accumulator = 0.0
	_wrist_drop = IDLE_WRIST_DROP
	_lock_node()
	var player: Node2D = _player()
	if player != null and _wired:
		_frame_arena(player, false)


func _on_player_died() -> void:
	_fight.freeze()


func _on_player_respawned() -> void:
	if not _wired:
		return
	for event: Dictionary in _fight.reset():
		_apply(event)


func _on_trigger_body_entered(body: Node2D) -> void:
	if not _wired or not body.is_in_group(PLAYER_GROUP):
		return
	_frame_arena(body, true)
	if _fight.phase != LockEncounter.Phase.DORMANT:
		return
	for event: Dictionary in _fight.start():
		_apply(event)


func _on_trigger_body_exited(body: Node2D) -> void:
	if not body.is_in_group(PLAYER_GROUP) or _fight.is_running():
		return
	_frame_arena(body, false)


func _frame_arena(body: Node2D, inside: bool) -> void:
	if body == null or not body.has_method(&"set_camera_limits"):
		return
	var level: Node = get_tree().get_first_node_in_group(LEVEL_GROUP)
	if level == null or not level.has_method(&"camera_rect"):
		return
	var rect: Rect2i = level.call(&"camera_rect")
	if inside:
		var left: int = maxi(rect.position.x, int(_arena.position.x - CAMERA_WALL))
		var bottom: int = int(_arena.end.y + CAMERA_FLOOR_MARGIN)
		rect = Rect2i(left, rect.position.y, rect.end.x - left, bottom - rect.position.y)
	body.call(&"set_camera_limits", rect)


func _sync_couplers() -> void:
	for id: StringName in _coupler_ids:
		var coupler: Coupler = _couplers.get(id, null)
		if coupler == null or _fight.is_powered(id):
			continue
		if _fight.is_sealed(id):
			if coupler.state != Coupler.State.SEALED:
				coupler.set_state(Coupler.State.SEALED)
			continue
		if coupler.state != Coupler.State.OFF:
			coupler.set_state(Coupler.State.OFF)
		coupler.set_charge(_fight.progress(id))


func _purge(delta: float, player: Node2D) -> void:
	if player == null or GameState.is_dead():
		return
	if not _arena.has_point(player.global_position + Vector2(0.0, -1.0)):
		return
	_purge_accumulator = GameState.apply_damage_over_time(
		Balance.LOCK_PURGE_DPS, delta, _purge_accumulator
	)


func _spawn(bay: int) -> void:
	if bay < 0 or bay >= _bay_points.size() or not ResourceLoader.exists(SR3_SCENE):
		return
	var instance: Node = (load(SR3_SCENE) as PackedScene).instantiate()
	var body := instance as Node2D
	if body == null:
		instance.free()
		return
	var point: Vector2 = _bay_points[bay] + Vector2(0.0, SPAWN_DROP)
	var player: Node2D = _player()
	var direction: int = 1
	if player != null and player.global_position.x < point.x:
		direction = -1
	body.add_to_group(SPAWN_GROUP)
	add_child(body)
	body.global_position = point
	if body.has_method(&"configure"):
		body.call(&"configure", {"dir": direction})
	_bay_open[bay] = BAY_OPEN_TIME
	AudioManager.play_sfx(&"door_open")


func _spawns() -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in get_children():
		if child.is_in_group(SPAWN_GROUP) and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _alive_spawns() -> int:
	return _spawns().size()


func _open_vent() -> void:
	if _vent == null or _vent.is_active():
		return
	_vent.visible = true
	_vent.set_powered_silent(false)
	_vent.set_powered(true)
	if _vent_hatch == null:
		return
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(_vent_hatch, "position", _vent_hatch.position + HATCH_FLY, HATCH_FLY_TIME)
	tween.tween_property(_vent_hatch, "rotation", 0.8, HATCH_FLY_TIME)
	tween.tween_property(_vent_hatch, "modulate:a", 0.0, HATCH_FLY_TIME)


func _close_vent() -> void:
	if _vent == null:
		return
	_vent.set_powered_silent(false)
	_vent.visible = false


func _lock_node() -> void:
	_node_released = false
	if _node_plate != null:
		_node_plate.visible = true
		_node_plate.position = to_local(_node.global_position) if _node != null else Vector2.ZERO
		_node_plate.modulate = Color.WHITE
		_node_plate.queue_redraw()
	_enforce_node_lock()


func _enforce_node_lock() -> void:
	if _node_released or _node == null:
		return
	if _node.enabled:
		_node.set_enabled(false)


func _release_node(animated: bool) -> void:
	_node_released = true
	if _node != null:
		_node.set_enabled(true)
	if _node_plate == null:
		return
	if not animated:
		_node_plate.visible = false
		return
	_node_plate.queue_redraw()
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(
		_node_plate, "position", _node_plate.position + Vector2(0.0, PLATE_FALL), PLATE_FALL_TIME
	)
	tween.tween_property(_node_plate, "modulate:a", 0.0, PLATE_FALL_TIME)
	tween.chain().tween_callback(_node_plate.hide)


func _player() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(PLAYER_GROUP) as Node2D


func _shake(amplitude: float) -> void:
	var player: Node2D = _player()
	if player != null and player.has_method(&"shake"):
		player.call(&"shake", amplitude)


func _burst_sparks() -> void:
	if _sparks != null:
		_sparks.restart()
		_sparks.emitting = true


func _find_entity(entity_id: String) -> Node:
	if entity_id.is_empty():
		return null
	var level: Node = get_parent()
	for node: Node in get_tree().get_nodes_in_group(StringName(ENTITY_PREFIX + entity_id)):
		if level == null or level.is_ancestor_of(node):
			return node
	return null


func _refresh_arm(delta: float) -> void:
	if _trolley == null:
		return
	var shake := Vector2.ZERO
	var phase: LockEncounter.Phase = _fight.phase
	if phase == LockEncounter.Phase.STAGGER or phase == LockEncounter.Phase.WAKING:
		shake = Vector2(randf_range(-SHAKE_PIXELS, SHAKE_PIXELS), 0.0).round()
	var trolley_center := Vector2(_fight.arm_x, _rail_top + TROLLEY_DROP)
	_trolley.position = (to_local(trolley_center) + shake).round()
	var shoulder: Vector2 = trolley_center + shake + Vector2(0.0, SHOULDER_DROP)
	var goal: float = _wrist_goal(shoulder)
	var speed: float = OFF_WRIST_SPEED if _fight.arm_state == LockEncounter.Arm.OFF else WRIST_SPEED
	_wrist_drop = move_toward(_wrist_drop, goal, speed * delta) if delta > 0.0 else goal
	var wrist: Vector2 = shoulder + Vector2(0.0, _wrist_drop)
	_pose(shoulder, wrist)
	_claw.frame = int(_claw_frame())
	var awake: bool = _fight.phase != LockEncounter.Phase.DORMANT and not _fight.is_defeated()
	_trolley.frame = 0 if awake else 1
	_eye.enabled = awake
	var pulse: float = 1.0
	if _fight.arm_state == LockEncounter.Arm.WINDUP:
		pulse = 0.6 + 0.4 * absf(sin(_clock * EYE_PULSE_HZ * PI))
	_eye.energy = EYE_ENERGY * pulse
	var welding: bool = _is_welding()
	_weld.enabled = welding
	_weld.energy = WELD_ENERGY * randf_range(0.6, 1.0) if welding else 0.0
	_weld.position = _claw.position + Vector2(0.0, CLAW_FRAME.y * 0.8)
	_sparks.position = _weld.position
	if welding and not _sparks.emitting:
		_sparks.emitting = true


func _wrist_goal(shoulder: Vector2) -> float:
	match _fight.arm_state:
		LockEncounter.Arm.OFF:
			return OFF_WRIST_DROP
		LockEncounter.Arm.WINDUP, LockEncounter.Arm.HOLD:
			var coupler: Coupler = _couplers.get(_fight.arm_target, null)
			if coupler != null:
				return coupler.global_position.y - CLAW_PLATE_DROP - shoulder.y
		LockEncounter.Arm.WELD:
			if _fight.stage == LockEncounter.STAGE_VENT:
				return VENT_WRIST_DROP
			if _gate != null:
				var top: float = _gate.world_rect().position.y - Balance.TILE_SIZE
				return top - CLAW_PLATE_DROP - shoulder.y
	return IDLE_WRIST_DROP


func _claw_frame() -> ClawFrame:
	if _fight.is_defeated() or _fight.phase == LockEncounter.Phase.DORMANT:
		return ClawFrame.OFF
	match _fight.arm_state:
		LockEncounter.Arm.WINDUP, LockEncounter.Arm.RUSH:
			return ClawFrame.PLATE
		LockEncounter.Arm.HOLD, LockEncounter.Arm.WELD:
			return ClawFrame.WELD
	return ClawFrame.OPEN


func _is_welding() -> bool:
	if _fight.is_defeated() or _fight.phase == LockEncounter.Phase.FROZEN:
		return false
	var state: LockEncounter.Arm = _fight.arm_state
	return state == LockEncounter.Arm.HOLD or state == LockEncounter.Arm.WELD


func _pose(shoulder: Vector2, wrist: Vector2) -> void:
	var reach: float = SEGMENT_LENGTH * 2.0 - REACH_SLACK
	var offset: Vector2 = wrist - shoulder
	var distance: float = maxf(offset.length(), 0.001)
	var direction: Vector2 = offset / distance
	var hand: Vector2 = wrist
	if distance > reach:
		hand = shoulder + direction * reach
		distance = reach
	var half: float = distance * 0.5
	var bend: float = sqrt(maxf(0.0, SEGMENT_LENGTH * SEGMENT_LENGTH - half * half))
	var side: float = 1.0 if _fight.arm_x > _arena.get_center().x else -1.0
	var perpendicular := Vector2(direction.y, -direction.x) * side
	var elbow: Vector2 = shoulder + direction * half + perpendicular * bend
	_place_segment(_upper, shoulder, elbow)
	_place_segment(_lower, elbow, hand)
	var rod_visible: bool = hand.distance_to(wrist) > 0.5
	_rod.visible = rod_visible
	_rod_edge.visible = rod_visible
	if rod_visible:
		var points := PackedVector2Array([to_local(hand), to_local(wrist)])
		_rod.points = points
		_rod_edge.points = points
	_claw.position = to_local(wrist).round()


func _place_segment(segment: Sprite2D, from: Vector2, to: Vector2) -> void:
	segment.position = to_local((from + to) * 0.5)
	segment.rotation = (to - from).angle()


func _refresh_lamps() -> void:
	var states: PackedInt32Array = _fight.lamp_states(_lamps.size())
	var reds: int = states.count(LockEncounter.LAMP_RED)
	var blinking: bool = reds >= _lamps.size() - LAMP_BLINK_LEFT
	var blink_on: bool = fmod(_clock * LAMP_BLINK_HZ, 1.0) < 0.5
	for index: int in range(_lamps.size()):
		var lamp: Sprite2D = _lamps[index]
		match states[index]:
			LockEncounter.LAMP_OFF:
				lamp.frame = 0
				lamp.modulate = Color.WHITE
			LockEncounter.LAMP_AMBER:
				lamp.frame = 1
				lamp.modulate = LAMP_AMBER
			LockEncounter.LAMP_RED:
				lamp.frame = 1 if (not blinking or blink_on) else 0
				lamp.modulate = Color.WHITE


func _refresh_bays(delta: float) -> void:
	for index: int in range(_bays.size()):
		if _bay_open[index] > 0.0:
			_bay_open[index] = maxf(0.0, _bay_open[index] - delta)
		_bays[index].frame = 1 if _bay_open[index] > 0.0 else 0


func _build_rail() -> void:
	_rail = Node2D.new()
	_rail.name = "Rail"
	_rail.z_index = Z_RAIL
	_rail.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var texture: Texture2D = AssetResolver.texture(RAIL_TEXTURE)
	var top_left: Vector2 = to_local(Vector2(_rail_left, _rail_top))
	var width: float = _rail_right - _rail_left
	_rail.draw.connect(func() -> void:
		if texture != null:
			_rail.draw_texture_rect(
				texture, Rect2(top_left, Vector2(width, float(texture.get_height()))), true
			)
	)
	add_child(_rail)


func _build_lamps() -> void:
	var texture: Texture2D = AssetResolver.texture(LAMP_SHEET)
	var count: int = maxi(1, Balance.LOCK_LAMPS)
	var span: float = _rail_right - _rail_left
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for index: int in range(count):
		var lamp := Sprite2D.new()
		lamp.name = "Lamp%02d" % index
		lamp.texture = texture
		lamp.hframes = 2
		lamp.z_index = Z_LAMP
		lamp.material = material
		var x: float = _rail_left + span * (float(index) + 0.5) / float(count)
		lamp.position = to_local(Vector2(x, _rail_top + 8.0)).round()
		add_child(lamp)
		_lamps.append(lamp)


func _build_bays() -> void:
	var texture: Texture2D = AssetResolver.texture(BAY_SHEET)
	for value: Variant in _params.get("bays", []) as Array:
		var cell: Array = value if value is Array else []
		if cell.size() < 2:
			continue
		var top := Vector2(
			(float(cell[0]) + 0.5) * Balance.TILE_SIZE, float(cell[1]) * Balance.TILE_SIZE
		)
		var bay := Sprite2D.new()
		bay.name = "Bay%d" % _bays.size()
		bay.texture = texture
		bay.hframes = 2
		bay.z_index = Z_BAY
		bay.offset = Vector2(0.0, BAY_FRAME.y * 0.5)
		bay.position = to_local(top).round()
		add_child(bay)
		_bays.append(bay)
		_bay_points.append(top)
		_bay_open.append(0.0)


func _build_arm() -> void:
	_upper = _segment("Upper", UPPER_TEXTURE, Z_UPPER)
	_lower = _segment("Lower", LOWER_TEXTURE, Z_LOWER)
	_rod_edge = _line("RodEdge", ROD_EDGE_WIDTH, ROD_EDGE)
	_rod = _line("Rod", ROD_WIDTH, ROD_COLOR)
	_claw = Sprite2D.new()
	_claw.name = "Claw"
	_claw.texture = AssetResolver.texture(CLAW_SHEET)
	_claw.hframes = 4
	_claw.z_index = Z_CLAW
	_claw.offset = Vector2(0.0, CLAW_FRAME.y * 0.5)
	add_child(_claw)
	_trolley = Sprite2D.new()
	_trolley.name = "Trolley"
	_trolley.texture = AssetResolver.texture(TROLLEY_SHEET)
	_trolley.hframes = 2
	_trolley.frame = 1
	_trolley.z_index = Z_TROLLEY
	add_child(_trolley)
	_eye = _light("Eye", EYE_COLOR, EYE_RADIUS)
	_trolley.add_child(_eye)
	_weld = _light("Weld", WELD_COLOR, WELD_RADIUS)
	add_child(_weld)
	_sparks = CPUParticles2D.new()
	_sparks.name = "Sparks"
	_sparks.z_index = Z_SPARKS
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.amount = 24
	_sparks.lifetime = 0.6
	_sparks.explosiveness = 0.7
	_sparks.direction = Vector2.UP
	_sparks.spread = 70.0
	_sparks.gravity = Vector2(0.0, 420.0)
	_sparks.initial_velocity_min = 50.0
	_sparks.initial_velocity_max = 120.0
	_sparks.scale_amount_min = 1.0
	_sparks.scale_amount_max = 2.0
	_sparks.color = SPARK_COLOR
	var spark_material := CanvasItemMaterial.new()
	spark_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	spark_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_sparks.material = spark_material
	add_child(_sparks)


func _segment(node_name: String, path: String, layer: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = AssetResolver.texture(path)
	sprite.z_index = layer
	add_child(sprite)
	return sprite


func _line(node_name: String, width: float, color: Color) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.width = width
	line.default_color = color
	line.z_index = Z_LOWER
	line.visible = false
	add_child(line)
	return line


func _light(node_name: String, color: Color, radius: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.name = node_name
	light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	light.color = color
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.shadow_enabled = false
	light.texture_scale = LightMath.scale_for_radius(radius, LightMath.TEXTURE_SIZE)
	light.enabled = false
	return light


func _build_gates() -> void:
	_gate = _make_gate(GATE_ID, _params.get("gate", []))
	_hatch = _make_gate(HATCH_ID, _params.get("hatch", []))


func _make_gate(gate_id: StringName, raw: Variant) -> LockGate:
	var cells: Array = raw if raw is Array else []
	if cells.size() < 4 or not ResourceLoader.exists(GATE_SCENE):
		return null
	var gate := (load(GATE_SCENE) as PackedScene).instantiate() as LockGate
	if gate == null:
		return null
	gate.name = String(gate_id)
	gate.configure({"id": String(gate_id), "size": [int(cells[2]), int(cells[3])]})
	gate.add_to_group(StringName(ENTITY_PREFIX + String(gate_id)))
	add_child(gate)
	gate.global_position = Vector2(float(cells[0]), float(cells[1])) * Balance.TILE_SIZE
	return gate


func _build_vent() -> void:
	var cell: Array = _params.get("vent", [])
	if _arena.size.x >= Balance.TILE_SIZE and ResourceLoader.exists(VACUUM_SCENE):
		var zone := (load(VACUUM_SCENE) as PackedScene).instantiate() as VacuumZone
		if zone != null:
			zone.name = String(VENT_ID)
			var tiles := Vector2i(
				int(_arena.size.x / Balance.TILE_SIZE), int(_arena.size.y / Balance.TILE_SIZE)
			)
			zone.configure({"rect": [tiles.x, tiles.y], "powered": false})
			add_child(zone)
			zone.global_position = _arena.position + Vector2.ONE * Balance.TILE_SIZE * 0.5
			zone.visible = false
			_vent = zone
	if cell.size() < 2:
		return
	_vent_home = Vector2(
		(float(cell[0]) + 0.5) * Balance.TILE_SIZE, (float(cell[1]) + 0.5) * Balance.TILE_SIZE
	)
	_vent_hatch = Sprite2D.new()
	_vent_hatch.name = "VentHatch"
	_vent_hatch.texture = AssetResolver.texture(HATCH_TEXTURE)
	_vent_hatch.z_index = Z_BAY
	_vent_hatch.position = to_local(_vent_home)
	add_child(_vent_hatch)


func _build_trigger() -> void:
	var rect: Rect2 = _tile_rect(_params.get("trigger", []), _arena)
	_trigger = Area2D.new()
	_trigger.name = "Trigger"
	_trigger.collision_layer = 0
	_trigger.collision_mask = PLAYER_MASK
	_trigger.monitorable = false
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	_trigger.add_child(shape)
	add_child(_trigger)
	_trigger.global_position = rect.get_center()
	_trigger.body_entered.connect(_on_trigger_body_entered)
	_trigger.body_exited.connect(_on_trigger_body_exited)


func _build_node_plate() -> void:
	if _node == null:
		return
	_node_plate = Node2D.new()
	_node_plate.name = "NodePlate"
	_node_plate.z_index = Z_PLATE
	_plate_sprite = Sprite2D.new()
	_plate_sprite.texture = AssetResolver.texture(PLATE_TEXTURE)
	_plate_sprite.offset = Vector2(0.0, -16.0)
	_node_plate.add_child(_plate_sprite)
	var lamps := Node2D.new()
	lamps.name = "Lamps"
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	lamps.material = material
	lamps.draw.connect(_draw_node_lamps.bind(lamps))
	_node_plate.add_child(lamps)
	_node_plate.draw.connect(lamps.queue_redraw)
	add_child(_node_plate)
	_node_plate.position = to_local(_node.global_position)


func _draw_node_lamps(canvas: Node2D) -> void:
	var count: int = maxi(1, _coupler_ids.size())
	var lit: int = _fight.powered_count()
	var width: float = count * NODE_LAMP_SIZE + (count - 1) * NODE_LAMP_GAP
	for index: int in range(count):
		var x: float = -width * 0.5 + index * (NODE_LAMP_SIZE + NODE_LAMP_GAP)
		var box := Rect2(x, -NODE_LAMP_HEIGHT, NODE_LAMP_SIZE, NODE_LAMP_SIZE)
		canvas.draw_rect(box.grow(1.0), NODE_LAMP_EDGE)
		canvas.draw_rect(box, NODE_LAMP_ON if index < lit else NODE_LAMP_OFF)


func _tile_rect(raw: Variant, fallback: Rect2) -> Rect2:
	var cells: Array = raw if raw is Array else []
	if cells.size() < 4:
		return fallback
	var tile: float = float(Balance.TILE_SIZE)
	return Rect2(
		Vector2(float(cells[0]), float(cells[1])) * tile,
		Vector2(float(cells[2]), float(cells[3])) * tile
	)


func _tile_x(raw: Array, index: int, fallback: float) -> float:
	if raw.size() <= index:
		return fallback
	return float(raw[index]) * Balance.TILE_SIZE
