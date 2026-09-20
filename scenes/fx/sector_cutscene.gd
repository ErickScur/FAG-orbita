class_name SectorCutscene
extends Node2D

enum Phase { IDLE, HOLD_START, TRAVEL, HOLD_END, RETURN, RELEASE }

const GROUP: StringName = &"sector_cutscene"
const HUD_GROUP: StringName = &"hud"
const PLAYER_GROUP: StringName = &"player"
const POWERED_GROUP: StringName = &"powered"

var _phase: Phase = Phase.IDLE
var _sector_id: StringName = &""
var _bounds: Rect2i = Rect2i()
var _finish: Vector2 = Vector2.ZERO
var _ambient: CanvasModulate = null
var _restored_color: Color = Balance.LAMP_COLOR
var _path: Array[Vector2] = []
var _path_length: float = 0.0
var _travel_time: float = Balance.CUTSCENE_TRAVEL_MAX_TIME
var _elapsed: float = 0.0
var _return_from: Vector2 = Vector2.ZERO
var _pending: Array[Node] = []
var _player: Node2D = null
var _player_camera: Camera2D = null
var _hidden_huds: Array[Node] = []
var _ambient_tween: Tween = null

@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group(GROUP)
	set_process(false)
	set_process_unhandled_input(false)
	_camera.enabled = false
	EventBus.sector_restored.connect(_on_sector_restored)


func _process(delta: float) -> void:
	_elapsed += delta
	match _phase:
		Phase.HOLD_START:
			if _elapsed >= Balance.CUTSCENE_HOLD_START_TIME:
				_enter_phase(Phase.TRAVEL)
		Phase.TRAVEL:
			var ratio: float = _ratio(_elapsed, _travel_time)
			_move_to(CutsceneRoute.point_at_ratio(_path, CutsceneRoute.ease_in_out(ratio)))
			if ratio >= 1.0:
				_enter_phase(Phase.HOLD_END)
		Phase.HOLD_END:
			if _elapsed >= Balance.CUTSCENE_HOLD_END_TIME:
				_enter_phase(Phase.RETURN)
		Phase.RETURN:
			var back: float = _ratio(_elapsed, Balance.CUTSCENE_RETURN_TIME)
			_move_to(_return_from.lerp(_player_anchor(), CutsceneRoute.ease_in_out(back)))
			if back >= 1.0:
				_finish_cutscene()
		Phase.RELEASE:
			if CutsceneRoute.can_release_control(
				_elapsed, Balance.CUTSCENE_SKIP_ARM_TIME, _any_action_pressed()
			):
				_release_control()
		_:
			return
	_reveal_nearby()


func _unhandled_input(event: InputEvent) -> void:
	if not _skippable() or _elapsed < Balance.CUTSCENE_SKIP_ARM_TIME:
		return
	if not _is_skip(event):
		return
	get_viewport().set_input_as_handled()
	_finish_cutscene()


func configure(
	bounds: Rect2i, finish: Vector2, ambient: CanvasModulate, restored_color: Color
) -> void:
	_bounds = bounds
	_finish = finish
	_ambient = ambient
	_restored_color = restored_color


func is_running() -> bool:
	return _phase != Phase.IDLE


func route() -> Array[Vector2]:
	return _path


func _on_sector_restored(sector_id: StringName) -> void:
	if _phase != Phase.IDLE:
		return
	_sector_id = sector_id
	_player = _find_player()
	if _player == null:
		EventBus.sector_cutscene_finished.emit(_sector_id)
		return
	_collect_targets()
	_build_path()
	_take_over()
	_lift_ambient()
	EventBus.sector_cutscene_started.emit(_sector_id)
	_enter_phase(Phase.HOLD_START)
	set_process(true)
	set_process_unhandled_input(true)


func _enter_phase(phase: Phase) -> void:
	_phase = phase
	_elapsed = 0.0
	if phase == Phase.TRAVEL:
		_move_to(_path[0])
	elif phase == Phase.RETURN:
		_return_from = _camera.global_position


func _take_over() -> void:
	_player_camera = get_viewport().get_camera_2d()
	_camera.limit_left = _bounds.position.x
	_camera.limit_top = _bounds.position.y
	_camera.limit_right = _bounds.position.x + _bounds.size.x
	_camera.limit_bottom = _bounds.position.y + _bounds.size.y
	_camera.global_position = _player_anchor()
	_camera.enabled = true
	_camera.make_current()
	_camera.reset_smoothing()
	_hide_hud(true)
	_lock_player(true)


func _finish_cutscene() -> void:
	if not _skippable():
		return
	_apply_all_effects()
	_phase = Phase.RELEASE
	_elapsed = 0.0
	set_process_unhandled_input(false)
	_camera.enabled = false
	if _player_camera != null and is_instance_valid(_player_camera):
		_player_camera.make_current()
		_player_camera.reset_smoothing()
	_player_camera = null
	_hide_hud(false)
	_pending.clear()


func _release_control() -> void:
	_phase = Phase.IDLE
	set_process(false)
	_lock_player(false)
	EventBus.sector_cutscene_finished.emit(_sector_id)


func _skippable() -> bool:
	return _phase != Phase.IDLE and _phase != Phase.RELEASE


func _ratio(elapsed: float, duration: float) -> float:
	if duration <= 0.0:
		return 1.0
	return elapsed / duration


func _any_action_pressed() -> bool:
	for action: StringName in InputMap.get_actions():
		if Input.is_action_pressed(action):
			return true
	return false


func _move_to(point: Vector2) -> void:
	_camera.global_position = CutsceneRoute.snap(point)


func _player_anchor() -> Vector2:
	if _player == null or not is_instance_valid(_player):
		return _camera.global_position
	return _player.global_position + Vector2(0.0, Balance.CAMERA_OFFSET_Y)


func _build_path() -> void:
	var points: Array[Vector2] = []
	for node: Node in _pending:
		var item := node as Node2D
		if item != null:
			points.append(item.global_position)
	_path = CutsceneRoute.build(
		_player_anchor(),
		_finish,
		points,
		Balance.CUTSCENE_WAYPOINT_SPACING,
		Balance.CUTSCENE_WAYPOINT_LIMIT
	)
	_path_length = CutsceneRoute.length(_path)
	_travel_time = CutsceneRoute.duration_for(
		_path_length,
		Balance.CUTSCENE_CAMERA_SPEED,
		Balance.CUTSCENE_TRAVEL_MIN_TIME,
		Balance.CUTSCENE_TRAVEL_MAX_TIME
	)


func _collect_targets() -> void:
	_pending.clear()
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group(POWERED_GROUP):
		if _needs_effect(node):
			_pending.append(node)


func _needs_effect(node: Node) -> bool:
	if not node.has_method(&"set_powered"):
		return false
	var wanted: bool = not (node is SporeSwarm)
	return bool(node.get(&"powered")) != wanted


func _apply_effect(node: Node) -> void:
	if not is_instance_valid(node):
		return
	node.call(&"set_powered", not (node is SporeSwarm))


func _reveal_nearby() -> void:
	var camera: Vector2 = _camera.global_position
	var remaining: Array[Node] = []
	for node: Node in _pending:
		var item := node as Node2D
		if item == null or not is_instance_valid(item):
			continue
		if CutsceneRoute.is_on_screen(camera, item.global_position, Balance.CUTSCENE_REVEAL_HALF_SIZE):
			_apply_effect(item)
			continue
		remaining.append(item)
	_pending = remaining


func _apply_all_effects() -> void:
	for node: Node in _pending:
		_apply_effect(node)
	_pending.clear()
	if _ambient != null and _restored_color != _ambient.color:
		_kill_ambient_tween()
		_ambient.color = _restored_color


func _lift_ambient() -> void:
	if _ambient == null or _restored_color == _ambient.color:
		return
	_kill_ambient_tween()
	_ambient_tween = create_tween()
	_ambient_tween.set_trans(Tween.TRANS_SINE)
	_ambient_tween.set_ease(Tween.EASE_OUT)
	_ambient_tween.tween_property(
		_ambient, ^"color", Balance.SECTOR_FLASH_COLOR, Balance.SECTOR_FLASH_TIME
	)
	_ambient_tween.tween_property(_ambient, ^"color", _restored_color, Balance.SECTOR_SETTLE_TIME)


func _kill_ambient_tween() -> void:
	if _ambient_tween != null and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = null


func _hide_hud(hidden: bool) -> void:
	if not hidden:
		for layer: Node in _hidden_huds:
			if is_instance_valid(layer):
				layer.set(&"visible", true)
		_hidden_huds.clear()
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	for node: Node in tree.get_nodes_in_group(HUD_GROUP):
		if not bool(node.get(&"visible")):
			continue
		node.set(&"visible", false)
		_hidden_huds.append(node)


func _lock_player(locked: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_method(&"set_input_locked"):
		_player.call(&"set_input_locked", locked)
	if _player.has_method(&"set_invincible"):
		_player.call(&"set_invincible", locked)


func _find_player() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(PLAYER_GROUP):
		var body := node as Node2D
		if body != null:
			return body
	return null


func _is_skip(event: InputEvent) -> bool:
	if event is InputEventKey:
		var key := event as InputEventKey
		return key.pressed and not key.echo
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).pressed
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).pressed
	if event is InputEventAction:
		return (event as InputEventAction).pressed
	return false
