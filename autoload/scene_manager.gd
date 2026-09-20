extends Node

const OVERLAY_LAYER: int = 100
const PAUSE_MENU_SCENE: String = "res://scenes/ui/pause_menu.tscn"

var pending_path: String = ""

var _transitioning: bool = false
var _overlay: ColorRect = null
var _pause_menu: CanvasLayer = null
var _chassis_lost: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.name = "TransitionLayer"
	layer.layer = OVERLAY_LAYER
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.name = "Fade"
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	_overlay.visible = false
	_spawn_pause_menu()
	EventBus.player_died.connect(_on_player_died)
	EventBus.game_over.connect(_on_game_over)
	EventBus.demo_completed.connect(_on_demo_completed)


func pause_menu() -> CanvasLayer:
	return _pause_menu


func chassis_lost_overlay() -> CanvasLayer:
	return _chassis_lost


func goto(path: String) -> void:
	if not _can_start(path):
		return
	_close_pause()
	if ScenePaths.is_level(path):
		_run_loading_transition(path)
	else:
		_run_direct_transition(path)


func goto_with_loading(path: String) -> void:
	if not _can_start(path):
		return
	_close_pause()
	_run_loading_transition(path)


func goto_instant(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("SceneManager: cena inexistente %s" % path)
		return
	_close_pause()
	pending_path = ""
	_transitioning = false
	if _overlay != null:
		_overlay.modulate.a = 0.0
		_overlay.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func is_transitioning() -> bool:
	return _transitioning


func finish_loading(packed: PackedScene) -> void:
	if packed == null:
		abort_loading("cena empacotada nula")
		return
	await _fade_to(1.0)
	get_tree().paused = false
	get_tree().change_scene_to_packed(packed)
	pending_path = ""
	await _fade_to(0.0)
	_transitioning = false


func abort_loading(reason: String) -> void:
	push_error("SceneManager: falha ao carregar %s (%s)" % [pending_path, reason])
	pending_path = ""
	if ResourceLoader.exists(ScenePaths.MAIN_MENU):
		await _fade_to(1.0)
		get_tree().paused = false
		get_tree().change_scene_to_file(ScenePaths.MAIN_MENU)
	await _fade_to(0.0)
	_transitioning = false


func _spawn_pause_menu() -> void:
	if not ResourceLoader.exists(PAUSE_MENU_SCENE):
		return
	var packed: PackedScene = load(PAUSE_MENU_SCENE)
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	if not (instance is CanvasLayer):
		instance.free()
		return
	_pause_menu = instance
	add_child(_pause_menu)


func _on_player_died() -> void:
	if GameState.reactor_percent <= 0.0:
		return
	_show_chassis_lost()


func _on_game_over(_reason: StringName) -> void:
	_dismiss_chassis_lost()
	goto(ScenePaths.GAME_OVER)


func _on_demo_completed() -> void:
	_dismiss_chassis_lost()
	goto(ScenePaths.DEMO_END)


func _show_chassis_lost() -> void:
	if _chassis_lost != null and is_instance_valid(_chassis_lost):
		return
	if not ResourceLoader.exists(ScenePaths.CHASSIS_LOST):
		push_error("SceneManager: cena inexistente %s" % ScenePaths.CHASSIS_LOST)
		return
	var packed: PackedScene = load(ScenePaths.CHASSIS_LOST)
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	if not (instance is CanvasLayer):
		instance.free()
		return
	_chassis_lost = instance
	add_child(_chassis_lost)
	_chassis_lost.connect(&"finished", _on_chassis_lost_finished)
	_chassis_lost.call(&"play")


func _on_chassis_lost_finished() -> void:
	_chassis_lost = null
	EventBus.player_respawned.emit()


func _dismiss_chassis_lost() -> void:
	if _chassis_lost == null or not is_instance_valid(_chassis_lost):
		_chassis_lost = null
		return
	_chassis_lost.queue_free()
	_chassis_lost = null


func _close_pause() -> void:
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.call(&"close")


func _can_start(path: String) -> bool:
	if _transitioning:
		return false
	if not ResourceLoader.exists(path):
		push_error("SceneManager: cena inexistente %s" % path)
		return false
	return true


func _run_direct_transition(path: String) -> void:
	_transitioning = true
	await _fade_to(1.0)
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await _fade_to(0.0)
	_transitioning = false


func _run_loading_transition(path: String) -> void:
	_transitioning = true
	pending_path = path
	await _fade_to(1.0)
	get_tree().paused = false
	get_tree().change_scene_to_file(ScenePaths.LOADING)
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	_overlay.visible = true
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_overlay, "modulate:a", alpha, Balance.SCENE_FADE_TIME)
	await tween.finished
	_overlay.visible = alpha > 0.0
