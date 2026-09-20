extends Node2D

const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 768, 216)
const SPAWN: Vector2 = Vector2(112, 160)
const WORLD_LAYER: int = 1
const ONE_WAY_LAYER: int = 64
const BACKGROUND_COLOR: Color = Color("#10161c")
const SOLID_COLOR: Color = Color("#2f4f5a")
const SOLID_TOP_COLOR: Color = Color("#4a7284")
const ONE_WAY_COLOR: Color = Color("#5fd4c8")
const SOLIDS: Array[Rect2] = [
	Rect2(-16, -64, 16, 280),
	Rect2(768, -64, 16, 280),
	Rect2(0, 128, 64, 88),
	Rect2(64, 160, 368, 56),
	Rect2(432, 192, 48, 24),
	Rect2(480, 160, 288, 56),
	Rect2(608, 144, 48, 16),
]
const ONE_WAYS: Array[Rect2] = [
	Rect2(432, 160, 48, 4),
]

var _player: Node2D = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_background()
	for rect: Rect2 in SOLIDS:
		_add_solid(rect)
	for rect: Rect2 in ONE_WAYS:
		_add_one_way(rect)
	_spawn_player()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"map"):
		get_tree().paused = not get_tree().paused


func _build_background() -> void:
	var background := ColorRect.new()
	background.position = Vector2(ROOM.position)
	background.size = Vector2(ROOM.size)
	background.color = BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)


func _add_solid(rect: Rect2) -> void:
	var body: StaticBody2D = _make_body(rect, WORLD_LAYER, false)
	_add_visual(body, rect, SOLID_COLOR)
	var edge := ColorRect.new()
	edge.position = -rect.size * 0.5
	edge.size = Vector2(rect.size.x, 2.0)
	edge.color = SOLID_TOP_COLOR
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(edge)
	add_child(body)


func _add_one_way(rect: Rect2) -> void:
	var body: StaticBody2D = _make_body(rect, ONE_WAY_LAYER, true)
	_add_visual(body, rect, ONE_WAY_COLOR)
	add_child(body)


func _make_body(rect: Rect2, layer: int, one_way: bool) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.one_way_collision = one_way
	body.add_child(shape)
	return body


func _add_visual(body: StaticBody2D, rect: Rect2, color: Color) -> void:
	var visual := ColorRect.new()
	visual.position = -rect.size * 0.5
	visual.size = rect.size
	visual.color = color
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)


func _spawn_player() -> void:
	if not ResourceLoader.exists(PLAYER_SCENE):
		push_warning("mu7_sandbox: cena do jogador ausente")
		return
	var scene: PackedScene = load(PLAYER_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_player = instance
	_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	_player.position = SPAWN
	add_child(_player)
	if _player.has_method("set_camera_limits"):
		_player.call("set_camera_limits", ROOM)
	if _player.has_method("snap_camera"):
		_player.call("snap_camera")
