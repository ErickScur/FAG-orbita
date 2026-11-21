class_name Mu7
extends CharacterBody2D

enum State { IDLE, WALK, JUMP, FALL, LAND, CLIMB, ACTION, DASH }

const SHEET_PATH: String = "res://assets/sprites/mu7/mu7_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FLASH_SHADER: String = "res://scenes/fx/hit_flash.gdshader"
const FLASH_AMOUNT: StringName = &"flash_amount"
const FLASH_COLOR: StringName = &"flash_color"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const ANIMATION_ROWS: Array[Dictionary] = [
	{"name": &"idle", "row": 0, "frames": 4, "fps": Balance.MU7_FPS_IDLE, "loop": true},
	{"name": &"walk", "row": 1, "frames": 6, "fps": Balance.MU7_FPS_WALK, "loop": true},
	{"name": &"jump", "row": 2, "frames": 2, "fps": Balance.MU7_FPS_JUMP, "loop": false},
	{"name": &"fall", "row": 3, "frames": 2, "fps": Balance.MU7_FPS_FALL, "loop": true},
	{"name": &"land", "row": 4, "frames": 2, "fps": Balance.MU7_FPS_LAND, "loop": false},
	{"name": &"hurt", "row": 5, "frames": 2, "fps": Balance.MU7_FPS_HURT, "loop": false},
	{"name": &"interact", "row": 6, "frames": 4, "fps": Balance.MU7_FPS_INTERACT, "loop": false},
	{"name": &"climb", "row": 7, "frames": 4, "fps": Balance.MU7_FPS_CLIMB, "loop": true},
	{"name": &"death", "row": 8, "frames": 4, "fps": Balance.MU7_FPS_DEATH, "loop": false},
	{"name": &"dash", "row": 9, "frames": 3, "fps": Balance.MU7_FPS_DASH, "loop": false},
]
const STATE_ANIMATIONS: Dictionary = {
	State.IDLE: &"idle",
	State.WALK: &"walk",
	State.JUMP: &"jump",
	State.FALL: &"fall",
	State.LAND: &"land",
	State.CLIMB: &"climb",
	State.DASH: &"dash",
}
const ONE_WAY_BIT: int = 7
const CLAW_PROBE_REACH: float = 10.0
const STEP_FRAMES: Array[int] = [1, 4]
const DROP_NUDGE: float = 1.0
const BLINK_INTERVAL: float = 0.1
const BEAM_FLASH_TIME: float = 0.1
const BEAM_COLOR: Color = Color("5fe8ff")
const BEAM_LIGHT_ENERGY: float = 1.2
const BEAM_LIGHT_RADIUS: float = 24.0
const BEAM_BLINK_PERIOD: float = 0.02
const BEAM_DIM_RATIO: float = 0.5
const TRAIL_COLOR: Color = Color(0.37, 0.91, 1.0, 0.7)
const REFUSE_SFX: StringName = &"ui_error"
const JET_SHEET: String = "res://assets/sprites/fx/thruster_jet.png"
const JET_FRAMES: int = 4
const JET_FPS: float = 16.0
const JET_ORIGIN: Vector2 = Vector2(0, -12)
const JET_DISTANCE: float = 10.0
const JET_BURST_TIME: float = 0.25
const JET_PARTICLE_COLOR: Color = Color(0.37, 0.91, 1.0, 0.8)
const JET_PARTICLE_SPEED: float = 60.0

@export var floor_sfx: StringName = &"step_metal"

var facing: int = 1

var _state: State = State.IDLE
var _action_animation: StringName = &""
var _locked: bool = false
var _dead: bool = false
var _drop_timer: float = 0.0
var _hurt_timer: float = 0.0
var _invincible_left: float = 0.0
var _invincible_hold: bool = false
var _blink_timer: float = 0.0
var _damage_accumulator: float = 0.0
var _heat_accumulator: float = 0.0
var _look_ahead: float = 0.0
var _camera_limits: Rect2i = Rect2i()
var _has_camera_limits: bool = false
var _climbing: bool = false
var _claw_blocked: bool = false
var _wall_push: float = 0.0
var _flashlight_on: bool = false
var _light_tween: Tween = null
var _joypad: bool = false
var _interaction_target: Interactable = null
var _interaction_prompt: String = ""
var _jump_assist: JumpAssist = JumpAssist.new(Balance.COYOTE_TIME, Balance.JUMP_BUFFER)
var _shake_left: float = 0.0
var _shake_amplitude: float = 0.0
var _shake_elapsed: float = 0.0
var _flash_left: float = 0.0
var _flash_material: ShaderMaterial = null
var _dashing: bool = false
var _dash_left: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_velocity: Vector2 = Vector2.ZERO
var _air_dash_used: bool = false
var _beam_flash_left: float = 0.0
var _in_vacuum: bool = false
var _vacuum_anchor: Vector2 = Vector2.ZERO
var _double_jump_used: bool = false
var _thrusting: bool = false
var _jet_direction: Vector2 = Vector2.UP
var _jet_left: float = 0.0
var _jet_clock: float = 0.0
var _jet_sprite: Sprite2D = null
var _jet_particles: CPUParticles2D = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _camera: Camera2D = $Camera2D
@onready var _one_way_probe: RayCast2D = $OneWayProbe
@onready var _one_way_clearance: RayCast2D = $OneWayClearance
@onready var _claw_top: RayCast2D = $ClawProbeTop
@onready var _claw_bottom: RayCast2D = $ClawProbeBottom
@onready var _hurtbox: Area2D = $Hurtbox
@onready var _sensor: Area2D = $InteractionSensor
@onready var _sensor_shape: CollisionShape2D = $InteractionSensor/CollisionShape2D
@onready var _flashlight: PointLight2D = $Flashlight
@onready var _beam_ray: RayCast2D = $BeamRay
@onready var _beam_line: Line2D = $BeamLine
@onready var _beam_light: PointLight2D = $BeamLight
@onready var _dash_trail: CPUParticles2D = $DashTrail


func _ready() -> void:
	_build_animations()
	_setup_flash()
	_setup_sensor()
	_setup_flashlight()
	_setup_beam()
	_setup_dash_trail()
	_setup_jet()
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
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.sector_restored.connect(_on_sector_restored)
	_play(&"idle")


func _input(event: InputEvent) -> void:
	var joypad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
	if not joypad and not (event is InputEventKey):
		return
	if joypad == _joypad:
		return
	_joypad = joypad
	_interaction_prompt = ""


func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_drop_through(delta)
	_in_vacuum = _overlaps_vacuum()
	_thrusting = false
	_try_dash()
	if _dashing:
		_dash_step(delta)
	elif _climbing:
		_climb_step(delta)
	elif _in_vacuum:
		_vacuum_step(delta)
	else:
		_vacuum_anchor = Vector2.ZERO
		_walk_step(delta)
	_try_beam()
	_process_hurtbox(delta)
	_update_flashlight(delta)
	_update_interaction()
	_update_shake(delta)
	_update_flash(delta)
	_update_beam_flash(delta)
	_update_jet(delta)


func _walk_step(delta: float) -> void:
	if not _movement_blocked() and Input.is_action_just_pressed(&"move_down"):
		_try_drop_through()
	var axis: float = 0.0 if _movement_blocked() else Input.get_axis(&"move_left", &"move_right")
	if _hurt_timer <= 0.0:
		_apply_horizontal(axis, delta)
	_apply_wall_push(axis)
	_apply_gravity(delta)
	_handle_jump(delta)
	var was_on_floor: bool = is_on_floor()
	var fall_speed: float = velocity.y
	move_and_slide()
	if not was_on_floor and is_on_floor():
		_land(fall_speed)
	if is_on_floor():
		_air_dash_used = false
		_double_jump_used = false
	_update_facing(axis)
	if _try_grab(axis):
		return
	_update_state(axis)
	_update_look_ahead(axis, delta)


func _climb_step(delta: float) -> void:
	_aim_claw_probes()
	if _movement_blocked() or ClimbLogic.should_release(_touching_magnetic(), _has_claws()):
		_release_climb()
		return
	if Input.is_action_just_pressed(&"jump"):
		_jump_off_wall()
		return
	velocity = ClimbLogic.climb_velocity(
		Input.get_axis(&"move_up", &"move_down"), Balance.CLAW_CLIMB_SPEED
	)
	move_and_slide()
	_update_look_ahead(0.0, delta)


func _try_grab(axis: float) -> bool:
	if _movement_blocked():
		return false
	_aim_claw_probes()
	var touching: bool = _touching_magnetic()
	if _claw_blocked:
		if not touching or is_on_floor():
			_claw_blocked = false
		return false
	var up: bool = Input.is_action_pressed(&"move_up")
	if not ClimbLogic.can_grab(_has_claws(), touching, axis, facing, up):
		return false
	_climbing = true
	_air_dash_used = false
	_double_jump_used = false
	_wall_push = 0.0
	velocity = Vector2.ZERO
	_jump_assist.cancel()
	_set_state(State.CLIMB)
	AudioManager.play_sfx(&"claw_grab")
	return true


func _jump_off_wall() -> void:
	var jump_speed: float = absf(_jump_speed())
	velocity = ClimbLogic.jump_off_velocity(facing, Balance.CLAW_JUMP_PUSH, jump_speed)
	_wall_push = velocity.x
	_climbing = false
	_claw_blocked = true
	_jump_assist.cancel()
	_set_state(State.JUMP)
	AudioManager.play_sfx(&"jump")
	move_and_slide()


func _release_climb() -> void:
	_climbing = false
	_claw_blocked = true
	_jump_assist.cancel()
	_set_state(State.FALL)


func _apply_wall_push(axis: float) -> void:
	if is_zero_approx(_wall_push):
		return
	if is_on_floor() or not is_zero_approx(axis):
		_wall_push = 0.0
		return
	if absf(velocity.x) < absf(_wall_push):
		velocity.x = _wall_push


func _aim_claw_probes() -> void:
	if _claw_top == null or _claw_bottom == null:
		return
	var reach: float = float(facing) * CLAW_PROBE_REACH
	_claw_top.target_position.x = reach
	_claw_bottom.target_position.x = reach
	_claw_top.force_raycast_update()
	_claw_bottom.force_raycast_update()


func _touching_magnetic() -> bool:
	return _probe_hits_magnetic(_claw_top) or _probe_hits_magnetic(_claw_bottom)


func _probe_hits_magnetic(probe: RayCast2D) -> bool:
	if probe == null or not probe.is_colliding():
		return false
	var collider: Object = probe.get_collider()
	if not (collider is Node):
		return false
	return (collider as Node).is_in_group(ClimbLogic.MAGNETIC_GROUP)


func _has_claws() -> bool:
	if GameState.statuses.blocks_abilities():
		return false
	return ClimbLogic.has_ability(GameState.abilities)


func _has_heat_sink() -> bool:
	return HeatRules.has_heat_sink(GameState.abilities)


func _has_heated_core() -> bool:
	return FreezeRules.has_heated_core(GameState.abilities)


func _has_thruster() -> bool:
	return VacuumRules.has_thruster(GameState.abilities)


func _jump_speed(step: float = 0.0) -> float:
	var height: float = FreezeRules.jump_height(GameState.statuses.jump_multiplier())
	return PlatformerMath.jump_velocity(height, Balance.GRAVITY, step)


func is_climbing() -> bool:
	return _climbing


func is_dashing() -> bool:
	return _dashing


func dash_cooldown_left() -> float:
	return _dash_cooldown


func is_air_dash_used() -> bool:
	return _air_dash_used


func is_in_vacuum() -> bool:
	return _in_vacuum


func is_anchored() -> bool:
	return not _vacuum_anchor.is_zero_approx()


func is_double_jump_used() -> bool:
	return _double_jump_used


func is_thrusting() -> bool:
	return _thrusting


func is_beam_visible() -> bool:
	return _beam_line != null and _beam_line.visible


func set_input_locked(locked: bool) -> void:
	_locked = locked
	if not locked:
		return
	_cancel_dash()
	velocity.x = 0.0
	_jump_assist.cancel()


func is_input_locked() -> bool:
	return _locked


func take_hit(
	damage: int,
	source: Vector2,
	push_x: float = Balance.KNOCKBACK_SPEED,
	push_y: float = Balance.KNOCKBACK_SPEED
) -> bool:
	if _dead or is_invincible() or damage <= 0:
		return false
	GameState.apply_damage(damage)
	_start_hurt(source, true, push_x, push_y)
	return true


func take_latch_hit(damage: int, source: Vector2) -> bool:
	if _dead or is_invincible() or damage <= 0:
		return false
	GameState.apply_damage(damage)
	_start_hurt(source, false)
	return true


func is_dead() -> bool:
	return _dead


func is_invincible() -> bool:
	return _invincible_left > 0.0 or _invincible_hold


func set_invincible(active: bool) -> void:
	_invincible_hold = active


func is_flashlight_on() -> bool:
	return _flashlight_on


func interaction_target() -> Interactable:
	return _interaction_target


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


func shake(amplitude: float) -> void:
	_shake_amplitude = ScreenShake.amplitude_for(
		_shake_amplitude * ScreenShake.falloff(_shake_left, Balance.SHAKE_TIME), amplitude
	)
	_shake_left = Balance.SHAKE_TIME


func shake_offset() -> Vector2:
	if _camera == null:
		return Vector2.ZERO
	return _camera.offset


func flash_amount() -> float:
	if _flash_material == null:
		return 0.0
	return float(_flash_material.get_shader_parameter(FLASH_AMOUNT))


func _setup_flash() -> void:
	if not ResourceLoader.exists(FLASH_SHADER):
		push_warning("MU7: shader de flash ausente em %s" % FLASH_SHADER)
		return
	var shader: Shader = load(FLASH_SHADER)
	if shader == null:
		return
	_flash_material = ShaderMaterial.new()
	_flash_material.shader = shader
	_flash_material.set_shader_parameter(FLASH_COLOR, Balance.HIT_FLASH_COLOR)
	_flash_material.set_shader_parameter(FLASH_AMOUNT, 0.0)
	_sprite.material = _flash_material


func _update_shake(delta: float) -> void:
	if _camera == null:
		return
	if _shake_left <= 0.0:
		if not _camera.offset.is_zero_approx():
			_camera.offset = Vector2.ZERO
		return
	_shake_elapsed += delta
	_shake_left = ScreenShake.remaining_after(_shake_left, delta)
	_camera.offset = ScreenShake.offset(
		_shake_amplitude,
		_shake_left,
		Balance.SHAKE_TIME,
		_shake_elapsed,
		Balance.SHAKE_FREQUENCY
	)
	if _shake_left <= 0.0:
		_shake_amplitude = 0.0


func _update_flash(delta: float) -> void:
	if _flash_material == null or _flash_left <= 0.0:
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	var amount: float = 0.0
	if Balance.HIT_FLASH_TIME > 0.0:
		amount = clampf(_flash_left / Balance.HIT_FLASH_TIME, 0.0, 1.0)
	_flash_material.set_shader_parameter(FLASH_AMOUNT, amount)
	if _flash_left > 0.0:
		_sprite.visible = true


func _on_player_damaged(_amount: int) -> void:
	shake(Balance.SHAKE_DAMAGE)
	if _flash_material == null:
		return
	_flash_left = Balance.HIT_FLASH_TIME
	_flash_material.set_shader_parameter(FLASH_AMOUNT, 1.0)
	_sprite.visible = true


func _on_sector_restored(_sector_id: StringName) -> void:
	shake(Balance.SHAKE_SECTOR)


func _setup_beam() -> void:
	_beam_ray.enabled = false
	_beam_ray.collide_with_bodies = true
	_beam_ray.collide_with_areas = false
	_beam_ray.hit_from_inside = true
	_beam_line.visible = false
	_beam_line.default_color = BEAM_COLOR
	_beam_line.material = _unshaded_material()
	_beam_light.enabled = false
	_beam_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_beam_light.color = BEAM_COLOR
	_beam_light.energy = BEAM_LIGHT_ENERGY
	_beam_light.blend_mode = Light2D.BLEND_MODE_ADD
	_beam_light.texture_scale = LightMath.scale_for_radius(
		BEAM_LIGHT_RADIUS, LightMath.TEXTURE_SIZE
	)


func _setup_dash_trail() -> void:
	_dash_trail.emitting = false
	_dash_trail.local_coords = false
	_dash_trail.color = TRAIL_COLOR
	_dash_trail.material = _unshaded_material()


func _unshaded_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return material


func _try_dash() -> void:
	if _dashing or not Input.is_action_just_pressed(&"dash"):
		return
	if _movement_blocked() or not DashLogic.has_ability(GameState.abilities):
		return
	var on_floor: bool = is_on_floor() and not _climbing
	if not DashLogic.can_dash_now(on_floor, _air_dash_used) or _dash_cooldown > 0.0:
		return
	var blocked: bool = GameState.statuses.blocks_abilities()
	if not DashLogic.can_use(GameState.charge, Balance.DASH_COST, _dash_cooldown, blocked):
		AudioManager.play_sfx(REFUSE_SFX)
		return
	if not GameState.spend_charge(Balance.DASH_COST):
		AudioManager.play_sfx(REFUSE_SFX)
		return
	_start_dash(on_floor)


func _start_dash(on_floor: bool) -> void:
	if _climbing:
		_climbing = false
		_claw_blocked = true
		_set_facing(-facing)
	else:
		var axis: float = Input.get_axis(&"move_left", &"move_right")
		if not is_zero_approx(axis):
			_set_facing(1 if axis > 0.0 else -1)
	if not on_floor:
		_air_dash_used = true
	_dashing = true
	_dash_left = Balance.DASH_TIME
	_dash_velocity = DashLogic.dash_velocity(facing, Balance.DASH_SPEED)
	velocity = _dash_velocity
	_wall_push = 0.0
	_jump_assist.cancel()
	_set_state(State.DASH)
	_dash_trail.emitting = true
	AudioManager.play_sfx(&"dash")


func _dash_step(delta: float) -> void:
	_dash_left = DashLogic.tick(_dash_left, delta)
	velocity = _dash_velocity
	move_and_slide()
	_update_look_ahead(float(facing), delta)
	if _dash_left <= 0.0:
		_finish_dash()


func _finish_dash() -> void:
	_dashing = false
	_dash_left = 0.0
	_dash_cooldown = Balance.DASH_COOLDOWN
	velocity.x = DashLogic.exit_speed(velocity.x, Balance.WALK_SPEED)
	velocity.y = 0.0
	_dash_trail.emitting = false
	_set_state(State.IDLE if is_on_floor() else State.FALL)


func _cancel_dash() -> void:
	if not _dashing:
		return
	_dashing = false
	_dash_left = 0.0
	_dash_cooldown = Balance.DASH_COOLDOWN
	_dash_trail.emitting = false
	if _state == State.DASH:
		_state = State.IDLE


func _set_facing(next: int) -> void:
	facing = -1 if next < 0 else 1
	_sprite.flip_h = facing < 0


func _try_beam() -> void:
	if not Input.is_action_just_pressed(&"beam"):
		return
	if _movement_blocked() or not BeamLogic.has_ability(GameState.abilities):
		return
	var blocked: bool = GameState.statuses.blocks_abilities()
	if not BeamLogic.can_fire(GameState.charge, Balance.BEAM_COST, blocked):
		AudioManager.play_sfx(REFUSE_SFX)
		return
	if not GameState.spend_charge(Balance.BEAM_COST):
		AudioManager.play_sfx(REFUSE_SFX)
		return
	_fire_beam()


func _fire_beam() -> void:
	_beam_ray.target_position = BeamLogic.ray_vector(facing, Balance.BEAM_RANGE)
	_beam_ray.force_raycast_update()
	var hit_point: Variant = null
	var target: Node = null
	if _beam_ray.is_colliding():
		hit_point = _beam_ray.get_collision_point()
		target = BeamLogic.resolve_target(_beam_ray.get_collider())
	if target != null:
		target.call(BeamLogic.SHUTDOWN_METHOD, Balance.BEAM_SHUTDOWN_TIME)
	var length: float = BeamLogic.beam_length(
		_beam_ray.global_position, hit_point, Balance.BEAM_RANGE
	)
	var tip := Vector2(float(facing) * length, 0.0)
	_beam_line.points = PackedVector2Array([Vector2.ZERO, tip])
	_beam_line.visible = true
	_beam_light.position = _beam_line.position + tip * 0.5
	_beam_light.enabled = true
	_beam_flash_left = BEAM_FLASH_TIME
	AudioManager.play_sfx(&"beam")
	if is_on_floor() and not _dashing and not _climbing:
		play_action(&"interact")


func _update_beam_flash(delta: float) -> void:
	if _beam_flash_left <= 0.0:
		return
	_beam_flash_left = maxf(0.0, _beam_flash_left - delta)
	var bright: bool = fmod(_beam_flash_left, BEAM_BLINK_PERIOD * 2.0) > BEAM_BLINK_PERIOD
	_beam_light.energy = BEAM_LIGHT_ENERGY * (1.0 if bright else BEAM_DIM_RATIO)
	if _beam_flash_left > 0.0:
		return
	_beam_line.visible = false
	_beam_light.enabled = false
	_beam_light.energy = BEAM_LIGHT_ENERGY


func _setup_sensor() -> void:
	var shape: Shape2D = _sensor_shape.shape
	if shape is CircleShape2D:
		(shape as CircleShape2D).radius = Balance.INTERACT_RANGE


func _setup_flashlight() -> void:
	_flashlight.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _flashlight.texture == null:
		push_warning("MU7: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_flashlight.color = Balance.FLASHLIGHT_COLOR
	_flashlight.energy = Balance.SENSOR_ENERGY
	_flashlight.blend_mode = Light2D.BLEND_MODE_ADD
	_flashlight.shadow_enabled = true
	_flashlight.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	_flashlight.shadow_filter_smooth = Balance.SHADOW_FILTER_SMOOTH
	_flashlight.texture_scale = LightMath.scale_for_radius(
		Balance.VISION_RADIUS_OFF, LightMath.TEXTURE_SIZE
	)


func _apply_camera_limits() -> void:
	_camera.limit_left = _camera_limits.position.x
	_camera.limit_top = _camera_limits.position.y
	_camera.limit_right = _camera_limits.position.x + _camera_limits.size.x
	_camera.limit_bottom = _camera_limits.position.y + _camera_limits.size.y


func _apply_horizontal(axis: float, delta: float) -> void:
	var statuses: StatusEffects = GameState.statuses
	var rate: float = FreezeRules.horizontal_rate(
		axis, velocity.x, is_on_floor(), statuses.is_slippery()
	)
	var top: float = FreezeRules.walk_speed(statuses.speed_multiplier())
	velocity.x = PlatformerMath.approach(velocity.x, axis * top, rate * delta)


func _apply_gravity(delta: float) -> void:
	velocity.y = PlatformerMath.clamp_fall(
		velocity.y + Balance.GRAVITY * delta, Balance.MAX_FALL_SPEED
	)


func _handle_jump(delta: float) -> void:
	_jump_assist.update(delta, is_on_floor())
	if _movement_blocked():
		return
	var pressed: bool = Input.is_action_just_pressed(&"jump")
	if pressed and _try_drop_through():
		return
	if pressed and _try_double_jump(delta):
		return
	if pressed:
		_jump_assist.press()
	if _jump_assist.consume():
		velocity.y = _jump_speed(delta)
		AudioManager.play_sfx(&"jump")
		_set_state(State.JUMP)
	if Input.is_action_just_released(&"jump"):
		velocity.y = PlatformerMath.apply_jump_cut(velocity.y, Balance.JUMP_CUT_MULTIPLIER)


func _try_double_jump(delta: float) -> bool:
	var blocked: bool = GameState.statuses.blocks_abilities()
	var allowed: bool = VacuumRules.can_double_jump(
		_has_thruster(),
		_double_jump_used,
		is_on_floor(),
		_jump_assist.coyote_left(),
		_climbing,
		blocked,
		GameState.charge,
		Balance.DOUBLE_JUMP_COST
	)
	if not allowed or not GameState.spend_charge(Balance.DOUBLE_JUMP_COST):
		return false
	_double_jump_used = true
	_jump_assist.cancel()
	velocity.y = _jump_speed(delta)
	_jet_direction = Vector2.UP
	_jet_left = JET_BURST_TIME
	AudioManager.play_sfx(&"dash")
	_set_state(State.JUMP)
	return true


func _vacuum_step(delta: float) -> void:
	var input: Vector2 = _vacuum_input()
	var pressed: bool = not _movement_blocked() and Input.is_action_just_pressed(&"jump")
	_jump_assist.cancel()
	_wall_push = 0.0
	if is_on_floor():
		_vacuum_anchor = Vector2.ZERO
		_air_dash_used = false
		_double_jump_used = false
		if _hurt_timer <= 0.0:
			_apply_horizontal(input.x, delta)
		velocity.y = Balance.VACUUM_FLOOR_STICK
		if pressed:
			_vacuum_push(input, Vector2.UP)
	elif is_anchored():
		_air_dash_used = false
		velocity = Vector2.ZERO
		if pressed:
			_vacuum_push(input, _vacuum_anchor)
		elif input.dot(_vacuum_anchor) > 0.0:
			_vacuum_thrust(input, delta)
			if _thrusting:
				_vacuum_anchor = Vector2.ZERO
	else:
		_vacuum_thrust(input, delta)
	velocity = VacuumRules.clamp_drift(velocity, Balance.VACUUM_MAX_SPEED)
	var drift: Vector2 = velocity
	move_and_slide()
	_vacuum_settle(drift)
	_update_facing(input.x)
	_update_state(input.x)
	_update_look_ahead(input.x, delta)


func _vacuum_input() -> Vector2:
	if _movement_blocked():
		return Vector2.ZERO
	return Vector2(
		Input.get_axis(&"move_left", &"move_right"), Input.get_axis(&"move_up", &"move_down")
	)


func _vacuum_push(input: Vector2, normal: Vector2) -> void:
	velocity = VacuumRules.push_velocity(input, normal, Balance.VACUUM_PUSH_SPEED)
	_vacuum_anchor = Vector2.ZERO
	AudioManager.play_sfx(&"jump")
	_set_state(State.JUMP)


func _vacuum_thrust(input: Vector2, delta: float) -> void:
	var blocked: bool = GameState.statuses.blocks_abilities()
	if not VacuumRules.can_thrust(_has_thruster(), blocked, GameState.charge, input):
		return
	if not GameState.spend_charge(VacuumRules.thrust_cost(delta, Balance.THRUSTER_DRAIN)):
		return
	velocity = VacuumRules.thrust(
		velocity, input, delta, Balance.THRUSTER_ACCEL, Balance.THRUSTER_SPEED
	)
	_thrusting = true
	_jet_direction = input.normalized()


func _vacuum_settle(drift: Vector2) -> void:
	if is_on_floor():
		_vacuum_anchor = Vector2.ZERO
		return
	var collision: KinematicCollision2D = get_last_slide_collision()
	if collision == null or not VacuumRules.hits_surface(drift, collision.get_normal()):
		return
	_vacuum_anchor = collision.get_normal()
	velocity = Vector2.ZERO


func _overlaps_vacuum() -> bool:
	if _hurtbox == null:
		return false
	for area: Area2D in _hurtbox.get_overlapping_areas():
		if area is VacuumZone and (area as VacuumZone).is_active():
			return true
	return false


func _setup_jet() -> void:
	_jet_sprite = Sprite2D.new()
	_jet_sprite.name = "ThrusterJet"
	_jet_sprite.texture = AssetResolver.texture(JET_SHEET)
	_jet_sprite.hframes = JET_FRAMES
	_jet_sprite.z_index = -1
	_jet_sprite.visible = false
	_jet_sprite.material = _unshaded_material()
	add_child(_jet_sprite)
	_jet_particles = CPUParticles2D.new()
	_jet_particles.name = "ThrusterExhaust"
	_jet_particles.emitting = false
	_jet_particles.local_coords = false
	_jet_particles.amount = 12
	_jet_particles.lifetime = 0.3
	_jet_particles.spread = 12.0
	_jet_particles.gravity = Vector2.ZERO
	_jet_particles.initial_velocity_min = JET_PARTICLE_SPEED * 0.5
	_jet_particles.initial_velocity_max = JET_PARTICLE_SPEED
	_jet_particles.scale_amount_min = 1.0
	_jet_particles.scale_amount_max = 2.0
	_jet_particles.color = JET_PARTICLE_COLOR
	_jet_particles.material = _unshaded_material()
	add_child(_jet_particles)


func _update_jet(delta: float) -> void:
	if _jet_sprite == null:
		return
	_jet_left = maxf(0.0, _jet_left - delta)
	var active: bool = (_thrusting or _jet_left > 0.0) and not _dead
	_jet_sprite.visible = active
	_jet_particles.emitting = active
	if not active:
		return
	_jet_clock += delta
	_jet_sprite.frame = int(_jet_clock * JET_FPS) % JET_FRAMES
	var flame: Vector2 = -_jet_direction
	if flame.is_zero_approx():
		flame = Vector2.DOWN
	_jet_sprite.position = JET_ORIGIN + flame * JET_DISTANCE
	_jet_sprite.rotation = flame.angle() - PI * 0.5
	_jet_particles.position = _jet_sprite.position
	_jet_particles.direction = flame


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


func _update_timers(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
	if _dash_cooldown > 0.0 and not _dashing:
		_dash_cooldown = maxf(0.0, _dash_cooldown - delta)
	if _invincible_left <= 0.0:
		return
	_invincible_left = maxf(0.0, _invincible_left - delta)
	_blink_timer += delta
	if _invincible_left <= 0.0:
		_blink_timer = 0.0
		_sprite.visible = true
		return
	_sprite.visible = fmod(_blink_timer, BLINK_INTERVAL * 2.0) < BLINK_INTERVAL


func _movement_blocked() -> bool:
	return _locked or _dead or _hurt_timer > 0.0


func _process_hurtbox(delta: float) -> void:
	if _dead or _invincible_hold:
		_damage_accumulator = 0.0
		_heat_accumulator = 0.0
		return
	var per_second: float = 0.0
	if _in_vacuum:
		per_second += Balance.VACUUM_DPS
	var climate: Dictionary = {
		"in_heat": false, "kind": HeatRules.KIND_WARM, "cooled": false,
		"in_cold": false, "warmed": false,
	}
	for area: Area2D in _hurtbox.get_overlapping_areas():
		_read_climate(area, climate)
		if not (area is DamageArea):
			continue
		var source: DamageArea = area
		if _dashing and source.dash_passable:
			continue
		if source.hurts_over_time():
			per_second += source.damage_per_second
		if not source.hurts_on_contact() or is_invincible():
			continue
		GameState.apply_damage(source.contact_damage)
		source.notify_status()
		_start_hurt(
			source.global_position, source.knockback, source.knockback_x, source.knockback_y
		)
	_process_heat(climate, delta)
	_process_cold(climate)
	if per_second <= 0.0:
		_damage_accumulator = 0.0
		return
	_damage_accumulator = GameState.apply_damage_over_time(
		per_second, delta, _damage_accumulator
	)


func _read_climate(area: Area2D, climate: Dictionary) -> void:
	if area is HeatZone:
		var zone: HeatZone = area
		if zone.is_cold():
			climate["in_cold"] = true
			return
		climate["in_heat"] = true
		if zone.is_furnace():
			climate["kind"] = HeatRules.KIND_FURNACE
	elif area is ColdIsland:
		var island: ColdIsland = area
		if island.cools():
			climate["cooled"] = true
		elif island.warms():
			climate["warmed"] = true


func _process_cold(climate: Dictionary) -> void:
	var in_cold: bool = bool(climate["in_cold"])
	var warmed: bool = bool(climate["warmed"])
	if FreezeRules.freezes(in_cold, warmed, _has_heated_core()):
		GameState.apply_status(StatusEffects.FREEZE)


func _process_heat(heat: Dictionary, delta: float) -> void:
	var in_heat: bool = bool(heat["in_heat"])
	var cooled: bool = bool(heat["cooled"])
	if HeatRules.overheats(in_heat, cooled):
		GameState.apply_status(StatusEffects.OVERHEAT)
	var furnace: float = HeatRules.furnace_dps(StringName(heat["kind"]), in_heat, cooled)
	var per_second: float = HeatRules.total_dps(
		GameState.statuses.integrity_dps(), furnace, _has_heat_sink()
	)
	if per_second <= 0.0:
		_heat_accumulator = 0.0
		return
	_heat_accumulator = GameState.apply_damage_over_time(per_second, delta, _heat_accumulator)


func _start_hurt(
	source: Vector2,
	push: bool,
	push_x: float = Balance.KNOCKBACK_SPEED,
	push_y: float = Balance.KNOCKBACK_SPEED
) -> void:
	_invincible_left = Balance.INVULNERABLE_TIME
	_blink_timer = 0.0
	AudioManager.play_sfx(&"damage")
	if _dead:
		return
	if push:
		_cancel_dash()
	play_action(&"hurt")
	if not push:
		return
	var direction: float = signf(global_position.x - source.x)
	if is_zero_approx(direction):
		direction = -float(facing)
	velocity = Vector2(direction * push_x, -push_y)
	_hurt_timer = Balance.SR3_KNOCKBACK_LOCK
	_jump_assist.cancel()


func _update_flashlight(delta: float) -> void:
	if not _locked and not _dead and Input.is_action_just_pressed(&"flashlight"):
		_toggle_flashlight()
	if not _flashlight_on:
		return
	var drain: float = Balance.FLASHLIGHT_DRAIN * GameState.statuses.charge_drain_multiplier()
	var cost: float = LightMath.drain_for(delta, drain)
	if not GameState.spend_charge(cost):
		_set_flashlight(false)


func _toggle_flashlight() -> void:
	if _flashlight_on:
		_set_flashlight(false)
		return
	if not LightMath.can_enable(GameState.charge, Balance.FLASHLIGHT_DRAIN):
		AudioManager.play_sfx(&"ui_back")
		return
	_set_flashlight(true)


func _set_flashlight(on: bool) -> void:
	if _flashlight_on == on:
		return
	_flashlight_on = on
	AudioManager.play_sfx(&"flashlight")
	var radius: float = Balance.VISION_RADIUS_ON if on else Balance.VISION_RADIUS_OFF
	if _light_tween != null and _light_tween.is_valid():
		_light_tween.kill()
	_light_tween = create_tween()
	_light_tween.set_parallel(true)
	_light_tween.tween_property(
		_flashlight,
		"texture_scale",
		LightMath.scale_for_radius(radius, LightMath.TEXTURE_SIZE),
		Balance.LIGHT_FADE_TIME
	)
	_light_tween.tween_property(
		_flashlight,
		"energy",
		Balance.FLASHLIGHT_ENERGY if on else Balance.SENSOR_ENERGY,
		Balance.LIGHT_FADE_TIME
	)
	EventBus.flashlight_toggled.emit(on)


func _update_interaction() -> void:
	var target: Interactable = null
	if not _interaction_blocked():
		target = _pick_interaction_target()
	_interaction_target = target
	var prompt: String = ""
	if target != null:
		prompt = InteractionRules.prompt(InteractionRules.glyph(_joypad), target.prompt_text)
	if prompt != _interaction_prompt:
		_interaction_prompt = prompt
		if prompt.is_empty():
			EventBus.interaction_cleared.emit()
		else:
			EventBus.interaction_available.emit(prompt)
	if target == null or not is_on_floor():
		return
	if not Input.is_action_just_pressed(&"interact"):
		return
	play_action(&"interact")
	AudioManager.play_sfx(&"interact")
	target.interact(self)


func _pick_interaction_target() -> Interactable:
	var candidates: Array[Interactable] = []
	var positions := PackedVector2Array()
	var enabled := PackedInt32Array()
	var priorities := PackedInt32Array()
	for area: Area2D in _sensor.get_overlapping_areas():
		if not (area is Interactable):
			continue
		var candidate: Interactable = area
		candidates.append(candidate)
		positions.append(candidate.global_position)
		enabled.append(1 if candidate.enabled else 0)
		priorities.append(candidate.interaction_priority)
	var index: int = InteractionRules.pick_index(positions, enabled, priorities, global_position)
	if index < 0:
		return null
	return candidates[index]


func _interaction_blocked() -> bool:
	return _locked or _dead or _hurt_timer > 0.0 or DialogueManager.freezes_timer()


func _land(fall_speed: float = 0.0) -> void:
	_wall_push = 0.0
	AudioManager.play_sfx(&"land")
	_set_state(State.LAND)
	var amplitude: float = ScreenShake.land_amplitude(
		fall_speed, Balance.LAND_SHAKE_SPEED, Balance.SHAKE_LAND
	)
	if amplitude <= 0.0:
		return
	shake(amplitude)
	Fx.burst(self, Fx.DUST_PUFF, global_position, Fx.DUST_TINT)


func _update_facing(axis: float) -> void:
	if is_zero_approx(axis):
		return
	facing = 1 if axis > 0.0 else -1
	_sprite.flip_h = facing < 0


func _update_state(axis: float) -> void:
	if _dead or _state == State.ACTION:
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
	if _dead:
		return
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


func _on_player_died() -> void:
	if _dead:
		return
	_dead = true
	_cancel_dash()
	_thrusting = false
	_jet_left = 0.0
	_vacuum_anchor = Vector2.ZERO
	_climbing = false
	_claw_blocked = false
	_wall_push = 0.0
	set_input_locked(true)
	velocity = Vector2.ZERO
	_hurt_timer = 0.0
	_invincible_left = 0.0
	_blink_timer = 0.0
	_damage_accumulator = 0.0
	_heat_accumulator = 0.0
	_sprite.visible = true
	_set_flashlight(false)
	play_action(&"death")


func _on_player_respawned() -> void:
	var spawn: Variant = _respawn_position()
	if spawn != null:
		global_position = spawn
	_dead = false
	_locked = false
	_cancel_dash()
	_dash_cooldown = 0.0
	_air_dash_used = false
	_double_jump_used = false
	_vacuum_anchor = Vector2.ZERO
	_climbing = false
	_claw_blocked = false
	_wall_push = 0.0
	_invincible_hold = false
	velocity = Vector2.ZERO
	_hurt_timer = 0.0
	_damage_accumulator = 0.0
	_heat_accumulator = 0.0
	_invincible_left = Balance.INVULNERABLE_TIME
	_blink_timer = 0.0
	_look_ahead = 0.0
	_jump_assist.cancel()
	_state = State.ACTION
	_set_state(State.IDLE)
	_camera.position.x = 0.0
	snap_camera()
	AudioManager.play_sfx(&"respawn")


func _respawn_position() -> Variant:
	var dock: BackupDock = _find_checkpoint_dock()
	if dock != null:
		return dock.spawn_position()
	for node: Node in get_tree().get_nodes_in_group(&"level"):
		if node.has_method("spawn_position"):
			return node.call("spawn_position")
	return null


func _find_checkpoint_dock() -> BackupDock:
	var wanted: String = String(GameState.checkpoint.get("dock_id", ""))
	var fallback: BackupDock = null
	for node: Node in get_tree().get_nodes_in_group(&"backup_dock"):
		if not (node is BackupDock):
			continue
		var dock: BackupDock = node
		if fallback == null:
			fallback = dock
		if String(dock.dock_id) == wanted:
			return dock
	if wanted.is_empty():
		return null
	return fallback
