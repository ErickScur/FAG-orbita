class_name GrowPlant
extends Node2D

const SHEET_PATH: String = "res://assets/sprites/world/grow_plant_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 64)
const FRAME_COUNT: int = 6
const ANIMATION_ID: StringName = &"grow"
const POWERED_GROUP: StringName = &"powered"
const FLAG_PREFIX: String = "plant_"
const LIGHT_COLOR: Color = Color("e58fb5")
const LIGHT_RADIUS: float = 56.0
const LIGHT_ENERGY: float = 0.9

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var plant_id: StringName = &"plant"
@export var powered: bool = false

var _progress: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _top_shape: CollisionShape2D = $Top/CollisionShape2D
@onready var _light: PointLight2D = $GrowLight


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	_build_frames()
	_setup_light()
	if bool(GameState.flags.get(flag_id(), false)):
		_progress = Growth.COMPLETE
	set_powered_silent(powered)
	EventBus.energy_changed.connect(_on_energy_changed)


func _physics_process(delta: float) -> void:
	if Growth.is_grown(_progress):
		return
	var next: float = Growth.step(_progress, powered, delta, Balance.PLANT_GROW_TIME)
	if next <= _progress:
		return
	_progress = next
	_apply_visual()
	if not Growth.is_grown(_progress):
		return
	GameState.flags[flag_id()] = true
	AudioManager.play_sfx(&"plant_grow")


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("id"):
		plant_id = StringName(String(params["id"]))
	if params.has("plant_id"):
		plant_id = StringName(String(params["plant_id"]))
	if params.has("powered"):
		powered = bool(params["powered"])
	if bool(GameState.flags.get(flag_id(), false)):
		_progress = Growth.COMPLETE
	if _sprite == null:
		return
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	_apply_visual()


func set_powered_silent(on: bool) -> void:
	powered = on
	_apply_visual()


func flag_id() -> String:
	return FLAG_PREFIX + String(plant_id)


func is_grown() -> bool:
	return Growth.is_grown(_progress)


func progress() -> float:
	return _progress


func _apply_visual() -> void:
	if _sprite == null:
		return
	_sprite.frame = Growth.frame_for(_progress, FRAME_COUNT)
	_top_shape.set_deferred(&"disabled", not Growth.is_grown(_progress))
	_light.energy = LIGHT_ENERGY if powered else 0.0


func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(ANIMATION_ID)
	frames.set_animation_loop(ANIMATION_ID, false)
	var added: int = 0
	for column: int in range(FRAME_COUNT):
		var texture: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, 0)
		if texture == null:
			break
		frames.add_frame(ANIMATION_ID, texture)
		added += 1
	if added == 0:
		push_warning("GrowPlant: sprite sheet ausente em %s" % SHEET_PATH)
		return
	frames.remove_animation(&"default")
	_sprite.sprite_frames = frames
	_sprite.animation = ANIMATION_ID
	_sprite.stop()


func _setup_light() -> void:
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _light.texture == null:
		push_warning("GrowPlant: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_light.color = LIGHT_COLOR
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.texture_scale = LightMath.scale_for_radius(LIGHT_RADIUS, LightMath.TEXTURE_SIZE)


func _on_energy_changed(
	changed_terminal: StringName, changed_system: StringName, on: bool
) -> void:
	if changed_terminal != terminal_id or changed_system != system_id:
		return
	set_powered(on)
