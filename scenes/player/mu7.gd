class_name Mu7
extends CharacterBody2D

enum State { IDLE, WALK, JUMP, FALL, LAND, CLIMB, ACTION }

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
}
const ONE_WAY_BIT: int = 7
const CLAW_PROBE_REACH: float = 10.0
const STEP_FRAMES: Array[int] = [1, 4]
const DROP_NUDGE: float = 1.0
const BLINK_INTERVAL: float = 0.1
const SHADOW_SMOOTH: float = 1.5

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


func _ready() -> void:
	_build_animations()
	_setup_flash()
	_setup_sensor()
	_setup_flashlight()
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
	if _climbing:
		_climb_step(delta)
	else:
		_walk_step(delta)
	_process_hurtbox(delta)
	_update_flashlight(delta)
	_update_interaction()
	_update_shake(delta)
	_update_flash(delta)


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
	_wall_push = 0.0
	velocity = Vector2.ZERO
	_jump_assist.cancel()
	_set_state(State.CLIMB)
	AudioManager.play_sfx(&"claw_grab")
	return true


func _jump_off_wall() -> void:
	var jump_speed: float = absf(
		PlatformerMath.jump_velocity(Balance.JUMP_HEIGHT, Balance.GRAVITY)
	)
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
	return ClimbLogic.has_ability(GameState.abilities)


func is_climbing() -> bool:
	return _climbing


func set_input_locked(locked: bool) -> void:
	_locked = locked
	if not locked:
		return
	velocity.x = 0.0
	_jump_assist.cancel()


func is_input_locked() -> bool:
	return _locked


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
	_flashlight.shadow_filter_smooth = SHADOW_SMOOTH
	_flashlight.texture_scale = LightMath.scale_for_radius(
		Balance.VISION_RADIUS_OFF, LightMath.TEXTURE_SIZE
	)


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
	if _movement_blocked():
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


func _update_timers(delta: float) -> void:
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
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
		return
	var per_second: float = 0.0
	for area: Area2D in _hurtbox.get_overlapping_areas():
		if not (area is DamageArea):
			continue
		var source: DamageArea = area
		if source.hurts_over_time():
			per_second += source.damage_per_second
		if not source.hurts_on_contact() or is_invincible():
			continue
		GameState.apply_damage(source.contact_damage)
		source.notify_status()
		_start_hurt(source.global_position, source.knockback, source.knockback_x, source.knockback_y)
	if per_second <= 0.0:
		_damage_accumulator = 0.0
		return
	var dealt: Vector2 = Vitals.accumulate(_damage_accumulator, per_second, delta)
	_damage_accumulator = dealt.y
	if dealt.x > 0.0:
		GameState.apply_damage(int(dealt.x))


func _start_hurt(source: Vector2, push: bool, push_x: float = Balance.KNOCKBACK_SPEED, push_y: float = Balance.KNOCKBACK_SPEED) -> void:
	_invincible_left = Balance.INVULNERABLE_TIME
	_blink_timer = 0.0
	AudioManager.play_sfx(&"damage")
	if _dead:
		return
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
	var cost: float = LightMath.drain_for(delta, Balance.FLASHLIGHT_DRAIN)
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
	_climbing = false
	_claw_blocked = false
	_wall_push = 0.0
	set_input_locked(true)
	velocity = Vector2.ZERO
	_hurt_timer = 0.0
	_invincible_left = 0.0
	_blink_timer = 0.0
	_damage_accumulator = 0.0
	_sprite.visible = true
	_set_flashlight(false)
	play_action(&"death")


func _on_player_respawned() -> void:
	var spawn: Variant = _respawn_position()
	if spawn != null:
		global_position = spawn
	_dead = false
	_locked = false
	_climbing = false
	_claw_blocked = false
	_wall_push = 0.0
	_invincible_hold = false
	velocity = Vector2.ZERO
	_hurt_timer = 0.0
	_damage_accumulator = 0.0
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
