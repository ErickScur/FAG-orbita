class_name ElectricFloor
extends StaticBody2D

const SHEET_PATH: String = "res://assets/sprites/world/electric_floor.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FLOOR_GROUP: StringName = &"electric_floor"
const POWERED_GROUP: StringName = &"powered"
const HAZARD_GROUP: StringName = &"hazard"
const FRAMES: int = 4
const ROW_ON: int = 0
const ROW_OFF: int = 1
const ARC_FPS: float = 10.0
const TILE: float = 16.0
const GLOW_SEGMENT_TILES: int = 4
const GLOW_RADIUS: float = 20.0
const GLOW_ENERGY: float = 0.7
const GLOW_COLOR: Color = Color("5fe8ff")
const GLOW_FLICKER_HZ: float = 7.0
const GLOW_FLICKER_DEPTH: float = 0.35
const OFF_TINT: Color = Color(0.62, 0.62, 0.66, 1.0)
const PULSE_TINT: Color = Color(0.37, 0.91, 1.0, 1.0)

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true

var _clock: float = 0.0
var _segment_leader: bool = true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _surface: DamageArea = $Surface
@onready var _sparks: CPUParticles2D = $Sparks
@onready var _glow: PointLight2D = $Glow


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(HAZARD_GROUP)
	add_to_group(FLOOR_GROUP)
	_surface.damage_per_second = Balance.ELECTRIC_FLOOR_DPS
	_surface.contact_damage = 0
	_surface.knockback = false
	_surface.dash_passable = false
	_surface.status_id = StatusEffects.DISCHARGE
	_surface.status_duration = Balance.DISCHARGE_TIME
	_sparks.material = HeatZone.unshaded_material()
	_apply_sheet()
	_setup_glow()
	set_powered_silent(powered)
	_merge_glow.call_deferred()


func _process(delta: float) -> void:
	if not powered:
		return
	_clock += delta
	_sprite.frame = ROW_ON * FRAMES + int(_clock * ARC_FPS + _phase_offset()) % FRAMES
	if _glow.enabled:
		_glow.energy = GLOW_ENERGY * (
			1.0 - GLOW_FLICKER_DEPTH * absf(sin(_clock * TAU * GLOW_FLICKER_HZ * 0.5))
		)


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("powered"):
		powered = bool(params["powered"])
	if _surface == null:
		return
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	set_powered_silent(on)
	if _segment_leader:
		AudioManager.play_sfx(&"power_on" if on else &"power_off")
	Fx.burst(self, Fx.POWER_PULSE, global_position + Vector2(0.0, -TILE * 0.5), PULSE_TINT)


func set_powered_silent(on: bool) -> void:
	powered = on
	if _surface == null:
		return
	_surface.set_active(on)
	_sparks.emitting = on
	_glow.enabled = on and _segment_leader
	_glow.energy = GLOW_ENERGY
	_sprite.self_modulate = Color.WHITE if on else OFF_TINT
	_sprite.frame = (ROW_ON if on else ROW_OFF) * FRAMES


func is_live() -> bool:
	return powered and _surface != null and _surface.active


func glow_enabled() -> bool:
	return _glow != null and _glow.enabled


func cell() -> Vector2i:
	return Vector2i(floori(global_position.x / TILE), floori(global_position.y / TILE))


func _apply_sheet() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("ElectricFloor: folha ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = texture
	_sprite.hframes = FRAMES
	_sprite.vframes = 2


func _setup_glow() -> void:
	_glow.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.color = GLOW_COLOR
	_glow.texture_scale = LightMath.scale_for_radius(GLOW_RADIUS, LightMath.TEXTURE_SIZE)


func _phase_offset() -> float:
	return float(posmod(cell().x, FRAMES))


func _merge_glow() -> void:
	var row: Dictionary = _row_cells()
	var here: Vector2i = cell()
	var left: int = here.x
	while row.has(left - 1):
		left -= 1
	_segment_leader = (here.x - left) % GLOW_SEGMENT_TILES == 0
	if not _segment_leader:
		_glow.enabled = false
		return
	var span: int = 1
	while span < GLOW_SEGMENT_TILES and row.has(here.x + span):
		span += 1
	_glow.position = Vector2((float(span) - 1.0) * TILE * 0.5, -TILE * 0.5)
	_glow.scale = Vector2(maxf(1.0, float(span) * TILE / (GLOW_RADIUS * 2.0)), 1.0)
	_glow.enabled = powered


func _row_cells() -> Dictionary:
	var row: Dictionary = {}
	var here: Vector2i = cell()
	for node: Node in get_tree().get_nodes_in_group(FLOOR_GROUP):
		var floor_tile: ElectricFloor = node as ElectricFloor
		if floor_tile == null:
			continue
		var other: Vector2i = floor_tile.cell()
		if other.y == here.y:
			row[other.x] = true
	return row
