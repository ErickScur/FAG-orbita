class_name LogObject
extends Interactable

const SHEET_PATH: String = "res://assets/sprites/props/props_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const PROMPT_DEFAULT: String = "EXAMINAR"

@export var prop_column: int = 0
@export var log_id: StringName = &""

var _examined: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if prompt_text.is_empty():
		prompt_text = PROMPT_DEFAULT
	interacted.connect(_on_interacted)
	_apply_column(prop_column)


func was_examined() -> bool:
	return _examined


func _apply_column(column: int) -> void:
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, 0)
	if atlas == null:
		push_warning("LogObject: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas


func _on_interacted(_actor: Node) -> void:
	_examined = true
	AudioManager.play_sfx(&"log_pickup")
