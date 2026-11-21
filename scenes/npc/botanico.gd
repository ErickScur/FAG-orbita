class_name Botanico
extends Node2D

signal noticed_player()

const SHEET_PATH: String = "res://assets/sprites/npc/botanico_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const FRAME_SIZE: Vector2i = Vector2i(16, 16)
const ANIMATIONS: Array[Dictionary] = [
	{"name": &"hover", "columns": [0, 1, 2, 3], "fps": 8.0, "loop": true},
	{"name": &"spray", "columns": [4, 5], "fps": 6.0, "loop": true},
]
const ANIM_HOVER: StringName = &"hover"
const ANIM_SPRAY: StringName = &"spray"
const PLAYER_GROUP: StringName = &"player"
const LIGHT_COLOR: Color = Color("ffd98a")
const BEEP_SFX: StringName = &"ui_confirm"
const AIR_MARGIN: float = 6.0
const CEILING_CLEARANCE: float = 20.0
const FLOOR_CLEARANCE: float = 12.0
const BOB_HEIGHT: float = 1.0
const BOB_HZ: float = 1.5

@export var home_radius: float = 0.0
@export var zone: Array = []

var _rng := RandomNumberGenerator.new()
var _home: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _territory: Rect2 = Rect2()
var _time_since_target: float = 0.0
var _spray_left: float = 0.0
var _following: bool = false
var _met_player: bool = false
var _bob_time: float = 0.0
var _mark: Vector2 = Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _lamp: PointLight2D = $Lamp


func _ready() -> void:
	_rng.randomize()
	_home = global_position
	if home_radius <= 0.0:
		home_radius = Balance.DRONE_WANDER_RADIUS
	_territory = WanderLogic.territory_rect(zone, Balance.TILE_SIZE)
	_build_animations()
	_setup_lamp()
	_bob_time = _rng.randf_range(0.0, 1.0)
	_target = _wander_target()
	_play(ANIM_HOVER)


func _physics_process(delta: float) -> void:
	var player: Node2D = _player()
	_update_following(player)
	_time_since_target += delta
	if _spray_left > 0.0:
		_spray_left -= delta
		if _spray_left <= 0.0:
			_retarget(player)
		_animate(delta)
		return
	var speed: float = Balance.DRONE_FOLLOW_SPEED if _following else Balance.DRONE_SPEED
	var before: Vector2 = global_position
	global_position = WanderLogic.step(global_position, _target, speed, delta)
	_face(global_position.x - before.x)
	var arrived: bool = WanderLogic.reached(
		global_position, _target, WanderLogic.ARRIVAL_TOLERANCE
	)
	var retarget_time: float = (
		Balance.DRONE_FOLLOW_RETARGET_TIME if _following else Balance.DRONE_RETARGET_TIME
	)
	if not _following and WanderLogic.should_spray(arrived, Balance.DRONE_SPRAY_CHANCE, _rng):
		_spray_left = Balance.DRONE_SPRAY_TIME
	elif WanderLogic.should_retarget(_time_since_target, retarget_time, false, arrived):
		_retarget(player)
	_animate(delta)


func configure(params: Dictionary) -> void:
	home_radius = float(params.get("home_radius", home_radius))
	if params.get("zone", []) is Array:
		zone = params.get("zone", [])
	_territory = WanderLogic.territory_rect(zone, Balance.TILE_SIZE)


func is_following() -> bool:
	return _following


func is_spraying() -> bool:
	return _spray_left > 0.0


func has_met_player() -> bool:
	return _met_player


func distance_to_player() -> float:
	var player: Node2D = _player()
	if player == null:
		return -1.0
	return global_position.distance_to(player.global_position)


func distance_from_home() -> float:
	return global_position.distance_to(_home)


func lamp_lit() -> bool:
	return _lamp != null and _lamp.enabled and _lamp.energy > 0.0


func is_within(max_distance: float) -> bool:
	var distance: float = distance_to_player()
	return distance >= 0.0 and distance <= max_distance


func is_home(max_distance: float) -> bool:
	return distance_from_home() <= max_distance


func mark_position() -> void:
	_mark = global_position


func moved_since_mark(min_distance: float) -> bool:
	return global_position.distance_to(_mark) >= min_distance


func _update_following(player: Node2D) -> void:
	var was_following: bool = _following
	if player == null:
		_following = false
	else:
		_following = WanderLogic.should_follow(
			_following,
			player.global_position,
			global_position,
			_territory.grow_individual(0.0, 0.0, 0.0, float(Balance.TILE_SIZE)),
			Balance.DRONE_FOLLOW_RADIUS
		)
	if _following == was_following:
		return
	_spray_left = 0.0
	_retarget(player)
	if _following and not _met_player:
		_met_player = true
		AudioManager.play_sfx(BEEP_SFX)
		noticed_player.emit()


func _retarget(player: Node2D) -> void:
	_time_since_target = 0.0
	if _following and player != null:
		var facing: int = int(player.get(&"facing")) if &"facing" in player else 1
		var anchor: Vector2 = WanderLogic.follow_point(
			player.global_position, facing, Balance.DRONE_LEAD, Balance.DRONE_HOVER_HEIGHT
		)
		_target = _inside(WanderLogic.pick_target(anchor, Balance.DRONE_FOLLOW_JITTER, _rng))
		return
	_target = _wander_target()


func _wander_target() -> Vector2:
	return _inside(WanderLogic.pick_target(_home, home_radius, _rng))


func _inside(point: Vector2) -> Vector2:
	if _territory.size.x <= 0.0 or _territory.size.y <= 0.0:
		return point
	var air := Rect2(
		_territory.position + Vector2(AIR_MARGIN, CEILING_CLEARANCE),
		_territory.size - Vector2(AIR_MARGIN * 2.0, CEILING_CLEARANCE + FLOOR_CLEARANCE)
	)
	return WanderLogic.clamp_to(point, air)


func _animate(delta: float) -> void:
	_bob_time += delta
	if _sprite != null:
		_sprite.offset.y = roundf(sin(_bob_time * BOB_HZ * TAU) * BOB_HEIGHT)
	_play(ANIM_SPRAY if _spray_left > 0.0 else ANIM_HOVER)


func _face(dx: float) -> void:
	if _sprite == null or absf(dx) < 0.01:
		return
	_sprite.flip_h = dx < 0.0


func _player() -> Node2D:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group(PLAYER_GROUP) as Node2D


func _setup_lamp() -> void:
	_lamp.texture = AssetResolver.texture(LIGHT_TEXTURE)
	if _lamp.texture == null:
		push_warning("Botanico: textura de luz ausente em %s" % LIGHT_TEXTURE)
	_lamp.blend_mode = Light2D.BLEND_MODE_ADD
	_lamp.shadow_enabled = true
	_lamp.shadow_filter = Light2D.SHADOW_FILTER_PCF13
	_lamp.shadow_filter_smooth = Balance.SHADOW_FILTER_SMOOTH
	_lamp.color = LIGHT_COLOR
	_lamp.energy = Balance.DRONE_LIGHT_ENERGY
	_lamp.texture_scale = LightMath.scale_for_radius(
		Balance.DRONE_LIGHT_RADIUS, LightMath.TEXTURE_SIZE
	)


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("Botanico: sprite sheet ausente em %s" % SHEET_PATH)
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
			var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, int(column), 0)
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
	_sprite.play(animation)
