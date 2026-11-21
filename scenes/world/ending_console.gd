class_name EndingConsole
extends Interactable

const SHEET_PATH: String = "res://assets/sprites/world/command_machines_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(64, 64)
const ROW: int = 1
const GROUP: StringName = &"ending_console"
const COLUMNS: Dictionary = {&"seeding": 0, &"transmission": 2}

@export var ending_id: StringName = EndingData.SEEDING

var pulled: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	add_to_group(GROUP)
	var prompt: String = EndingData.text(EndingData.load_table(), ending_id, "prompt")
	if not prompt.is_empty():
		prompt_text = prompt
	_apply()


func set_pulled(on: bool) -> void:
	pulled = on
	set_enabled(not on)
	_apply()


func _apply() -> void:
	var column: int = int(COLUMNS.get(ending_id, 0)) + (1 if pulled else 0)
	var texture: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, ROW)
	if texture == null:
		push_warning("EndingConsole: folha ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = texture
