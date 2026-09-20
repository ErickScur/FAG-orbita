class_name Door
extends AnimatableBody2D

const SHEET_PATH: String = "res://assets/sprites/world/door_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 48)
const BLOCK_SIZE: Vector2i = Vector2i(16, 48)
const FRAME_CLOSED: int = 0
const FRAME_OPEN: int = 4
const OPEN_FPS: float = 9.0
const SEALED_TINT: Color = Color("ff7a7a")
const ANIM_CLOSED: StringName = &"closed"
const ANIM_OPENING: StringName = &"opening"
const ANIM_OPEN: StringName = &"open"
const ANIM_CLOSING: StringName = &"closing"
const ANIM_SEALED: StringName = &"sealed"

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = false
@export var sealed: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	add_to_group(&"powered")
	add_to_group(&"door")
	_build_animations()
	_sprite.animation_finished.connect(_on_animation_finished)
	set_powered_silent(powered)
	EventBus.energy_changed.connect(_on_energy_changed)


func set_powered(on: bool) -> void:
	if sealed or powered == on:
		return
	powered = on
	if on:
		AudioManager.play_sfx(&"door_open")
		_play(ANIM_OPENING)
		return
	_push_bodies_out()
	AudioManager.play_sfx(&"door_close")
	_set_blocking(true)
	_play(ANIM_CLOSING)


func set_powered_silent(on: bool) -> void:
	powered = on and not sealed
	if _sprite != null:
		_sprite.modulate = SEALED_TINT if sealed else Color.WHITE
	if sealed:
		_play(ANIM_SEALED)
		_set_blocking(true)
		return
	_play(ANIM_OPEN if powered else ANIM_CLOSED)
	_set_blocking(not powered)


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	sealed = bool(params.get("sealed", sealed))
	if _sprite == null:
		return
	set_powered_silent(powered)


func is_open() -> bool:
	return powered and not sealed


func current_animation() -> StringName:
	if _sprite == null:
		return &""
	return _sprite.animation


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("Door: sprite sheet ausente em %s" % SHEET_PATH)
		return
	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")
	_add_animation(frames, texture, ANIM_CLOSED, [FRAME_CLOSED])
	_add_animation(frames, texture, ANIM_OPENING, [1, 2, 3])
	_add_animation(frames, texture, ANIM_OPEN, [FRAME_OPEN])
	_add_animation(frames, texture, ANIM_CLOSING, [3, 2, 1])
	_add_animation(frames, texture, ANIM_SEALED, [FRAME_CLOSED])
	_sprite.sprite_frames = frames


func _add_animation(
	frames: SpriteFrames, texture: Texture2D, name: StringName, columns: Array[int]
) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, OPEN_FPS)
	frames.set_animation_loop(name, false)
	for column: int in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(
			Vector2(column * FRAME_SIZE.x, 0.0), Vector2(FRAME_SIZE)
		)
		atlas.filter_clip = true
		frames.add_frame(name, atlas)


func _play(name: StringName) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	if not _sprite.sprite_frames.has_animation(name):
		return
	_sprite.play(name)


func _set_blocking(blocking: bool) -> void:
	if _shape == null:
		return
	_shape.set_deferred(&"disabled", not blocking)


func _push_bodies_out() -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var half_width: float = float(BLOCK_SIZE.x) * 0.5
	for node: Node in tree.get_nodes_in_group(&"player"):
		var body := node as Node2D
		if body == null:
			continue
		var offset: Vector2 = body.global_position - global_position
		if absf(offset.x) > half_width or offset.y > 0.0 or offset.y < -float(BLOCK_SIZE.y):
			continue
		var direction: float = signf(offset.x)
		if is_zero_approx(direction):
			direction = 1.0
		body.global_position.x = global_position.x + direction * float(Balance.TILE_SIZE)


func _on_animation_finished() -> void:
	if _sprite.animation == ANIM_OPENING:
		_play(ANIM_OPEN)
		_set_blocking(false)
	elif _sprite.animation == ANIM_CLOSING:
		_play(ANIM_CLOSED)


func _on_energy_changed(
	changed_terminal: StringName, changed_system: StringName, on: bool
) -> void:
	if changed_terminal != terminal_id or changed_system != system_id:
		return
	set_powered(on)
