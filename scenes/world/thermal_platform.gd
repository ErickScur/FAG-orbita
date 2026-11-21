class_name ThermalPlatform
extends MovingPlatform

const THERMAL_SHEET: String = "res://assets/sprites/world/thermal_platform_sheet.png"
const THERMAL_GROUP: StringName = &"thermal_platform"
const ENCOUNTER_GROUP: StringName = &"argos_encounter"
const HEAT_FRAMES: int = 4
const SPRITE_DROP: float = 4.0
const COLD_COLOR: Color = Color("6a5a58")
const HOT_COLOR: Color = Color("ffb06a")
const GLOW_RADIUS: float = 24.0

@export var phase_offset: float = 0.0

var _clock: float = 0.0
var _ratio: float = 0.0
var _frozen: bool = false
var _encounter: Node = null


func _ready() -> void:
	super()
	add_to_group(THERMAL_GROUP)
	powered = true
	_lamp.visible = false
	_light.texture_scale = LightMath.scale_for_radius(GLOW_RADIUS, LightMath.TEXTURE_SIZE)
	_apply_heat(lift_ratio())


func _physics_process(delta: float) -> void:
	if _frozen:
		return
	_clock += delta
	_ratio = lift_ratio()
	position = point_at(_ratio)
	_apply_heat(_ratio)


func configure(params: Dictionary) -> void:
	super.configure(params)
	phase_offset = float(params.get("phase", phase_offset))
	powered = true


func set_powered(_on: bool) -> void:
	powered = true


func set_powered_silent(_on: bool) -> void:
	powered = true
	_apply_status()


func lift_ratio() -> float:
	var encounter: Node = _find_encounter()
	if encounter != null and encounter.has_method(&"heat_clock"):
		return ArgosLogic.lift_ratio(float(encounter.call(&"heat_clock")), phase_offset)
	return ArgosLogic.lift_ratio(_clock, phase_offset)


func point_at(ratio: float) -> Vector2:
	var points: PackedVector2Array = route()
	if points.size() < 2:
		return _origin
	return points[0].lerp(points[points.size() - 1], clampf(ratio, 0.0, 1.0))


func current_ratio() -> float:
	return _ratio


func freeze() -> void:
	_frozen = true
	_apply_heat(0.0)


func unfreeze() -> void:
	_frozen = false


func is_frozen() -> bool:
	return _frozen


static func heat_frame(ratio: float) -> int:
	var scaled: float = clampf(ratio, 0.0, 0.999) * float(HEAT_FRAMES)
	return clampi(int(floorf(scaled)), 0, HEAT_FRAMES - 1)


func _apply_sprite() -> void:
	var texture: Texture2D = AssetResolver.texture(THERMAL_SHEET)
	if texture == null:
		push_warning("ThermalPlatform: folha ausente em %s" % THERMAL_SHEET)
		return
	_sprite.texture = texture
	_sprite.hframes = 1
	_sprite.vframes = HEAT_FRAMES
	_sprite.position = Vector2(0.0, SPRITE_DROP)


func _apply_status() -> void:
	pass


func _apply_heat(ratio: float) -> void:
	if _sprite == null:
		return
	_sprite.frame = heat_frame(ratio)
	_light.color = COLD_COLOR.lerp(HOT_COLOR, ratio)
	_light.energy = LIGHT_ENERGY * ratio
	_light.enabled = ratio > 0.05


func _find_encounter() -> Node:
	if _encounter != null and is_instance_valid(_encounter):
		return _encounter
	if not is_inside_tree():
		return null
	_encounter = get_tree().get_first_node_in_group(ENCOUNTER_GROUP)
	return _encounter
