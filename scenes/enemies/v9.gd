class_name V9
extends Node2D

signal shut_down(duration: float)
signal woke_up()
signal latched()

const SHEET_PATH: String = "res://assets/sprites/enemies/v9_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const ANIMATIONS: Array[Dictionary] = [
	{"name": &"patrol", "row": 0, "columns": [0, 1, 2, 3], "fps": 8.0, "loop": true},
	{"name": &"alert", "row": 1, "columns": [0], "fps": 1.0, "loop": false},
	{"name": &"chase", "row": 1, "columns": [1], "fps": 1.0, "loop": false},
	{"name": &"latch", "row": 1, "columns": [2], "fps": 1.0, "loop": false},
	{"name": &"off", "row": 1, "columns": [3], "fps": 1.0, "loop": false},
]
const ANIM_PATROL: StringName = &"patrol"
const ANIM_ALERT: StringName = &"alert"
const ANIM_CHASE: StringName = &"chase"
const ANIM_LATCH: StringName = &"latch"
const ANIM_OFF: StringName = &"off"
const PLAYER_GROUP: StringName = &"player"
const POWERED_GROUP: StringName = &"powered"
const ENEMY_GROUP: StringName = &"enemy"
const BEAM_TARGET_GROUP: StringName = &"beam_target"
const WORLD_MASK: int = 1
const TARGET_HEIGHT: float = 12.0
const TOUCH_RADIUS: float = 12.0
const LATCH_OFFSET: Vector2 = Vector2.ZERO
const HALF_HEIGHT: float = 8.0
const FALL_PROBE: float = 320.0
const LENS_RADIUS: float = 22.0
const LENS_ENERGY: float = 0.9
const LENS_ENERGY_ALERT: float = 1.4
const LENS_PATROL: Color = Color("6fe0ff")
const LENS_ALERT: Color = Color("ffb347")
const LENS_CHASE: Color = Color("ff4a3a")
const ALERT_POP_SCALE: float = 1.25
const ALERT_SFX: StringName = &"ui_error"

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true

var path_tiles: PackedVector2Array = PackedVector2Array()

var _logic: V9Logic = V9Logic.new()
var _follower: PathFollower = null
var _origin: Vector2 = Vector2.ZERO
var _rest_y: float = 0.0
var _fall_speed: float = 0.0
var _pop: Tween = null

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _lens: PointLight2D = $Lens


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(ENEMY_GROUP)
	add_to_group(BEAM_TARGET_GROUP)
	_origin = position
	_build_animations()
	_setup_lens()
	_build_follower()
	set_powered_silent(powered)


func _physics_process(delta: float) -> void:
	var player: Mu7 = _player()
	var perception: Dictionary = _perceive(player)
	var event: StringName = _logic.update(
		delta, bool(perception["sees"]), bool(perception["heard"]), bool(perception["touching"])
	)
	_handle_event(event, player)
	_move(delta, player)
	_drain(delta, player)
	_refresh_visuals()


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("path"):
		path_tiles = MovingPlatform.points_from(params["path"])
	if params.has("powered"):
		powered = bool(params["powered"])
	if _sprite == null:
		return
	_build_follower()
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	set_powered_silent(on)
	AudioManager.play_sfx(&"power_on" if on else &"power_off")


func set_powered_silent(on: bool) -> void:
	powered = on
	_logic.set_powered(on)
	if not on:
		_start_fall()
	if _sprite == null:
		return
	_refresh_visuals()


func is_active() -> bool:
	return powered


func shutdown(duration: float) -> void:
	if not _logic.shutdown(duration):
		return
	_start_fall()
	AudioManager.play_sfx(&"sr3_shutdown")
	shut_down.emit(duration)
	if _sprite != null:
		_refresh_visuals()


func is_shut_down() -> bool:
	return _logic.state() == V9Logic.State.SHUTDOWN


func state() -> V9Logic.State:
	return _logic.state()


func state_name() -> String:
	return String(V9Logic.State.keys()[_logic.state()]).to_lower()


func current_animation() -> StringName:
	if _sprite == null:
		return &""
	return _sprite.animation


func lens_enabled() -> bool:
	return _lens != null and _lens.enabled


func _perceive(player: Mu7) -> Dictionary:
	var result: Dictionary = {"sees": false, "heard": false, "touching": false}
	if player == null or not _can_target(player):
		return result
	var target: Vector2 = _target_point(player)
	var distance: float = global_position.distance_to(target)
	result["heard"] = V9Logic.hears(distance, player.is_dashing())
	if distance <= Balance.V9_VISION_RANGE:
		var lit: bool = _is_lit(player, target)
		result["sees"] = V9Logic.sees(distance, lit, _line_clear(global_position, target))
	result["touching"] = distance <= TOUCH_RADIUS and not player.is_invincible()
	return result


func _can_target(player: Mu7) -> bool:
	if not powered or _logic.is_grounded():
		return false
	return not player.is_dead() and not player.is_input_locked()


func _is_lit(player: Mu7, target: Vector2) -> bool:
	if player.is_flashlight_on():
		return true
	var lamps: Array = []
	for node: Node in get_tree().get_nodes_in_group(POWERED_GROUP):
		if not (node is PoweredLamp):
			continue
		var lamp: PoweredLamp = node
		if not lamp.is_lit():
			continue
		var entry: Dictionary = LightExposure.lamp(lamp.global_position, lamp.radius)
		if LightExposure.inside(target, entry) and _line_clear(lamp.global_position, target):
			lamps.append(entry)
	return LightExposure.is_lit(target, false, lamps)


func _handle_event(event: StringName, player: Mu7) -> void:
	match event:
		V9Logic.EVENT_ALERTED:
			AudioManager.play_sfx(ALERT_SFX)
			_play_pop()
		V9Logic.EVENT_LATCHED:
			if player == null or not player.take_latch_hit(
				Balance.V9_CONTACT_DAMAGE, global_position
			):
				_logic.release()
				return
			latched.emit()
		V9Logic.EVENT_WOKE:
			_fall_speed = 0.0
			woke_up.emit()


func _move(delta: float, player: Mu7) -> void:
	match _logic.state():
		V9Logic.State.PATROL, V9Logic.State.COOLDOWN:
			_fly_track(delta)
		V9Logic.State.CHASE:
			if player != null:
				_fly_toward(_target_point(player), Balance.V9_CHASE_SPEED, delta)
		V9Logic.State.LATCHED:
			if player == null or player.is_dead():
				_logic.release()
				return
			global_position = _target_point(player) + LATCH_OFFSET
		V9Logic.State.SHUTDOWN, V9Logic.State.OFF:
			_fall(delta)


func _drain(delta: float, player: Mu7) -> void:
	if not _logic.is_latched() or player == null:
		return
	GameState.spend_charge(V9Logic.latch_drain(delta, GameState.charge))


func _fly_track(delta: float) -> void:
	if _follower == null:
		return
	var before: Vector2 = position
	position = _follower.step(position, delta)
	_face(position.x - before.x)


func _fly_toward(goal: Vector2, speed: float, delta: float) -> void:
	var offset: Vector2 = goal - global_position
	var travel: float = speed * delta
	if offset.length() <= travel:
		global_position = goal
	else:
		global_position += offset.normalized() * travel
	_face(offset.x)


func _start_fall() -> void:
	_fall_speed = 0.0
	_rest_y = global_position.y
	if not is_inside_tree():
		return
	var below: Vector2 = global_position + Vector2(0.0, FALL_PROBE)
	var hit: Dictionary = _ray_hit(global_position, below)
	if not hit.is_empty():
		_rest_y = (hit["position"] as Vector2).y - HALF_HEIGHT


func _fall(delta: float) -> void:
	if global_position.y >= _rest_y:
		return
	_fall_speed = minf(_fall_speed + Balance.GRAVITY * delta, Balance.MAX_FALL_SPEED)
	global_position.y = minf(_rest_y, global_position.y + _fall_speed * delta)


func _face(dx: float) -> void:
	if _sprite == null or is_zero_approx(dx):
		return
	_sprite.flip_h = dx < 0.0


func _target_point(player: Node2D) -> Vector2:
	return player.global_position + Vector2(0.0, -TARGET_HEIGHT)


func _line_clear(from: Vector2, to: Vector2) -> bool:
	return _ray_hit(from, to).is_empty()


func _ray_hit(from: Vector2, to: Vector2) -> Dictionary:
	var world: World2D = get_world_2d()
	if world == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from, to, WORLD_MASK)
	return world.direct_space_state.intersect_ray(query)


func _player() -> Mu7:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(PLAYER_GROUP) as Mu7


func _build_follower() -> void:
	var points := PackedVector2Array()
	if path_tiles.size() < 2:
		points.append(_origin)
	else:
		for offset: Vector2 in path_tiles:
			points.append(_origin + offset * float(Balance.TILE_SIZE))
	_follower = PathFollower.new(points, Balance.V9_PATROL_SPEED, 0.0)


func _refresh_visuals() -> void:
	var current: V9Logic.State = _logic.state()
	_play(_animation_for(current))
	var awake: bool = current != V9Logic.State.OFF and current != V9Logic.State.SHUTDOWN
	_lens.enabled = awake
	if not awake:
		return
	_lens.color = _lens_color(current)
	_lens.energy = LENS_ENERGY_ALERT if current == V9Logic.State.ALERT else LENS_ENERGY


func _animation_for(current: V9Logic.State) -> StringName:
	match current:
		V9Logic.State.ALERT:
			return ANIM_ALERT
		V9Logic.State.CHASE:
			return ANIM_CHASE
		V9Logic.State.LATCHED:
			return ANIM_LATCH
		V9Logic.State.SHUTDOWN, V9Logic.State.OFF:
			return ANIM_OFF
	return ANIM_PATROL


func _lens_color(current: V9Logic.State) -> Color:
	if current == V9Logic.State.ALERT:
		return LENS_ALERT
	if current == V9Logic.State.CHASE or current == V9Logic.State.LATCHED:
		return LENS_CHASE
	return LENS_PATROL


func _play_pop() -> void:
	if _sprite == null:
		return
	if _pop != null and _pop.is_valid():
		_pop.kill()
	_sprite.scale = Vector2.ONE
	_pop = create_tween()
	var half: float = Balance.V9_ALERT_TIME * 0.5
	_pop.tween_property(_sprite, "scale", Vector2.ONE * ALERT_POP_SCALE, half)
	_pop.tween_property(_sprite, "scale", Vector2.ONE, half)


func _setup_lens() -> void:
	_lens.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _lens.texture == null:
		push_warning("V9: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_lens.blend_mode = Light2D.BLEND_MODE_ADD
	_lens.shadow_enabled = false
	_lens.color = LENS_PATROL
	_lens.energy = LENS_ENERGY
	_lens.texture_scale = LightMath.scale_for_radius(LENS_RADIUS, LightMath.TEXTURE_SIZE)


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("V9: sprite sheet ausente em %s" % SHEET_PATH)
		return
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	for entry: Dictionary in ANIMATIONS:
		var animation: StringName = entry["name"]
		frames.add_animation(animation)
		frames.set_animation_speed(animation, float(entry["fps"]))
		frames.set_animation_loop(animation, bool(entry["loop"]))
		for column: Variant in entry["columns"] as Array:
			var atlas: AtlasTexture = AssetResolver.atlas(
				SHEET_PATH, FRAME_SIZE, int(column), int(entry["row"])
			)
			if atlas != null:
				atlas.filter_clip = true
				frames.add_frame(animation, atlas)
	_sprite.sprite_frames = frames


func _play(animation: StringName) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(animation):
		return
	if _sprite.animation == animation and _sprite.is_playing():
		return
	if _sprite.animation == animation and not _sprite.sprite_frames.get_animation_loop(animation):
		return
	_sprite.play(animation)
