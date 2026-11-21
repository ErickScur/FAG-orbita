class_name LockGate
extends StaticBody2D

signal closed()
signal opened()

const GATE_TEXTURE: String = "res://assets/sprites/world/lock_gate.png"
const HATCH_TEXTURE: String = "res://assets/sprites/world/lock_hatch.png"
const WORLD_LAYER: int = 1
const STUB_TILES: int = 1
const PLAYER_GROUP: StringName = &"player"
const PLAYER_HALF_WIDTH: float = 7.0
const PLAYER_HEIGHT: float = 24.0

@export var gate_id: StringName = &""
@export var size_tiles: Vector2i = Vector2i(1, 3)

var _closed: bool = false
var _amount: float = 0.0
var _pending: bool = false
var _tween: Tween = null
var _canvas: Node2D = null
var _texture: Texture2D = null

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	collision_layer = WORLD_LAYER
	collision_mask = 0
	_canvas = Node2D.new()
	_canvas.name = "Plates"
	_canvas.draw.connect(_draw_plates)
	add_child(_canvas)
	_apply_layout()
	set_closed_silent(_closed)


func _physics_process(_delta: float) -> void:
	if not _pending:
		return
	if _player_inside():
		return
	_pending = false
	_animate_close()


func configure(params: Dictionary) -> void:
	gate_id = StringName(String(params.get("gate_id", params.get("id", gate_id))))
	var raw: Variant = params.get("size", null)
	if raw is Array and (raw as Array).size() >= 2:
		size_tiles = Vector2i(maxi(1, int(raw[0])), maxi(1, int(raw[1])))
	if _shape == null:
		return
	_apply_layout()
	set_closed_silent(_closed)


func is_vertical() -> bool:
	return size_tiles.y >= size_tiles.x


func is_closed() -> bool:
	return _closed and not _pending


func is_closing() -> bool:
	return _pending or (_closed and _amount < 1.0)


func world_rect() -> Rect2:
	var size := Vector2(size_tiles) * float(Balance.TILE_SIZE)
	return Rect2(global_position, size)


func close() -> void:
	if _closed:
		return
	_closed = true
	_pending = true


func open() -> void:
	if not _closed:
		return
	_closed = false
	_pending = false
	_shape.set_deferred(&"disabled", true)
	AudioManager.play_sfx(&"door_open")
	_tween_amount(0.0)
	opened.emit()


func set_closed_silent(value: bool) -> void:
	_closed = value
	_pending = false
	_kill_tween()
	_amount = 1.0 if value else 0.0
	if _shape != null:
		_shape.set_deferred(&"disabled", not value)
	if _canvas != null:
		_canvas.queue_redraw()


func _animate_close() -> void:
	_shape.set_deferred(&"disabled", false)
	AudioManager.play_sfx(&"door_close")
	_tween_amount(1.0)
	closed.emit()


func _tween_amount(target: float) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_amount, _amount, target, Balance.LOCK_GATE_TIME)


func _set_amount(value: float) -> void:
	_amount = clampf(value, 0.0, 1.0)
	_canvas.queue_redraw()


func _apply_layout() -> void:
	var size := Vector2(size_tiles) * float(Balance.TILE_SIZE)
	var box := RectangleShape2D.new()
	box.size = size
	_shape.shape = box
	_shape.position = size * 0.5
	_texture = AssetResolver.texture(GATE_TEXTURE if is_vertical() else HATCH_TEXTURE)
	if _canvas != null:
		_canvas.queue_redraw()


func _player_inside() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var rect: Rect2 = world_rect()
	for node: Node in tree.get_nodes_in_group(PLAYER_GROUP):
		var body := node as Node2D
		if body == null:
			continue
		var feet: Vector2 = body.global_position
		var box := Rect2(
			feet - Vector2(PLAYER_HALF_WIDTH, PLAYER_HEIGHT),
			Vector2(PLAYER_HALF_WIDTH * 2.0, PLAYER_HEIGHT)
		)
		if rect.intersects(box):
			return true
	return false


func _draw_plates() -> void:
	if _texture == null:
		return
	var tile: float = float(Balance.TILE_SIZE)
	if is_vertical():
		_draw_vertical(tile)
	else:
		_draw_horizontal(tile)


func _draw_vertical(tile: float) -> void:
	var full: float = float(size_tiles.y) * tile
	var stub: float = float(STUB_TILES) * tile
	var shown: float = lerpf(stub, full, _amount)
	var width: float = float(size_tiles.x) * tile
	var cap := Rect2(0.0, 0.0, tile, tile)
	var middle := Rect2(0.0, tile, tile, tile)
	var foot := Rect2(0.0, tile * 2.0, tile, tile)
	var y: float = 0.0
	_canvas.draw_texture_rect_region(_texture, Rect2(0.0, y, width, tile), cap)
	y += tile
	while y + tile < shown:
		_canvas.draw_texture_rect_region(_texture, Rect2(0.0, y, width, tile), middle)
		y += tile
	if shown > tile:
		_canvas.draw_texture_rect_region(_texture, Rect2(0.0, shown - tile, width, tile), foot)


func _draw_horizontal(tile: float) -> void:
	var full: float = float(size_tiles.x) * tile
	var shown: float = full * _amount
	if shown <= 0.0:
		return
	var source_width: float = float(_texture.get_width())
	var source := Rect2(source_width - source_width * _amount, 0.0, source_width * _amount, tile)
	_canvas.draw_texture_rect_region(
		_texture, Rect2(0.0, 0.0, shown, float(size_tiles.y) * tile), source
	)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
