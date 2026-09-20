extends Node2D

const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 384, 216)
const SPAWN: Vector2 = Vector2(64, 176)
const FLOOR_RECT: Rect2 = Rect2(0, 176, 384, 40)
const FLOOR_COLOR: Color = Color("#2f4f5a")
const OPENING: StringName = &"core_wake"
const AMBIENT: StringName = &"core_calib_move"
const LOG_ID: StringName = &"log_core_01"
const QUEUE_FIRST: StringName = &"gh_enter"
const QUEUE_SECOND: StringName = &"gh_terminal_first"

var _player: Node2D = null


func _ready() -> void:
	%Ajuda.text = "SHIFT bark · Q log · F fila"
	_build_floor()
	_spawn_player()
	DialogueManager.play(OPENING)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"dash"):
		DialogueManager.play(AMBIENT)
	elif event.is_action_pressed(&"beam"):
		DialogueManager.open_log(LOG_ID)
	elif event.is_action_pressed(&"flashlight"):
		DialogueManager.play(QUEUE_FIRST)
		DialogueManager.enqueue(QUEUE_SECOND)


func _build_floor() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = FLOOR_RECT.position + FLOOR_RECT.size * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = FLOOR_RECT.size
	shape.shape = rectangle
	body.add_child(shape)
	var visual := ColorRect.new()
	visual.position = -FLOOR_RECT.size * 0.5
	visual.size = FLOOR_RECT.size
	visual.color = FLOOR_COLOR
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)
	add_child(body)


func _spawn_player() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		push_warning("dialogue_test: cena do jogador ausente")
		return
	var instance: Node = load(PLAYER_SCENE).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_player = instance
	_player.position = SPAWN
	add_child(_player)
	if _player.has_method("set_camera_limits"):
		_player.call("set_camera_limits", ROOM)
	if _player.has_method("snap_camera"):
		_player.call("snap_camera")
