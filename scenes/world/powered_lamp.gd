class_name PoweredLamp
extends Node2D

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true
@export var lamp_color: Color = Balance.LAMP_COLOR
@export var radius: float = Balance.LAMP_RADIUS
@export var energy: float = Balance.LAMP_ENERGY

var _tween: Tween = null

@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group(&"powered")
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _light.texture == null:
		push_warning("PoweredLamp: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.shadow_enabled = true
	_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	_apply_shape()
	set_powered_silent(powered)
	EventBus.energy_changed.connect(_on_energy_changed)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_light, "energy", energy if on else 0.0, Balance.LIGHT_FADE_TIME)


func set_powered_silent(on: bool) -> void:
	powered = on
	_kill_tween()
	_light.energy = energy if on else 0.0


func configure(params: Dictionary) -> void:
	terminal_id = StringName(params.get("terminal_id", terminal_id))
	system_id = StringName(params.get("system_id", system_id))
	if params.has("color"):
		lamp_color = Color(String(params.get("color", "")))
	radius = float(params.get("radius", radius))
	energy = float(params.get("energy", energy))
	if _light == null:
		return
	_apply_shape()
	set_powered_silent(powered)


func is_lit() -> bool:
	return powered


func _apply_shape() -> void:
	_light.color = lamp_color
	_light.texture_scale = LightMath.scale_for_radius(radius, LightMath.TEXTURE_SIZE)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _on_energy_changed(changed_terminal: StringName, changed_system: StringName, on: bool) -> void:
	if changed_terminal != terminal_id or changed_system != system_id:
		return
	set_powered(on)
