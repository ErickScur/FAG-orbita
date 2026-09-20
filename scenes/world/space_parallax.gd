extends CanvasLayer

const FAR_PATH: String = "res://assets/backgrounds/space_far.png"
const MID_PATH: String = "res://assets/backgrounds/space_mid.png"
const NEAR_PATH: String = "res://assets/backgrounds/space_near.png"

@onready var _far_layer: Parallax2D = $Far
@onready var _mid_layer: Parallax2D = $Mid
@onready var _near_layer: Parallax2D = $Near
@onready var _far: Sprite2D = $Far/FarSprite
@onready var _mid: Sprite2D = $Mid/MidSprite
@onready var _near: Sprite2D = $Near/NearSprite


func _ready() -> void:
	_apply(_far, FAR_PATH)
	_apply(_mid, MID_PATH)
	_apply(_near, NEAR_PATH)
	_tune(_far_layer, Balance.PARALLAX_FAR_SCALE, Balance.PARALLAX_FAR_DIM)
	_tune(_mid_layer, Balance.PARALLAX_MID_SCALE, Balance.PARALLAX_MID_DIM)
	_tune(_near_layer, Balance.PARALLAX_NEAR_SCALE, 1.0)


func layer_scales() -> PackedVector2Array:
	return [_far_layer.scroll_scale, _mid_layer.scroll_scale, _near_layer.scroll_scale]


func _tune(layer: Parallax2D, scroll: Vector2, dim: float) -> void:
	layer.scroll_scale = scroll
	layer.follow_viewport = false
	layer.modulate = Color(dim, dim, dim, 1.0)


func layer_offsets() -> PackedVector2Array:
	return [
		($Far as Parallax2D).scroll_offset,
		($Mid as Parallax2D).scroll_offset,
		($Near as Parallax2D).scroll_offset,
	]


func _apply(sprite: Sprite2D, path: String) -> void:
	var texture: Texture2D = AssetResolver.texture(path)
	if texture == null:
		push_warning("SpaceParallax: camada ausente em %s" % path)
		return
	sprite.texture = texture
