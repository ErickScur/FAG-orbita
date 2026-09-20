class_name Mu7
extends CharacterBody2D

enum State { IDLE, WALK, JUMP, FALL, LAND, ACTION }

const SHEET_PATH: String = "res://assets/sprites/mu7/mu7_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const ANIMATION_ROWS: Array[Dictionary] = [
	{"name": &"idle", "row": 0, "frames": 4, "fps": 4.0, "loop": true},
	{"name": &"walk", "row": 1, "frames": 6, "fps": 10.0, "loop": true},
	{"name": &"jump", "row": 2, "frames": 2, "fps": 8.0, "loop": false},
	{"name": &"fall", "row": 3, "frames": 2, "fps": 8.0, "loop": true},
	{"name": &"land", "row": 4, "frames": 2, "fps": 12.0, "loop": false},
	{"name": &"hurt", "row": 5, "frames": 2, "fps": 10.0, "loop": false},
	{"name": &"interact", "row": 6, "frames": 4, "fps": 8.0, "loop": false},
	{"name": &"climb", "row": 7, "frames": 4, "fps": 8.0, "loop": true},
	{"name": &"death", "row": 8, "frames": 4, "fps": 8.0, "loop": false},
	{"name": &"dash", "row": 9, "frames": 3, "fps": 12.0, "loop": false},
]
const STATE_ANIMATIONS: Dictionary = {
	State.IDLE: &"idle",
	State.WALK: &"walk",
	State.JUMP: &"jump",
	State.FALL: &"fall",
	State.LAND: &"land",
}
const ONE_WAY_BIT: int = 7
const STEP_FRAMES: Array[int] = [1, 4]
const DROP_NUDGE: float = 1.0

@export var floor_sfx: StringName = &"step_metal"

var facing: int = 1

var _state: State = State.IDLE
var _action_animation: StringName = &""
var _locked: bool = false
var _drop_timer: float = 0.0
var _look_ahead: float = 0.0
var _camera_limits: Rect2i = Rect2i()
var _has_camera_limits: bool = false
var _jump_assist: JumpAssist = JumpAssist.new(Balance.COYOTE_TIME, Balance.JUMP_BUFFER)

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D
@onready var _one_way_probe: RayCast2D = $OneWayProbe
@onready var _one_way_clearance: RayCast2D = $OneWayClearance


func _ready() -> void:
	_build_animations()
	_camera.offset = Vector2.ZERO
	_camera.position.y = Balance.CAMERA_OFFSET_Y
	_camera.position_smoothing_speed = Balance.CAMERA_SMOOTHING
	if _has_camera_limits:
		_apply_camera_limits()
	_camera.reset_smoothing()
	_sprite.animation_finished.connect(_on_animation_finished)
	_sprite.frame_changed.connect(_on_frame_changed)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	_play(&"idle")


func _physics_process(delta: float) -> void:
	_update_drop_through(delta)
	var axis: float = 0.0 if _locked else Input.get_axis(&"move_left", &"move_right")
	_apply_horizontal(axis, delta)
	_apply_gravity(delta)
	_handle_jump(delta)
	var was_on_floor: bool = is_on_floor()
	move_and_slide()
	if not was_on_floor and is_on_floor():
		_land()
	_update_facing(axis)
	_update_state(axis)
	_update_look_ahead(axis, delta)


func set_input_locked(locked: bool) -> void:
	_locked = locked
	if not locked:
		return
	velocity.x = 0.0
	_jump_assist.cancel()


func is_input_locked() -> bool:
	return _locked


func set_camera_limits(rect_px: Rect2i) -> void:
	_camera_limits = rect_px
	_has_camera_limits = true
	if _camera == null:
		return
	_apply_camera_limits()
	_camera.reset_smoothing()


func snap_camera() -> void:
	if _camera == null:
		return
	_camera.reset_smoothing()


func play_action(anim: StringName) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(anim):
		return
	_state = State.ACTION
	_action_animation = anim
	_play(anim)


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("MU7: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.sprite_frames = SpriteSheet.build_frames(texture, FRAME_SIZE, ANIMATION_ROWS)


func _apply_camera_limits() -> void:
	_camera.limit_left = _camera_limits.position.x
	_camera.limit_top = _camera_limits.position.y
	_camera.limit_right = _camera_limits.position.x + _camera_limits.size.x
	_camera.limit_bottom = _camera_limits.position.y + _camera_limits.size.y


func _apply_horizontal(axis: float, delta: float) -> void:
	var rate: float = Balance.WALK_ACCEL if not is_zero_approx(axis) else Balance.WALK_DECEL
	if not is_on_floor():
		rate *= Balance.AIR_ACCEL_RATIO
	velocity.x = PlatformerMath.approach(velocity.x, axis * Balance.WALK_SPEED, rate * delta)


func _apply_gravity(delta: float) -> void:
	velocity.y = PlatformerMath.clamp_fall(
		velocity.y + Balance.GRAVITY * delta, Balance.MAX_FALL_SPEED
	)


func _handle_jump(delta: float) -> void:
	_jump_assist.update(delta, is_on_floor())
	if _locked:
		return
	var pressed: bool = Input.is_action_just_pressed(&"jump")
	if pressed and _try_drop_through():
		return
	if pressed:
		_jump_assist.press()
	if _jump_assist.consume():
		velocity.y = PlatformerMath.jump_velocity(Balance.JUMP_HEIGHT, Balance.GRAVITY, delta)
		AudioManager.play_sfx(&"jump")
		_set_state(State.JUMP)
	if Input.is_action_just_released(&"jump"):
		velocity.y = PlatformerMath.apply_jump_cut(velocity.y, Balance.JUMP_CUT_MULTIPLIER)


func _try_drop_through() -> bool:
	if not Input.is_action_pressed(&"move_down") or not is_on_floor():
		return false
	_one_way_probe.force_raycast_update()
	if not _one_way_probe.is_colliding():
		return false
	_drop_timer = Balance.DROP_THROUGH_TIME
	set_collision_mask_value(ONE_WAY_BIT, false)
	position.y += DROP_NUDGE
	velocity.y = maxf(velocity.y, 0.0)
	return true


func _update_drop_through(delta: float) -> void:
	if _drop_timer <= 0.0:
		return
	_drop_timer = maxf(0.0, _drop_timer - delta)
	if _drop_timer > 0.0:
		return
	_one_way_clearance.force_raycast_update()
	if _one_way_clearance.is_colliding():
		_drop_timer = Balance.DROP_THROUGH_TIME
		return
	set_collision_mask_value(ONE_WAY_BIT, true)


func _land() -> void:
	AudioManager.play_sfx(&"land")
	_set_state(State.LAND)


func _update_facing(axis: float) -> void:
	if is_zero_approx(axis):
		return
	facing = 1 if axis > 0.0 else -1
	_sprite.flip_h = facing < 0


func _update_state(axis: float) -> void:
	if _state == State.ACTION:
		return
	if _state == State.LAND and is_on_floor():
		return
	if not is_on_floor():
		_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)
	elif not is_zero_approx(axis):
		_set_state(State.WALK)
	else:
		_set_state(State.IDLE)


func _update_look_ahead(axis: float, delta: float) -> void:
	if not is_zero_approx(axis):
		_look_ahead = float(facing) * Balance.CAMERA_LOOK_AHEAD
	var weight: float = clampf(Balance.CAMERA_LOOK_AHEAD_SPEED * delta, 0.0, 1.0)
	_camera.position.x = lerpf(_camera.position.x, _look_ahead, weight)


func _set_state(next: State) -> void:
	if _state == next:
		return
	_state = next
	_play(StringName(STATE_ANIMATIONS.get(next, &"idle")))


func _play(anim: StringName) -> void:
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(anim):
		return
	if _sprite.animation == anim and _sprite.is_playing():
		return
	_sprite.play(anim)


func _on_animation_finished() -> void:
	if _state != State.LAND and _state != State.ACTION:
		return
	_state = State.IDLE
	_action_animation = &""
	_play(&"idle")


func _on_frame_changed() -> void:
	if _state != State.WALK or not is_on_floor():
		return
	if not STEP_FRAMES.has(_sprite.frame):
		return
	AudioManager.play_sfx(floor_sfx)


func _on_dialogue_started() -> void:
	set_input_locked(true)


func _on_dialogue_finished() -> void:
	set_input_locked(false)
