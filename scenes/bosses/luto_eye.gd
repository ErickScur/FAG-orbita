class_name LutoEye
extends Node2D

const SHEET_PATH: String = "res://assets/sprites/bosses/luto_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(64, 64)
const GROUP: StringName = &"mem_luto"
const IDLE_FPS: float = 5.0
const BOB_SPEED: float = 1.6
const BOB_HEIGHT: float = 3.0
const DRIFT_RATE: float = 2.5
const BEAM_COLOR: Color = Color("ff5fa8")
const BEAM_WIDTH: float = 2.0
const LIGHT_COLOR: Color = Color("ff5fa8")
const LIGHT_RADIUS: float = 72.0
const LIGHT_ENERGY_IDLE: float = 0.6
const LIGHT_ENERGY_POWERED: float = 1.3
const SINGLE_FRAMES: Dictionary = {&"alert": 0, &"attack": 1, &"hurt": 2, &"closed": 3}
const Z_BEHIND_WORLD: int = -5
const SCREEN_MIN_CENTER_Y: float = 74.0

var powered: bool = false

var _sprite: AnimatedSprite2D = null
var _beam: Line2D = null
var _light: PointLight2D = null
var _elapsed: float = 0.0
var _anchor: Vector2 = Vector2.ZERO
var _beam_target: Vector2 = Vector2.ZERO
var _beam_on: bool = false
var _hold: StringName = &""


func _ready() -> void:
	add_to_group(GROUP)
	z_index = Z_BEHIND_WORLD
	_build()
	_anchor = position
	_play(&"idle")


func _process(delta: float) -> void:
	_elapsed += delta
	var bob: float = roundf(sin(_elapsed * BOB_SPEED) * BOB_HEIGHT)
	position = Vector2(_anchor.x, maxf(_anchor.y, lowest_center()) + bob)
	if _beam_on:
		_beam.points = PackedVector2Array([Vector2.ZERO, to_local(_beam_target)])
		_beam.default_color.a = 0.55 + 0.45 * absf(sin(_elapsed * 18.0))


func place(at: Vector2) -> void:
	_anchor = at
	position = at


func drift_to(target: Vector2, delta: float) -> void:
	_anchor = _anchor.lerp(target, clampf(delta * DRIFT_RATE, 0.0, 1.0))


func set_powered(on: bool) -> void:
	powered = on
	if _light != null:
		_light.energy = LIGHT_ENERGY_POWERED if on else LIGHT_ENERGY_IDLE
	if _hold == &"":
		_play(&"alert" if on else &"idle")


func set_powered_silent(on: bool) -> void:
	set_powered(on)


func aim(target: Vector2) -> void:
	_beam_target = target
	_beam_on = true
	_beam.visible = true
	_hold = &"attack"
	_play(&"attack")


func release() -> void:
	_beam_on = false
	_beam.visible = false
	_hold = &""
	_play(&"alert" if powered else &"idle")


func flinch() -> void:
	_hold = &"hurt"
	_play(&"hurt")


func close_eye() -> void:
	_beam_on = false
	_beam.visible = false
	_hold = &"closed"
	_play(&"closed")
	if _light != null:
		_light.energy = 0.0


func lowest_center() -> float:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return -INF
	var view: Transform2D = viewport.get_canvas_transform()
	var scale_y: float = view.get_scale().y
	if is_zero_approx(scale_y):
		return -INF
	return -view.origin.y / scale_y + SCREEN_MIN_CENTER_Y


func current_animation() -> StringName:
	return _sprite.animation if _sprite != null else &""


func _build() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	_sprite.sprite_frames = _frames()
	add_child(_sprite)
	_beam = Line2D.new()
	_beam.name = "Beam"
	_beam.width = BEAM_WIDTH
	_beam.default_color = BEAM_COLOR
	_beam.visible = false
	_beam.z_index = -1
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_beam.material = unshaded
	_sprite.material = unshaded
	add_child(_beam)
	_light = PointLight2D.new()
	_light.name = "Light"
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_light.color = LIGHT_COLOR
	_light.energy = LIGHT_ENERGY_IDLE
	_light.texture_scale = LightMath.scale_for_radius(LIGHT_RADIUS, LightMath.TEXTURE_SIZE)
	add_child(_light)


func _frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.set_animation_speed(&"idle", IDLE_FPS)
	frames.set_animation_loop(&"idle", true)
	for column: int in range(4):
		var idle: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, 0)
		if idle != null:
			frames.add_frame(&"idle", idle)
	for animation: StringName in SINGLE_FRAMES:
		frames.add_animation(animation)
		frames.set_animation_loop(animation, true)
		var still: AtlasTexture = AssetResolver.atlas(
			SHEET_PATH, FRAME_SIZE, int(SINGLE_FRAMES[animation]), 1
		)
		if still != null:
			frames.add_frame(animation, still)
	return frames


func _play(animation: StringName) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(animation):
		return
	if _sprite.animation == animation and _sprite.is_playing():
		return
	_sprite.play(animation)
