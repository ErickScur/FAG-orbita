class_name AmbientMotes
extends Node2D

const TEXTURE_PATH: String = "res://assets/sprites/fx/spore.png"
const FRAME_SIZE: Vector2i = Vector2i(8, 8)
const FRAME_COLUMN: int = 3
const DEFAULT_TINT: Color = Color(0.658824, 0.843137, 0.541176, 0.42)

@export var tint: Color = DEFAULT_TINT

@onready var _particles: CPUParticles2D = $Particles


func _ready() -> void:
	_particles.texture = AssetResolver.atlas(TEXTURE_PATH, FRAME_SIZE, FRAME_COLUMN, 0)
	if _particles.texture == null:
		push_warning("AmbientMotes: partícula ausente em %s" % TEXTURE_PATH)
	_particles.emission_rect_extents = _screen_extents()
	_particles.amount = Balance.AMBIENT_MOTE_AMOUNT
	_particles.lifetime = Balance.AMBIENT_MOTE_LIFETIME
	_particles.initial_velocity_max = Balance.AMBIENT_MOTE_SPEED
	_particles.gravity = Vector2(0.0, Balance.AMBIENT_MOTE_RISE)
	_particles.color = Color(tint.r, tint.g, tint.b, DEFAULT_TINT.a)
	_particles.emitting = true
	_follow_camera()


func _process(_delta: float) -> void:
	_follow_camera()


func configure(value: Color) -> void:
	tint = value
	if _particles != null:
		_particles.color = Color(value.r, value.g, value.b, DEFAULT_TINT.a)


func _follow_camera() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var camera: Camera2D = viewport.get_camera_2d()
	if camera == null:
		return
	global_position = camera.get_screen_center_position()


func _screen_extents() -> Vector2:
	var width: float = float(
		ProjectSettings.get_setting("display/window/size/viewport_width", 384)
	)
	var height: float = float(
		ProjectSettings.get_setting("display/window/size/viewport_height", 216)
	)
	return Vector2(width, height) * 0.6
