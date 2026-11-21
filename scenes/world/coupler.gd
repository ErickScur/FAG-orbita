class_name Coupler
extends Node2D

enum State { OFF, CHARGING, POWERED, SEALED }

const SHEET: String = "res://assets/sprites/world/coupler_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const POWERED_GROUP: StringName = &"powered"
const COUPLER_GROUP: StringName = &"coupler"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const GLOW_COLOR: Color = Color("5fe8ff")
const GLOW_RADIUS: float = 28.0
const GLOW_ENERGY: Dictionary = {
	State.OFF: 0.0,
	State.CHARGING: 0.45,
	State.POWERED: 1.0,
	State.SEALED: 0.0,
}

@export var coupler_id: StringName = &""
@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = false

var state: State = State.OFF

var _sprite: Sprite2D = null
var _glow: PointLight2D = null


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(COUPLER_GROUP)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetResolver.texture(SHEET)
	_sprite.hframes = 4
	_sprite.offset = Vector2(0.0, -float(FRAME_SIZE.y) * 0.5)
	add_child(_sprite)
	_glow = PointLight2D.new()
	_glow.name = "Glow"
	_glow.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_glow.color = GLOW_COLOR
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.position = Vector2(0.0, -float(FRAME_SIZE.y) * 0.5)
	_glow.texture_scale = LightMath.scale_for_radius(GLOW_RADIUS, LightMath.TEXTURE_SIZE)
	add_child(_glow)
	set_powered_silent(powered)


func configure(params: Dictionary) -> void:
	coupler_id = StringName(String(params.get("coupler_id", params.get("id", coupler_id))))
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("powered"):
		powered = bool(params["powered"])
	if _sprite == null:
		return
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on and state != State.SEALED:
		return
	powered = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	set_state(State.POWERED if on else State.OFF)


func set_powered_silent(on: bool) -> void:
	powered = on
	set_state(State.POWERED if on else State.OFF)


func set_state(next: State) -> void:
	state = next
	if _sprite == null:
		return
	_sprite.frame = int(next)
	var energy: float = float(GLOW_ENERGY.get(next, 0.0))
	_glow.energy = energy
	_glow.enabled = energy > 0.0


func is_powered() -> bool:
	return state == State.POWERED
