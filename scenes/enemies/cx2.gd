class_name Cx2
extends Node2D

signal shut_down(duration: float)
signal woke_up()

const SHEET_PATH: String = "res://assets/sprites/enemies/cx2_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const ANIMATIONS: Array[Dictionary] = [
	{"name": &"scan", "row": 0, "columns": [0, 1, 2, 3], "fps": 1.0, "loop": false},
	{"name": &"lock", "row": 1, "columns": [0, 1], "fps": 10.0, "loop": true},
	{"name": &"fire", "row": 1, "columns": [2], "fps": 1.0, "loop": false},
	{"name": &"off", "row": 1, "columns": [3], "fps": 1.0, "loop": false},
]
const ANIM_SCAN: StringName = &"scan"
const ANIM_LOCK: StringName = &"lock"
const ANIM_FIRE: StringName = &"fire"
const ANIM_OFF: StringName = &"off"
const SCAN_FRAMES: int = 4
const PLAYER_GROUP: StringName = &"player"
const POWERED_GROUP: StringName = &"powered"
const ENEMY_GROUP: StringName = &"enemy"
const BEAM_TARGET_GROUP: StringName = &"beam_target"
const WORLD_MASK: int = 1
const HALF_TILE: float = 8.0
const SPRITE_DEPTH: float = 16.0
const LENS_DEPTH: float = 24.0
const TARGET_HEIGHT: float = 12.0
const CONE_RAYS: int = 11
const FIRE_FLASH_TIME: float = 0.15
const SCAN_COLOR: Color = Color(0.45, 0.85, 1.0, 0.16)
const LOCK_COLOR: Color = Color(1.0, 0.25, 0.2, 0.3)
const LIGHT_SCAN: Color = Color("6fd8ff")
const LIGHT_LOCK: Color = Color("ff4a3a")
const LIGHT_ENERGY: float = 0.8
const LIGHT_ENERGY_LOCK: float = 1.2

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true
@export var mount: StringName = Cx2Logic.MOUNT_CEILING

var _logic: Cx2Logic = Cx2Logic.new()
var _angle_override: float = 0.0
var _has_angle_override: bool = false
var _fire_left: float = 0.0
var _was_locking: bool = false
var _was_shut_down: bool = false

@onready var _mount: Node2D = $Mount
@onready var _sprite: AnimatedSprite2D = $Mount/Sprite
@onready var _cone: Polygon2D = $Cone
@onready var _light: PointLight2D = $ConeLight


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(ENEMY_GROUP)
	add_to_group(BEAM_TARGET_GROUP)
	_build_animations()
	_setup_cone()
	_setup_light()
	_apply_mount()
	set_powered_silent(powered)


func _physics_process(delta: float) -> void:
	if _fire_left > 0.0:
		_fire_left = maxf(0.0, _fire_left - delta)
	var player: Node2D = _player()
	var sees: bool = player != null and _sees(player)
	if _logic.update(delta, sees):
		_fire(player)
	_check_wake()
	var locking: bool = _logic.phase() == Cx2Logic.Phase.LOCK
	if locking and not _was_locking:
		AudioManager.play_sfx(&"ui_error")
	_was_locking = locking
	_refresh_visuals()


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	mount = Cx2Logic.normalize_mount(StringName(String(params.get("mount", mount))))
	if params.has("base_angle"):
		_angle_override = float(params["base_angle"])
		_has_angle_override = true
	if params.has("powered"):
		powered = bool(params["powered"])
	if _sprite == null:
		return
	_apply_mount()
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	set_powered_silent(on)
	AudioManager.play_sfx(&"power_on" if on else &"power_off")


func set_powered_silent(on: bool) -> void:
	powered = on
	_logic.set_powered(on)
	_fire_left = 0.0
	_was_locking = false
	if _sprite == null:
		return
	_refresh_visuals()


func is_active() -> bool:
	return powered


func shutdown(duration: float) -> void:
	if not _logic.shutdown(duration):
		return
	_fire_left = 0.0
	_was_locking = false
	_was_shut_down = true
	if powered:
		AudioManager.play_sfx(&"sr3_shutdown")
	shut_down.emit(duration)
	if _sprite != null:
		_refresh_visuals()


func is_shut_down() -> bool:
	return _logic.is_shut_down()


func shutdown_remaining() -> float:
	return _logic.shutdown_remaining()


func lens_position() -> Vector2:
	var depth := Vector2(0.0, LENS_DEPTH).rotated(deg_to_rad(Cx2Logic.mount_rotation(mount)))
	return global_position + Cx2Logic.mount_base(mount) * HALF_TILE + depth


func aim_angle() -> float:
	return _logic.aim_angle()


func phase() -> Cx2Logic.Phase:
	return _logic.phase()


func current_animation() -> StringName:
	if _sprite == null:
		return &""
	return _sprite.animation


func _check_wake() -> void:
	if not _was_shut_down or _logic.is_shut_down():
		return
	_was_shut_down = false
	woke_up.emit()


func _sees(player: Node2D) -> bool:
	if not powered or _logic.is_shut_down():
		return false
	if player.has_method(&"is_input_locked") and bool(player.call(&"is_input_locked")):
		return false
	var target: Vector2 = player.global_position + Vector2(0.0, -TARGET_HEIGHT)
	var origin: Vector2 = lens_position()
	var inside: bool = Cx2Logic.in_cone(
		origin, _logic.aim_angle(), Balance.CX2_CONE_HALF_ANGLE, Balance.CX2_RANGE, target
	)
	if not inside:
		return false
	return _ray_hit(origin, target).is_empty()


func _fire(player: Node2D) -> void:
	_fire_left = FIRE_FLASH_TIME
	AudioManager.play_sfx(&"terminal_breaker")
	if not (player is Mu7):
		return
	var hit: bool = (player as Mu7).take_hit(
		Balance.CX2_PULSE_DAMAGE, global_position, Balance.KNOCKBACK_SPEED, Balance.KNOCKBACK_SPEED
	)
	if hit:
		GameState.apply_status(StatusEffects.DISCHARGE, Balance.DISCHARGE_TIME)


func _player() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(PLAYER_GROUP) as Node2D


func _ray_hit(from: Vector2, to: Vector2) -> Dictionary:
	var world: World2D = get_world_2d()
	if world == null:
		return {}
	var query := PhysicsRayQueryParameters2D.create(from, to, WORLD_MASK)
	return world.direct_space_state.intersect_ray(query)


func _refresh_visuals() -> void:
	var current: Cx2Logic.Phase = _logic.phase()
	var animation: StringName = _animation_for(current)
	if animation == ANIM_SCAN:
		_show_scan_frame()
	else:
		_play(animation)
	var visible_cone: bool = current == Cx2Logic.Phase.SCAN or current == Cx2Logic.Phase.LOCK
	_cone.visible = visible_cone
	_light.enabled = visible_cone
	if not visible_cone:
		return
	var locking: bool = current == Cx2Logic.Phase.LOCK
	_cone.color = SCAN_COLOR.lerp(LOCK_COLOR, _logic.lock_ratio()) if locking else SCAN_COLOR
	_light.color = LIGHT_LOCK if locking else LIGHT_SCAN
	_light.energy = LIGHT_ENERGY_LOCK if locking else LIGHT_ENERGY
	_update_cone_shape()


func _update_cone_shape() -> void:
	var origin: Vector2 = lens_position()
	var aim: float = _logic.aim_angle()
	var half: float = Balance.CX2_CONE_HALF_ANGLE
	var distances := PackedFloat32Array()
	for index: int in range(CONE_RAYS):
		var ratio: float = float(index) / float(CONE_RAYS - 1)
		var angle: float = aim - half + ratio * half * 2.0
		var end: Vector2 = origin + Cx2Logic.direction(angle) * Balance.CX2_RANGE
		var hit: Dictionary = _ray_hit(origin, end)
		var reach: float = Balance.CX2_RANGE
		if not hit.is_empty():
			reach = origin.distance_to(hit["position"])
		distances.append(reach)
	var points: PackedVector2Array = Cx2Logic.cone_polygon(origin, aim, half, distances)
	var local := PackedVector2Array()
	for point: Vector2 in points:
		local.append(point - global_position)
	_cone.polygon = local
	var middle: Vector2 = Cx2Logic.direction(aim) * Balance.CX2_RANGE * 0.5
	_light.position = origin - global_position + middle


func _show_scan_frame() -> void:
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(ANIM_SCAN):
		return
	var frame: int = Cx2Logic.scan_frame(_logic.current_sweep(), _logic.sweep_arc, SCAN_FRAMES)
	if _sprite.animation != ANIM_SCAN:
		_sprite.animation = ANIM_SCAN
	_sprite.pause()
	if _sprite.frame != frame:
		_sprite.frame = frame


func _animation_for(current: Cx2Logic.Phase) -> StringName:
	if current == Cx2Logic.Phase.OFF or current == Cx2Logic.Phase.SHUTDOWN:
		return ANIM_OFF
	if _fire_left > 0.0:
		return ANIM_FIRE
	if current == Cx2Logic.Phase.LOCK:
		return ANIM_LOCK
	return ANIM_SCAN


func _apply_mount() -> void:
	mount = Cx2Logic.normalize_mount(mount)
	_logic.base_angle = _angle_override if _has_angle_override else Cx2Logic.mount_aim(mount)
	_mount.position = Cx2Logic.mount_base(mount) * HALF_TILE
	_mount.rotation_degrees = Cx2Logic.mount_rotation(mount)
	_sprite.position = Vector2(0.0, SPRITE_DEPTH)


func _setup_cone() -> void:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_cone.material = material
	_cone.color = SCAN_COLOR


func _setup_light() -> void:
	_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _light.texture == null:
		push_warning("CX2: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.shadow_enabled = true
	_light.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	_light.shadow_filter_smooth = Balance.SHADOW_FILTER_SMOOTH
	_light.color = LIGHT_SCAN
	_light.energy = LIGHT_ENERGY
	_light.texture_scale = LightMath.scale_for_radius(
		Balance.CX2_RANGE * 0.5, LightMath.TEXTURE_SIZE
	)


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("CX2: sprite sheet ausente em %s" % SHEET_PATH)
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
