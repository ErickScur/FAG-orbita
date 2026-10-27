class_name HeatZone
extends Area2D

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const HAZARD_LAYER: int = 16
const LIGHT_COVER: float = 1.3
const WARM_COLOR: Color = Color("e07a3a")
const FURNACE_COLOR: Color = Color("ff5a1f")
const COLD_COLOR: Color = Color("7fc4ff")
const WARM_ENERGY: float = 0.7
const FURNACE_ENERGY: float = 1.1
const COLD_ENERGY: float = 0.35
const SHIMMER_COLOR: Color = Color(1.0, 0.6, 0.3, 0.35)
const FURNACE_SHIMMER_COLOR: Color = Color(1.0, 0.4, 0.15, 0.5)
const FLAKE_COLOR: Color = Color(0.85, 0.95, 1.0, 0.55)
const FLAKE_FALL: float = 8.0
const FLAKE_SPREAD_ANGLE: float = 35.0
const TILES_PER_PARTICLE: int = 4
const MAX_PARTICLES: int = 48
const PARTICLE_LIFETIME: float = 1.6
const PARTICLE_RISE: float = -10.0
const PARTICLE_SPREAD: float = 3.0
const PARTICLE_SPREAD_ANGLE: float = 10.0

@export var kind: StringName = HeatRules.KIND_WARM
@export var size_tiles: Vector2i = Vector2i.ONE

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _glow: PointLight2D = $Glow
@onready var _shimmer: CPUParticles2D = $Shimmer


func _ready() -> void:
	collision_layer = HAZARD_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	_apply_layout()


func configure(params: Dictionary) -> void:
	kind = HeatRules.normalize_kind(StringName(String(params.get("kind", kind))))
	size_tiles = parse_rect(params.get("rect", null), size_tiles)
	if _shape == null:
		return
	_apply_layout()


static func parse_rect(value: Variant, fallback: Vector2i) -> Vector2i:
	if value is Vector2i:
		return Vector2i(maxi(1, (value as Vector2i).x), maxi(1, (value as Vector2i).y))
	if value is Array and (value as Array).size() >= 2:
		var columns: int = int((value as Array)[0])
		var rows: int = int((value as Array)[1])
		return Vector2i(maxi(1, columns), maxi(1, rows))
	return fallback


static func area_rect(size: Vector2i, tile: int) -> Rect2:
	var half: float = float(tile) * 0.5
	return Rect2(Vector2(-half, -half), Vector2(size * tile))


static func unshaded_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material


func is_furnace() -> bool:
	return HeatRules.normalize_kind(kind) == HeatRules.KIND_FURNACE


func is_cold() -> bool:
	return HeatRules.is_cold(kind)


func world_rect() -> Rect2:
	var local: Rect2 = area_rect(size_tiles, Balance.TILE_SIZE)
	return Rect2(global_position + local.position, local.size)


func _apply_layout() -> void:
	kind = HeatRules.normalize_kind(kind)
	var rect: Rect2 = area_rect(size_tiles, Balance.TILE_SIZE)
	var center: Vector2 = rect.get_center()
	var box := RectangleShape2D.new()
	box.size = rect.size
	_shape.shape = box
	_shape.position = center
	_setup_glow(rect)
	_setup_shimmer(rect)


func _setup_glow(rect: Rect2) -> void:
	_glow.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _glow.texture == null:
		push_warning("HeatZone: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.color = _glow_color()
	_glow.energy = _glow_energy()
	_glow.texture_scale = 1.0
	_glow.position = rect.get_center()
	_glow.scale = rect.size * LIGHT_COVER / LightMath.TEXTURE_SIZE


func _setup_shimmer(rect: Rect2) -> void:
	var tiles: int = size_tiles.x * size_tiles.y
	_shimmer.amount = clampi(tiles / TILES_PER_PARTICLE, 1, MAX_PARTICLES)
	_shimmer.lifetime = PARTICLE_LIFETIME
	_shimmer.position = rect.get_center()
	_shimmer.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_shimmer.emission_rect_extents = rect.size * 0.5
	_shimmer.direction = Vector2.DOWN if is_cold() else Vector2.UP
	_shimmer.spread = FLAKE_SPREAD_ANGLE if is_cold() else PARTICLE_SPREAD_ANGLE
	_shimmer.gravity = Vector2(0.0, FLAKE_FALL if is_cold() else PARTICLE_RISE)
	_shimmer.initial_velocity_min = 0.0
	_shimmer.initial_velocity_max = PARTICLE_SPREAD
	_shimmer.color = _shimmer_color()
	_shimmer.material = unshaded_material()
	_shimmer.emitting = true


func _glow_color() -> Color:
	if is_cold():
		return COLD_COLOR
	return FURNACE_COLOR if is_furnace() else WARM_COLOR


func _glow_energy() -> float:
	if is_cold():
		return COLD_ENERGY
	return FURNACE_ENERGY if is_furnace() else WARM_ENERGY


func _shimmer_color() -> Color:
	if is_cold():
		return FLAKE_COLOR
	return FURNACE_SHIMMER_COLOR if is_furnace() else SHIMMER_COLOR
