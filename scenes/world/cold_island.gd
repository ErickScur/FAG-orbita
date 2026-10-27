class_name ColdIsland
extends Area2D

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const HAZARD_LAYER: int = 16
const POWERED_GROUP: StringName = &"powered"
const LIGHT_COVER: float = 1.3
const LIGHT_COLOR: Color = Color("4aa8ff")
const LIGHT_ENERGY: float = 1.2
const FROST_COLOR: Color = Color(0.85, 0.95, 1.0, 0.6)
const TILES_PER_PARTICLE: int = 2
const MAX_PARTICLES: int = 32
const PARTICLE_LIFETIME: float = 2.4
const PARTICLE_FALL: float = 6.0
const PARTICLE_DRIFT: float = 2.0
const PARTICLE_SPREAD_ANGLE: float = 30.0

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true
@export var size_tiles: Vector2i = Vector2i.ONE

var _tween: Tween = null

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _glow: PointLight2D = $Glow
@onready var _frost: CPUParticles2D = $Frost


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	collision_layer = HAZARD_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	_apply_layout()
	set_powered_silent(powered)


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	size_tiles = HeatZone.parse_rect(params.get("rect", null), size_tiles)
	if params.has("powered"):
		powered = bool(params["powered"])
	if _shape == null:
		return
	_apply_layout()
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	_frost.emitting = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	_kill_tween()
	_glow.enabled = true
	_tween = create_tween()
	_tween.tween_property(_glow, "energy", LIGHT_ENERGY if on else 0.0, Balance.LIGHT_FADE_TIME)
	_tween.tween_callback(_finish_fade)


func set_powered_silent(on: bool) -> void:
	powered = on
	_kill_tween()
	if _glow == null:
		return
	_glow.energy = LIGHT_ENERGY if on else 0.0
	_glow.enabled = on
	_frost.emitting = on


func is_active() -> bool:
	return powered


func world_rect() -> Rect2:
	var local: Rect2 = HeatZone.area_rect(size_tiles, Balance.TILE_SIZE)
	return Rect2(global_position + local.position, local.size)


func _apply_layout() -> void:
	var rect: Rect2 = HeatZone.area_rect(size_tiles, Balance.TILE_SIZE)
	var box := RectangleShape2D.new()
	box.size = rect.size
	_shape.shape = box
	_shape.position = rect.get_center()
	_glow.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _glow.texture == null:
		push_warning("ColdIsland: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.color = LIGHT_COLOR
	_glow.texture_scale = 1.0
	_glow.position = rect.get_center()
	_glow.scale = rect.size * LIGHT_COVER / LightMath.TEXTURE_SIZE
	var tiles: int = size_tiles.x * size_tiles.y
	_frost.amount = clampi(tiles / TILES_PER_PARTICLE, 1, MAX_PARTICLES)
	_frost.lifetime = PARTICLE_LIFETIME
	_frost.position = rect.get_center()
	_frost.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_frost.emission_rect_extents = rect.size * 0.5
	_frost.direction = Vector2.DOWN
	_frost.spread = PARTICLE_SPREAD_ANGLE
	_frost.gravity = Vector2(0.0, PARTICLE_FALL)
	_frost.initial_velocity_min = 0.0
	_frost.initial_velocity_max = PARTICLE_DRIFT
	_frost.color = FROST_COLOR
	_frost.material = HeatZone.unshaded_material()


func _finish_fade() -> void:
	_glow.enabled = powered
	_kill_tween()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
