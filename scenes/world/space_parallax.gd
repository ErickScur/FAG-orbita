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
	_mount(_far_layer, _far, FAR_PATH, Balance.PARALLAX_FAR_SCALE, Balance.PARALLAX_FAR_DIM)
	_mount(_mid_layer, _mid, MID_PATH, Balance.PARALLAX_MID_SCALE, Balance.PARALLAX_MID_DIM)
	_mount(_near_layer, _near, NEAR_PATH, Balance.PARALLAX_NEAR_SCALE, 1.0)


func layer_scales() -> PackedVector2Array:
	return [_far_layer.scroll_scale, _mid_layer.scroll_scale, _near_layer.scroll_scale]


func layer_offsets() -> PackedVector2Array:
	return [
		($Far as Parallax2D).scroll_offset,
		($Mid as Parallax2D).scroll_offset,
		($Near as Parallax2D).scroll_offset,
	]


func layer_sizes() -> PackedVector2Array:
	return [_far_layer.repeat_size, _mid_layer.repeat_size, _near_layer.repeat_size]


func _mount(
	layer: Parallax2D, sprite: Sprite2D, path: String, scroll: Vector2, dim: float
) -> void:
	_tune(layer, scroll, dim)
	var texture: Texture2D = AssetResolver.texture(path)
	if texture == null:
		push_warning("SpaceParallax: camada ausente em %s" % path)
		return
	sprite.texture = texture
	layer.repeat_size = texture.get_size()


func _tune(layer: Parallax2D, scroll: Vector2, dim: float) -> void:
	layer.scroll_scale = scroll
	layer.follow_viewport = false
	layer.modulate = Color(dim, dim, dim, 1.0)
