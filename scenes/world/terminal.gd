class_name Terminal
extends Interactable

const SHEET_PATH: String = "res://assets/sprites/world/terminal_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const COLUMN_OFF: int = 3
const COLUMN_ON: int = 4
const PROMPT_DEFAULT: String = "LER REGISTRO"
const PROMPT_READ: String = "LER DE NOVO"

@export var log_id: StringName = &""

var _read: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if prompt_text.is_empty():
		prompt_text = PROMPT_DEFAULT
	interacted.connect(_on_interacted)
	_apply_column(COLUMN_OFF)


func was_read() -> bool:
	return _read


func _apply_column(column: int) -> void:
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, 0)
	if atlas == null:
		push_warning("Terminal: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas


func _on_interacted(_actor: Node) -> void:
	_read = true
	set_prompt(PROMPT_READ)
	_apply_column(COLUMN_ON)
	AudioManager.play_sfx(&"terminal_breaker")
