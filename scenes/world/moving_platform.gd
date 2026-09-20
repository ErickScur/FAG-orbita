class_name MovingPlatform
extends AnimatableBody2D

const SPRITE_PATH: String = "res://assets/sprites/world/moving_platform.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const POWERED_GROUP: StringName = &"powered"
const ONE_WAY_LAYER: int = 64
const COLOR_ON: Color = Color("7ad17a")
const COLOR_OFF: Color = Color("d15a5a")
const LIGHT_RADIUS: float = 24.0
const LIGHT_ENERGY: float = 0.7

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = false
@export var speed: float = 0.0
@export var wait_time: float = 0.0

var path_tiles: PackedVector2Array = PackedVector2Array()

var _follower: PathFollower = null
var _origin: Vector2 = Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _lamp: Polygon2D = $StatusLamp
@onready var _light: PointLight2D = $StatusLight


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	collision_layer = ONE_WAY_LAYER
	collision_mask = 0
	sync_to_physics = true
	_origin = position
	_apply_sprite()
	_setup_light()
	_build_follower()
	set_powered_silent(powered)
	EventBus.energy_changed.connect(_on_energy_changed)


func _physics_process(delta: float) -> void:
	if not powered or _follower == null:
		return
	position = _follower.step(position, delta)


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("path"):
		path_tiles = points_from(params["path"])
	if params.has("speed"):
		speed = float(params["speed"])
	if params.has("wait"):
		wait_time = float(params["wait"])
	if params.has("powered"):
		powered = bool(params["powered"])
	if _sprite == null:
		return
	_build_follower()
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	_apply_status()


func set_powered_silent(on: bool) -> void:
	powered = on
	_apply_status()


func is_moving() -> bool:
	return powered and _follower != null and not _follower.is_waiting()


func target_index() -> int:
	if _follower == null:
		return 0
	return _follower.progress_index()


func route() -> PackedVector2Array:
	if _follower == null:
		return PackedVector2Array()
	return _follower.points


static func points_from(value: Variant) -> PackedVector2Array:
	var result := PackedVector2Array()
	if not (value is Array):
		return result
	for entry: Variant in value as Array:
		if entry is Array and (entry as Array).size() >= 2:
			var pair: Array = entry
			result.append(Vector2(float(pair[0]), float(pair[1])))
		elif entry is Vector2:
			result.append(entry)
	return result


func _build_follower() -> void:
	var points := PackedVector2Array()
	if path_tiles.size() < 2:
		points.append(_origin)
	else:
		for offset: Vector2 in path_tiles:
			points.append(_origin + offset * float(Balance.TILE_SIZE))
	var move_speed: float = speed if speed > 0.0 else Balance.PLATFORM_SPEED
	var pause: float = wait_time if wait_time > 0.0 else Balance.PLATFORM_WAIT
	_follower = PathFollower.new(points, move_speed, pause)


func _apply_sprite() -> void:
	var texture: Texture2D = AssetResolver.texture(SPRITE_PATH)
	if texture == null:
		push_warning("MovingPlatform: sprite ausente em %s" % SPRITE_PATH)
		return
	_sprite.texture = texture


func _setup_light() -> void:
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _light.texture == null:
		push_warning("MovingPlatform: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.energy = LIGHT_ENERGY
	_light.texture_scale = LightMath.scale_for_radius(LIGHT_RADIUS, LightMath.TEXTURE_SIZE)


func _apply_status() -> void:
	if _lamp == null:
		return
	var color: Color = COLOR_ON if powered else COLOR_OFF
	_lamp.color = color
	_light.color = color


func _on_energy_changed(
	changed_terminal: StringName, changed_system: StringName, on: bool
) -> void:
	if changed_terminal != terminal_id or changed_system != system_id:
		return
	set_powered(on)
