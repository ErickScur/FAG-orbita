class_name ThinIce
extends StaticBody2D

signal cracked()
signal broke()
signal reformed()

const SHEET_PATH: String = "res://assets/sprites/world/ice_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(16, 16)
const ROW: int = 0
const WORLD_LAYER: int = 1
const SHARD_TINT: Color = Color(0.8, 0.93, 1.0, 0.9)
const CRACK_SFX: StringName = &"land"
const BREAK_SFX: StringName = &"door_close"

var _logic: ThinIceLogic = ThinIceLogic.new()
var _frame: int = -1

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _top: Area2D = $Top
@onready var _space: Area2D = $Space


func _ready() -> void:
	collision_layer = WORLD_LAYER
	collision_mask = 0
	_refresh()


func _physics_process(delta: float) -> void:
	var stepped: bool = _top.has_overlapping_bodies()
	var occupied: bool = _space.has_overlapping_bodies()
	match _logic.update(delta, stepped, occupied):
		&"cracked":
			AudioManager.play_sfx(CRACK_SFX)
			cracked.emit()
		&"broke":
			_set_solid(false)
			AudioManager.play_sfx(BREAK_SFX)
			Fx.burst(self, Fx.DUST_PUFF, global_position, SHARD_TINT)
			broke.emit()
		&"reformed":
			_set_solid(true)
			reformed.emit()
	_refresh()


func configure(_params: Dictionary) -> void:
	return


func is_solid() -> bool:
	return _logic.is_solid()


func state() -> ThinIceLogic.State:
	return _logic.state()


func current_frame() -> int:
	return _frame


func _set_solid(solid: bool) -> void:
	_shape.set_deferred(&"disabled", not solid)


func _refresh() -> void:
	var wanted: int = _logic.frame()
	if wanted == _frame:
		return
	_frame = wanted
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, wanted, ROW)
	if atlas == null:
		push_warning("ThinIce: folha de gelo ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas
