class_name PoweredLamp
extends Node2D

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const TILE_SHEET: String = "res://assets/tiles/core_tiles.png"
const TILE_FRAME: Vector2i = Vector2i(16, 16)
const ATLAS_COLUMNS: int = 8
const FRAME_ON: int = 22
const FRAME_OFF: int = 25
const FIXTURE_TINT: float = 0.35

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true
@export var lamp_color: Color = Balance.LAMP_COLOR
@export var radius: float = Balance.LAMP_RADIUS
@export var energy: float = Balance.LAMP_ENERGY
@export var sheet: String = TILE_SHEET
@export var frame_on: int = FRAME_ON
@export var frame_off: int = FRAME_OFF

var _tween: Tween = null
var _pulse_time: float = 0.0
var _base_energy: float = 0.0

@onready var _light: PointLight2D = $Light
@onready var _fixture: Sprite2D = $Fixture


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
	_pulse_time = _pulse_phase()
	set_process(true)


func _process(delta: float) -> void:
	if not powered or _tween != null:
		return
	_pulse_time += delta
	_light.energy = LightMath.pulse(
		_base_energy, _pulse_time, Balance.LAMP_PULSE_HZ, Balance.LAMP_PULSE_DEPTH
	)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	_apply_fixture()
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	_kill_tween()
	_base_energy = energy
	_tween = create_tween()
	_tween.tween_property(_light, "energy", energy if on else 0.0, Balance.LIGHT_FADE_TIME)
	_tween.tween_callback(_kill_tween)
	Fx.burst(self, Fx.POWER_PULSE, global_position, lamp_color)


func set_powered_silent(on: bool) -> void:
	powered = on
	_apply_fixture()
	_kill_tween()
	_base_energy = energy
	_light.energy = energy if on else 0.0


func configure(params: Dictionary) -> void:
	terminal_id = StringName(params.get("terminal_id", terminal_id))
	system_id = StringName(params.get("system_id", system_id))
	if params.has("color"):
		lamp_color = Color(String(params.get("color", "")))
	radius = float(params.get("radius", radius))
	energy = float(params.get("energy", energy))
	sheet = String(params.get("sheet", sheet))
	frame_on = int(params.get("frame_on", frame_on))
	frame_off = int(params.get("frame_off", frame_off))
	if _light == null:
		return
	_apply_shape()
	set_powered_silent(powered)


func is_lit() -> bool:
	return powered


func _apply_shape() -> void:
	_light.color = lamp_color
	_light.texture_scale = LightMath.scale_for_radius(radius, LightMath.TEXTURE_SIZE)


func _apply_fixture() -> void:
	if _fixture == null:
		return
	var index: int = frame_on if powered else frame_off
	var texture: AtlasTexture = AssetResolver.atlas(
		sheet, TILE_FRAME, index % ATLAS_COLUMNS, index / ATLAS_COLUMNS
	)
	if texture == null:
		push_warning("PoweredLamp: quadro de luminária ausente em %s" % sheet)
		return
	_fixture.texture = texture
	_fixture.self_modulate = (
		Color.WHITE.lerp(lamp_color, FIXTURE_TINT) if powered else Color.WHITE
	)


func _pulse_phase() -> float:
	return float(int(absf(position.x) + absf(position.y)) % 16) * 0.25


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _on_energy_changed(changed_terminal: StringName, changed_system: StringName, on: bool) -> void:
	if changed_terminal != terminal_id or changed_system != system_id:
		return
	set_powered(on)
