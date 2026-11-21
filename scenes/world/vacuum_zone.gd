class_name VacuumZone
extends Area2D

const STARS_TEXTURE: String = "res://assets/backgrounds/space_far.png"
const HAZARD_LAYER: int = 16
const VACUUM_GROUP: StringName = &"vacuum_zone"
const BACKDROP_Z: int = -9
const BORDER_Z: int = 5
const STARS_SCROLL: float = 0.92
const STARS_OPEN: Color = Color(1.0, 1.0, 1.0, 1.0)
const STARS_SEALED: Color = Color(0.35, 0.62, 0.78, 0.3)
const FIELD_COLOR: Color = Color(0.37, 0.91, 1.0, 0.16)
const BORDER_OPEN: Color = Color("f2c230")
const BORDER_SEALED: Color = Color(0.37, 0.91, 1.0, 0.55)
const BORDER_WIDTH: float = 1.0
const BORDER_DASH: float = 4.0
const BORDER_INSET: float = 0.5
const BLINK_HZ: float = 1.2
const BLINK_DEPTH: float = 0.45
const DEBRIS_COLOR: Color = Color(0.62, 0.66, 0.72, 0.75)
const DEBRIS_TILES_PER_PARTICLE: int = 6
const DEBRIS_MAX: int = 40
const DEBRIS_LIFETIME: float = 9.0
const DEBRIS_SPEED: float = 6.0
const DEBRIS_SIZE_MIN: float = 1.0
const DEBRIS_SIZE_MAX: float = 2.5
const FADE_TIME: float = 0.6

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true
@export var size_tiles: Vector2i = Vector2i.ONE

var _tween: Tween = null
var _blink: float = 0.0
var _rect: Rect2 = Rect2()
var _backdrop: Sprite2D = null
var _field: ColorRect = null
var _debris: CPUParticles2D = null
var _border: Node2D = null
var _seal: float = 0.0

@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(VACUUM_GROUP)
	collision_layer = HAZARD_LAYER
	collision_mask = 0
	monitoring = false
	monitorable = true
	_build_visuals()
	_apply_layout()
	set_powered_silent(powered)


func _process(delta: float) -> void:
	_blink += delta
	_scroll_stars()
	if _border != null:
		_border.queue_redraw()


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
	AudioManager.play_sfx(&"power_off" if on else &"power_on")
	_debris.emitting = on
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_seal, _seal, 0.0 if on else 1.0, FADE_TIME)


func set_powered_silent(on: bool) -> void:
	powered = on
	_kill_tween()
	if _debris == null:
		return
	_debris.emitting = on
	_set_seal(0.0 if on else 1.0)


func is_active() -> bool:
	return powered


func world_rect() -> Rect2:
	return Rect2(global_position + _rect.position, _rect.size)


func contains_point(point: Vector2) -> bool:
	return world_rect().has_point(point)


func _build_visuals() -> void:
	_backdrop = Sprite2D.new()
	_backdrop.name = "Stars"
	_backdrop.z_index = BACKDROP_Z
	_backdrop.centered = false
	_backdrop.region_enabled = true
	_backdrop.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_backdrop.texture = AssetResolver.texture(STARS_TEXTURE)
	_backdrop.material = _unshaded(CanvasItemMaterial.BLEND_MODE_MIX)
	add_child(_backdrop)
	_field = ColorRect.new()
	_field.name = "Field"
	_field.z_index = BACKDROP_Z
	_field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_field.color = FIELD_COLOR
	_field.material = _unshaded(CanvasItemMaterial.BLEND_MODE_ADD)
	add_child(_field)
	_debris = CPUParticles2D.new()
	_debris.name = "Debris"
	_debris.local_coords = false
	_debris.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_debris.direction = Vector2.RIGHT
	_debris.spread = 180.0
	_debris.gravity = Vector2.ZERO
	_debris.initial_velocity_min = DEBRIS_SPEED * 0.3
	_debris.initial_velocity_max = DEBRIS_SPEED
	_debris.angular_velocity_min = -40.0
	_debris.angular_velocity_max = 40.0
	_debris.scale_amount_min = DEBRIS_SIZE_MIN
	_debris.scale_amount_max = DEBRIS_SIZE_MAX
	_debris.lifetime = DEBRIS_LIFETIME
	_debris.preprocess = DEBRIS_LIFETIME
	_debris.color = DEBRIS_COLOR
	_debris.material = _unshaded(CanvasItemMaterial.BLEND_MODE_MIX)
	add_child(_debris)
	_border = Node2D.new()
	_border.name = "Border"
	_border.z_index = BORDER_Z
	_border.material = _unshaded(CanvasItemMaterial.BLEND_MODE_MIX)
	_border.draw.connect(_draw_border)
	add_child(_border)


func _apply_layout() -> void:
	_rect = HeatZone.area_rect(size_tiles, Balance.TILE_SIZE)
	var box := RectangleShape2D.new()
	box.size = _rect.size
	_shape.shape = box
	_shape.position = _rect.get_center()
	if _backdrop == null:
		return
	_backdrop.position = _rect.position
	_backdrop.region_rect = Rect2(Vector2.ZERO, _rect.size)
	_field.position = _rect.position
	_field.size = _rect.size
	var tiles: int = size_tiles.x * size_tiles.y
	_debris.amount = clampi(tiles / DEBRIS_TILES_PER_PARTICLE, 1, DEBRIS_MAX)
	_debris.position = _rect.get_center()
	_debris.emission_rect_extents = _rect.size * 0.5
	_scroll_stars()


func _scroll_stars() -> void:
	if _backdrop == null or not is_inside_tree():
		return
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var camera_origin: Vector2 = -viewport.get_canvas_transform().origin
	var offset: Vector2 = (camera_origin * STARS_SCROLL).round()
	_backdrop.region_rect = Rect2(_rect.position - offset, _rect.size)


func _set_seal(value: float) -> void:
	_seal = clampf(value, 0.0, 1.0)
	if _backdrop != null:
		_backdrop.modulate = STARS_OPEN.lerp(STARS_SEALED, _seal)
	if _field != null:
		_field.modulate = Color(1.0, 1.0, 1.0, _seal)
	if _border != null:
		_border.queue_redraw()


func _draw_border() -> void:
	var color: Color = BORDER_OPEN.lerp(BORDER_SEALED, _seal)
	if _seal < 0.5:
		var wave: float = 0.5 + 0.5 * sin(_blink * TAU * BLINK_HZ)
		color.a *= 1.0 - BLINK_DEPTH * wave
	var box: Rect2 = _rect.grow(-BORDER_INSET)
	var corners: Array[Vector2] = [
		box.position,
		Vector2(box.end.x, box.position.y),
		box.end,
		Vector2(box.position.x, box.end.y),
	]
	for index: int in range(corners.size()):
		var start: Vector2 = corners[index]
		var finish: Vector2 = corners[(index + 1) % corners.size()]
		if _seal >= 0.5:
			_border.draw_line(start, finish, color, BORDER_WIDTH)
		else:
			_border.draw_dashed_line(start, finish, color, BORDER_WIDTH, BORDER_DASH)


func _unshaded(blend: CanvasItemMaterial.BlendMode) -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = blend
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
