class_name LevelExit
extends Area2D

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const SHEET_PATH: String = "res://assets/sprites/world/door_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 48)
const FRAME_OPEN: int = 4
const PLAYER_MASK: int = 2
const LIGHT_COLOR: Color = Color("8fe3b0")
const LIGHT_RADIUS: float = 80.0
const LIGHT_ENERGY: float = 1.1

@export var target: String = ""

var _used: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group(&"level_exit")
	collision_layer = 0
	collision_mask = PLAYER_MASK
	monitorable = false
	_apply_sprite()
	_apply_light()
	body_entered.connect(_on_body_entered)


func configure(params: Dictionary) -> void:
	if params.has("target"):
		target = String(params["target"])


func has_target() -> bool:
	return not target.is_empty() and ResourceLoader.exists(target)


func _apply_sprite() -> void:
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, FRAME_OPEN, 0)
	if atlas == null:
		push_warning("LevelExit: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas


func _apply_light() -> void:
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _light.texture == null:
		push_warning("LevelExit: textura de luz ausente em %s" % LIGHT_TEXTURE)
		return
	_light.color = LIGHT_COLOR
	_light.energy = LIGHT_ENERGY
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.texture_scale = LightMath.scale_for_radius(LIGHT_RADIUS, LightMath.TEXTURE_SIZE)


func _on_body_entered(body: Node2D) -> void:
	if _used or not body.is_in_group(&"player"):
		return
	_used = true
	AudioManager.play_sfx(&"door_open")
	if has_target():
		SceneManager.goto(target)
		return
	EventBus.demo_completed.emit()
