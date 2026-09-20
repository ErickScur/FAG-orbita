class_name MagneticWall
extends StaticBody2D

const TILE_SHEET: String = "res://assets/tiles/greenhouse_tiles.png"
const TILE_FRAME: Vector2i = Vector2i(16, 16)
const TILE_COLUMN: int = 0
const TILE_ROW: int = 3
const WORLD_LAYER: int = 1
const GLOW_TEXTURE: String = "res://assets/fx/light_radial.png"

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	add_to_group(ClimbLogic.MAGNETIC_GROUP)
	collision_layer = WORLD_LAYER
	collision_mask = 0
	_apply_texture()
	_setup_glow()


func glow_energy() -> float:
	return _glow.energy


func _apply_texture() -> void:
	var texture: AtlasTexture = AssetResolver.atlas(
		TILE_SHEET, TILE_FRAME, TILE_COLUMN, TILE_ROW
	)
	if texture == null:
		push_warning("MagneticWall: tile de parede magnética ausente em %s" % TILE_SHEET)
		return
	_sprite.texture = texture
	_sprite.self_modulate = Color(Balance.MAGNETIC_SELF_LIGHT, Balance.MAGNETIC_SELF_LIGHT, Balance.MAGNETIC_SELF_LIGHT, 1.0)


func _setup_glow() -> void:
	_glow.texture = AssetResolver.texture(GLOW_TEXTURE)
	if _glow.texture == null:
		push_warning("MagneticWall: textura de luz ausente em %s" % GLOW_TEXTURE)
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.color = Balance.MAGNETIC_GLOW_COLOR
	_glow.energy = Balance.MAGNETIC_GLOW_ENERGY
	_glow.texture_scale = LightMath.scale_for_radius(Balance.MAGNETIC_GLOW_RADIUS, LightMath.TEXTURE_SIZE)
