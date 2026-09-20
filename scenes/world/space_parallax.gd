extends CanvasLayer

const FAR_PATH: String = "res://assets/backgrounds/space_far.png"
const MID_PATH: String = "res://assets/backgrounds/space_mid.png"
const NEAR_PATH: String = "res://assets/backgrounds/space_near.png"

@onready var _far: Sprite2D = $Far/FarSprite
@onready var _mid: Sprite2D = $Mid/MidSprite
@onready var _near: Sprite2D = $Near/NearSprite


func _ready() -> void:
	_apply(_far, FAR_PATH)
	_apply(_mid, MID_PATH)
	_apply(_near, NEAR_PATH)


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
