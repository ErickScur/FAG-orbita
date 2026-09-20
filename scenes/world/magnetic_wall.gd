class_name MagneticWall
extends StaticBody2D

const TILE_SHEET: String = "res://assets/tiles/greenhouse_tiles.png"
const TILE_FRAME: Vector2i = Vector2i(16, 16)
const TILE_COLUMN: int = 0
const TILE_ROW: int = 3
const WORLD_LAYER: int = 1

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	add_to_group(ClimbLogic.MAGNETIC_GROUP)
	collision_layer = WORLD_LAYER
	collision_mask = 0
	_apply_texture()


func _apply_texture() -> void:
	var texture: AtlasTexture = AssetResolver.atlas(
		TILE_SHEET, TILE_FRAME, TILE_COLUMN, TILE_ROW
	)
	if texture == null:
		push_warning("MagneticWall: tile de parede magnética ausente em %s" % TILE_SHEET)
		return
	_sprite.texture = texture
