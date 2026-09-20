class_name LogObject
extends Interactable

const PROPS_SHEET: String = "res://assets/sprites/props/props_sheet.png"
const TERMINAL_SHEET: String = "res://assets/sprites/world/terminal_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const STYLE_PROP: StringName = &"prop"
const STYLE_TERMINAL: StringName = &"terminal"
const TERMINAL_COLUMN_OFF: int = 3
const TERMINAL_COLUMN_ON: int = 4
const PROMPT_DEFAULT: String = "EXAMINAR"

@export var style: StringName = &"prop"
@export var prop_column: int = 0
@export var log_id: StringName = &""

var _examined: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	if prompt_text.is_empty():
		prompt_text = PROMPT_DEFAULT
	interacted.connect(_on_interacted)
	_refresh_sprite()


func was_examined() -> bool:
	return _examined


func set_prop_column(column: int) -> void:
	prop_column = column
	_refresh_sprite()


func _refresh_sprite() -> void:
	if style == STYLE_TERMINAL:
		_apply_frame(
			TERMINAL_SHEET, TERMINAL_COLUMN_ON if _examined else TERMINAL_COLUMN_OFF
		)
		return
	_apply_frame(PROPS_SHEET, prop_column)


func _apply_frame(sheet: String, column: int) -> void:
	if _sprite == null:
		return
	var atlas: AtlasTexture = AssetResolver.atlas(sheet, FRAME_SIZE, column, 0)
	if atlas == null:
		push_warning("LogObject: sprite sheet ausente em %s" % sheet)
		return
	_sprite.texture = atlas


func _on_interacted(_actor: Node) -> void:
	_examined = true
	_refresh_sprite()
	AudioManager.play_sfx(&"log_pickup")
