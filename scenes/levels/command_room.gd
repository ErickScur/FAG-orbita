class_name CommandRoom
extends Node

const CONFIRM_SCENE: String = "res://scenes/ui/confirm_dialog.tscn"
const HUD_GROUP: StringName = &"hud"
const PLAYER_GROUP: StringName = &"player"
const POWERED_GROUP: StringName = &"powered"
const DIALOG_LAYER: int = 50

var _table: Dictionary = {}
var _busy: bool = false
var _releasing: bool = false
var _release_elapsed: float = 0.0
var _chosen: StringName = &""
var _dialog_layer: CanvasLayer = null


func _ready() -> void:
	_table = EndingData.load_table()
	set_process(false)
	_setup.call_deferred()


func _process(delta: float) -> void:
	if not _releasing:
		set_process(false)
		return
	_release_elapsed += delta
	if not CutsceneRoute.can_release_control(
		_release_elapsed, Balance.CUTSCENE_SKIP_ARM_TIME, _any_action_pressed()
	):
		return
	_releasing = false
	_busy = false
	_lock_player(false)
	set_process(false)


func is_busy() -> bool:
	return _busy


func chosen() -> StringName:
	return _chosen


func _setup() -> void:
	AudioManager.stop_music()
	GameState.set_reactor_online(false)
	GameState.current_objective = ""
	EventBus.objective_changed.emit("")
	for node: Node in get_tree().get_nodes_in_group(EndingConsole.GROUP):
		var console := node as EndingConsole
		if console == null:
			continue
		console.interacted.connect(_on_console_interacted.bind(console))


func _on_console_interacted(_actor: Node, console: EndingConsole) -> void:
	if _busy or console.pulled or _chosen != &"":
		return
	_busy = true
	_lock_player(true)
	var dialog: Control = _open_dialog()
	if dialog == null:
		_execute(console)
		return
	dialog.connect(&"answered", _on_answered.bind(console))
	dialog.call(
		&"open",
		EndingData.text(_table, console.ending_id, "confirm"),
		EndingData.text(_table, console.ending_id, "confirm_yes"),
		EndingData.text(_table, console.ending_id, "confirm_no")
	)


func _on_answered(confirmed: bool, console: EndingConsole) -> void:
	if confirmed:
		_execute(console)
		return
	_releasing = true
	_release_elapsed = 0.0
	set_process(true)


func _execute(console: EndingConsole) -> void:
	_chosen = console.ending_id
	EndingData.record_choice(GameState.flags, _chosen)
	SaveManager.save_game()
	EventBus.ending_chosen.emit(_chosen)
	console.set_pulled(true)
	var machine: EndingMachine = _machine_for(_chosen)
	if machine != null:
		machine.set_active(true)
	AudioManager.play_sfx(&"terminal_breaker")
	AudioManager.play_sfx(&"power_on")
	_hide_hud()
	_shake_player()
	_dim_room(machine)
	get_tree().create_timer(Balance.ENDING_ROOM_BEAT_TIME).timeout.connect(_cut_to_cutscene)


func _cut_to_cutscene() -> void:
	SceneManager.goto_instant(ScenePaths.ENDING_CUTSCENE)


func _open_dialog() -> Control:
	if not ResourceLoader.exists(CONFIRM_SCENE):
		return null
	if _dialog_layer == null or not is_instance_valid(_dialog_layer):
		_dialog_layer = CanvasLayer.new()
		_dialog_layer.name = "ChoiceLayer"
		_dialog_layer.layer = DIALOG_LAYER
		add_child(_dialog_layer)
	var dialog: Control = (load(CONFIRM_SCENE) as PackedScene).instantiate()
	_dialog_layer.add_child(dialog)
	return dialog


func _machine_for(ending_id: StringName) -> EndingMachine:
	for node: Node in get_tree().get_nodes_in_group(EndingMachine.GROUP):
		var machine := node as EndingMachine
		if machine != null and machine.ending_id() == ending_id:
			return machine
	return null


func _dim_room(machine: EndingMachine) -> void:
	var origin: Vector2 = machine.global_position if machine != null else Vector2.ZERO
	var lamps: Array[PoweredLamp] = []
	for node: Node in get_tree().get_nodes_in_group(POWERED_GROUP):
		var lamp := node as PoweredLamp
		if lamp != null and lamp.powered:
			lamps.append(lamp)
	lamps.sort_custom(func(a: PoweredLamp, b: PoweredLamp) -> bool:
		return a.global_position.distance_to(origin) > b.global_position.distance_to(origin)
	)
	var step: float = Balance.ENDING_ROOM_BEAT_TIME / float(lamps.size() + 1)
	for index: int in range(lamps.size()):
		var timer: SceneTreeTimer = get_tree().create_timer(step * float(index + 1))
		timer.timeout.connect(_turn_off.bind(lamps[index]))


func _turn_off(lamp: PoweredLamp) -> void:
	if is_instance_valid(lamp):
		lamp.set_powered(false)


func _hide_hud() -> void:
	for node: Node in get_tree().get_nodes_in_group(HUD_GROUP):
		node.set(&"visible", false)


func _shake_player() -> void:
	var player: Node = get_tree().get_first_node_in_group(PLAYER_GROUP)
	if player != null and player.has_method(&"shake"):
		player.call(&"shake", Balance.SHAKE_SECTOR)


func _lock_player(locked: bool) -> void:
	var player: Node = get_tree().get_first_node_in_group(PLAYER_GROUP)
	if player != null and player.has_method(&"set_input_locked"):
		player.call(&"set_input_locked", locked)


func _any_action_pressed() -> bool:
	for action: StringName in InputMap.get_actions():
		if Input.is_action_pressed(action):
			return true
	return false
