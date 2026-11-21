class_name EndingMachine
extends Node2D

const SHEET_PATH: String = "res://assets/sprites/world/command_machines_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(64, 64)
const GROUP: StringName = &"ending_machine"
const MACHINE_CAPSULE: StringName = &"capsule"
const MACHINE_ANTENNA: StringName = &"antenna"
const COLUMNS: Dictionary = {&"capsule": 0, &"antenna": 2}
const ENDINGS: Dictionary = {&"capsule": &"seeding", &"antenna": &"transmission"}
const GLOW_COLORS: Dictionary = {&"capsule": Color("7bd88f"), &"antenna": Color("7fe3f0")}

@export var machine: StringName = MACHINE_CAPSULE
@export var active: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	add_to_group(GROUP)
	_glow.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_glow.color = GLOW_COLORS.get(machine, Balance.LAMP_COLOR)
	_glow.energy = Balance.LAMP_ENERGY
	_glow.texture_scale = LightMath.scale_for_radius(Balance.LAMP_RADIUS, LightMath.TEXTURE_SIZE)
	_apply()


func ending_id() -> StringName:
	return ENDINGS.get(machine, &"")


func set_active(on: bool) -> void:
	active = on
	_apply()


func _apply() -> void:
	if _sprite == null:
		return
	var column: int = int(COLUMNS.get(machine, 0)) + (1 if active else 0)
	var texture: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, 0)
	if texture == null:
		push_warning("EndingMachine: folha ausente em %s" % SHEET_PATH)
	else:
		_sprite.texture = texture
	_glow.enabled = active
