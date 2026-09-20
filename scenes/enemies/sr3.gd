class_name Sr3
extends CharacterBody2D

signal shut_down(duration: float)
signal woke_up()

const SHEET_PATH: String = "res://assets/sprites/enemies/sr3_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 16)
const SHUTDOWN_FPS: float = 8.0
const ANIMATION_ROWS: Array[Dictionary] = [
	{"name": &"walk", "row": 0, "frames": 4, "fps": 6.0, "loop": true},
	{"name": &"shutdown", "row": 1, "frames": 3, "fps": SHUTDOWN_FPS, "loop": false},
	{"name": &"off", "row": 2, "frames": 1, "fps": 1.0, "loop": true},
]
const FOLDING_TIME: float = 3.0 / SHUTDOWN_FPS
const WARNING_COLOR: Color = Color("ffb347")
const WARNING_RADIUS: float = 40.0
const WARNING_ENERGY: float = 0.8
const PROBE_DISTANCE: float = 10.0
const BEAM_TARGET_GROUP: StringName = &"beam_target"

@export var dir: int = 1

var _shutdown_left: float = 0.0
var _shutdown_total: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hitbox: DamageArea = $Hitbox
@onready var _floor_probe: RayCast2D = $FloorProbe
@onready var _wall_probe: RayCast2D = $WallProbe
@onready var _warning_light: PointLight2D = $WarningLight


func _ready() -> void:
	_hitbox.knockback_x = Balance.SR3_KNOCKBACK_X
	_hitbox.knockback_y = Balance.SR3_KNOCKBACK_Y
	add_to_group(BEAM_TARGET_GROUP)
	add_to_group(&"enemy")
	_build_animations()
	_setup_light()
	_hitbox.contact_damage = Balance.SR3_CONTACT_DAMAGE
	_hitbox.knockback = true
	dir = Sr3Logic.normalize_direction(dir)
	_apply_direction()
	_play(Sr3Logic.ANIM_WALK)


func _physics_process(delta: float) -> void:
	velocity.y += Balance.GRAVITY * delta
	_tick_shutdown(delta)
	if is_shut_down():
		velocity.x = 0.0
		move_and_slide()
		return
	if is_on_floor() and Sr3Logic.should_turn(_floor_ahead(), _wall_ahead()):
		_turn()
	velocity.x = Sr3Logic.walk_velocity(dir, Balance.SR3_SPEED, false)
	move_and_slide()


func configure(params: Dictionary) -> void:
	if params.has("dir"):
		dir = Sr3Logic.normalize_direction(int(params["dir"]))
	if _sprite == null:
		return
	_apply_direction()


func shutdown(duration: float) -> void:
	if duration <= 0.0:
		return
	var was_awake: bool = not is_shut_down()
	_shutdown_left = maxf(_shutdown_left, duration)
	_shutdown_total = maxf(_shutdown_total, duration)
	if not was_awake:
		return
	velocity.x = 0.0
	_hitbox.set_active(false)
	_hitbox.set_deferred(&"monitorable", false)
	_warning_light.enabled = false
	_play(Sr3Logic.ANIM_SHUTDOWN)
	AudioManager.play_sfx(&"sr3_shutdown")
	shut_down.emit(duration)


func is_shut_down() -> bool:
	return _shutdown_left > 0.0


func shutdown_remaining() -> float:
	return _shutdown_left


func _tick_shutdown(delta: float) -> void:
	if _shutdown_left <= 0.0:
		return
	var before: float = _shutdown_left
	_shutdown_left = Sr3Logic.tick_shutdown(before, delta)
	_play(Sr3Logic.animation_for(_shutdown_left, _shutdown_total, FOLDING_TIME))
	if not Sr3Logic.woke_up(before, _shutdown_left):
		return
	_shutdown_total = 0.0
	_hitbox.set_active(true)
	_hitbox.set_deferred(&"monitorable", true)
	_warning_light.enabled = true
	woke_up.emit()


func _floor_ahead() -> bool:
	_floor_probe.force_raycast_update()
	return _floor_probe.is_colliding()


func _wall_ahead() -> bool:
	_wall_probe.force_raycast_update()
	return _wall_probe.is_colliding()


func _turn() -> void:
	dir = Sr3Logic.flip(dir)
	_apply_direction()


func _apply_direction() -> void:
	_sprite.flip_h = dir < 0
	_floor_probe.position.x = Sr3Logic.probe_offset(dir, PROBE_DISTANCE)
	_wall_probe.target_position.x = Sr3Logic.probe_offset(dir, PROBE_DISTANCE + 4.0)


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("SR3: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.sprite_frames = SpriteSheet.build_frames(texture, FRAME_SIZE, ANIMATION_ROWS)


func _setup_light() -> void:
	_warning_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _warning_light.texture == null:
		push_warning("SR3: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_warning_light.color = WARNING_COLOR
	_warning_light.energy = WARNING_ENERGY
	_warning_light.blend_mode = Light2D.BLEND_MODE_ADD
	_warning_light.texture_scale = LightMath.scale_for_radius(
		WARNING_RADIUS, LightMath.TEXTURE_SIZE
	)


func _play(anim: StringName) -> void:
	var frames: SpriteFrames = _sprite.sprite_frames
	if frames == null or not frames.has_animation(anim):
		return
	var restart: bool = Sr3Logic.should_restart_animation(
		_sprite.animation, anim, _sprite.is_playing(), frames.get_animation_loop(anim)
	)
	if not restart:
		return
	_sprite.play(anim)
