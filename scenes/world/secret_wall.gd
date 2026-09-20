class_name SecretWall
extends StaticBody2D

const WALL_LAYER: int = 1
const GROUP_PREFIX: String = "secret_"
const SFX_REVEAL: StringName = &"secret_found"
const DEFAULT_TILES: String = "res://assets/tiles/greenhouse_tiles.png"
const TILE_FRAME: Vector2i = Vector2i(16, 16)

@export var secret_id: StringName = &""
@export var tiles_path: String = DEFAULT_TILES
@export var tile_column: int = 7
@export var tile_row: int = 1

var _revealed: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _touch: Area2D = $Touch


func _ready() -> void:
	collision_layer = WALL_LAYER
	collision_mask = 0
	_apply_texture()
	if secret_id != &"":
		add_to_group(group_name())
	if GameState.has_secret(secret_id):
		reveal(true)
		return
	_touch.body_entered.connect(_on_touch_body_entered)


func configure(params: Dictionary) -> void:
	if params.has("secret"):
		secret_id = StringName(String(params["secret"]))
	if params.has("tiles"):
		tiles_path = String(params["tiles"])


func group_name() -> StringName:
	return StringName(GROUP_PREFIX + String(secret_id))


func _occluder_node() -> LightOccluder2D:
	return get_node_or_null(^"Occluder") as LightOccluder2D


func is_revealed() -> bool:
	return _revealed


func reveal(instant: bool) -> void:
	if _revealed:
		return
	_revealed = true
	var occluder: LightOccluder2D = _occluder_node()
	if occluder != null:
		occluder.set_deferred(&"visible", false)
	set_deferred(&"collision_layer", 0)
	_shape.set_deferred(&"disabled", true)
	_touch.set_deferred(&"monitoring", false)
	if instant:
		modulate.a = Balance.SECRET_WALL_ALPHA
		return
	var tween: Tween = create_tween()
	tween.tween_property(
		self, ^"modulate:a", Balance.SECRET_WALL_ALPHA, Balance.SECRET_WALL_FADE_TIME
	)


func _apply_texture() -> void:
	var texture: AtlasTexture = AssetResolver.atlas(
		tiles_path, TILE_FRAME, tile_column, tile_row
	)
	if texture == null:
		push_warning("SecretWall: folha de tiles ausente em %s" % tiles_path)
		return
	_sprite.texture = texture


func _on_touch_body_entered(body: Node2D) -> void:
	if _revealed or not body.is_in_group(&"player"):
		return
	if GameState.register_secret(secret_id):
		AudioManager.play_sfx(SFX_REVEAL)
	_reveal_group()


func _reveal_group() -> void:
	if secret_id == &"":
		reveal(false)
		return
	for node: Node in get_tree().get_nodes_in_group(group_name()):
		if node is SecretWall:
			(node as SecretWall).reveal(false)
