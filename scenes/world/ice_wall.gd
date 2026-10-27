class_name IceWall
extends StaticBody2D

signal melted()
signal froze()

const SHEET_PATH: String = "res://assets/sprites/world/ice_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(16, 16)
const ROW: int = 1
const WORLD_LAYER: int = 1
const POWERED_GROUP: StringName = &"powered"
const PLAYER_GROUP: StringName = &"player"
const WALL_GROUP: StringName = &"ice_wall"
const STEAM_TINT: Color = Color(0.85, 0.95, 1.0, 0.8)
const MELT_SFX: StringName = &"spores"

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = false
@export var heater: StringName = &""

var _logic: IceWallLogic = IceWallLogic.new()
var _frame: int = -1
var _settled: bool = false
var _was_solid: bool = true

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _touch: Area2D = $Touch


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(WALL_GROUP)
	collision_layer = WORLD_LAYER
	collision_mask = 0
	_logic.heated = powered
	_refresh()


func _physics_process(delta: float) -> void:
	if heater != &"":
		_logic.heated = _heater_on()
	var occupied: bool = _player_touching()
	if occupied and IceWallLogic.melts_on_touch(GameState.abilities):
		_melt_column()
	if not _settled:
		_settled = true
		_logic.settle()
	else:
		_logic.update(delta, occupied)
	_apply_solid()
	_refresh()


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	heater = StringName(String(params.get("heater", heater)))
	if params.has("powered"):
		powered = bool(params["powered"])
	_logic.heated = powered


func set_powered(on: bool) -> void:
	powered = on
	if heater == &"":
		_logic.heated = on


func set_powered_silent(on: bool) -> void:
	set_powered(on)
	_settled = false


func is_active() -> bool:
	return powered


func is_solid() -> bool:
	return _logic.is_solid()


func is_melted_forever() -> bool:
	return _logic.is_melted_forever()


func melt_progress() -> float:
	return _logic.progress()


func current_frame() -> int:
	return _frame


func melt_forever() -> bool:
	if not _logic.melt_forever():
		return false
	Fx.burst(self, Fx.DUST_PUFF, global_position, STEAM_TINT)
	return true


func _melt_column() -> void:
	if not melt_forever():
		return
	var walls: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group(WALL_GROUP):
		if not (node is IceWall):
			continue
		var wall: IceWall = node
		if is_equal_approx(wall.global_position.x, global_position.x):
			walls[roundi(wall.global_position.y)] = wall
	for direction: int in [-1, 1]:
		var y: int = roundi(global_position.y) + direction * Balance.TILE_SIZE
		while walls.has(y):
			(walls[y] as IceWall).melt_forever()
			y += direction * Balance.TILE_SIZE


func _heater_on() -> bool:
	for node: Node in get_tree().get_nodes_in_group(heater):
		if node.has_method(&"is_active") and bool(node.call(&"is_active")):
			return true
	return false


func _player_touching() -> bool:
	for body: Node2D in _touch.get_overlapping_bodies():
		if body.is_in_group(PLAYER_GROUP):
			return true
	return false


func _apply_solid() -> void:
	var solid: bool = _logic.is_solid()
	if solid == _was_solid:
		return
	_was_solid = solid
	_shape.set_deferred(&"disabled", not solid)
	if solid:
		froze.emit()
		return
	AudioManager.play_sfx(MELT_SFX)
	melted.emit()


func _refresh() -> void:
	var wanted: int = _logic.frame()
	if wanted == _frame:
		return
	_frame = wanted
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, wanted, ROW)
	if atlas == null:
		push_warning("IceWall: folha de gelo ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas
