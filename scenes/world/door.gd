class_name Door
extends AnimatableBody2D

const SHEET_PATH: String = "res://assets/sprites/world/door_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 48)
const BLOCK_SIZE: Vector2i = Vector2i(16, 48)
const FRAME_CLOSED: int = 0
const FRAME_OPEN: int = 4
const OPEN_FPS: float = 9.0
const SEALED_TINT: Color = Color("ff7a7a")
const BULKHEAD_PROBE_INSET: float = 1.0
const BULKHEAD_DELAY_FRAMES: int = 2
const BULKHEAD_SEAM_STEP: float = 8.0
const BULKHEAD_OUTLINE: Color = Color("0f151d")
const BULKHEAD_BODY: Color = Color("1f2b36")
const BULKHEAD_EDGE: Color = Color("4e6474")
const BULKHEAD_COLUMNS: Array[Vector2i] = [
	Vector2i(-15, 0), Vector2i(-9, 0), Vector2i(8, 0), Vector2i(14, 0),
]
const ANIM_CLOSED: StringName = &"closed"
const ANIM_OPENING: StringName = &"opening"
const ANIM_OPEN: StringName = &"open"
const ANIM_CLOSING: StringName = &"closing"
const ANIM_SEALED: StringName = &"sealed"

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = false
@export var sealed: bool = false

var _bulkhead_height: float = 0.0
var _bulkhead_delay: int = BULKHEAD_DELAY_FRAMES

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _bulkhead: CollisionShape2D = $BulkheadShape


func _ready() -> void:
	add_to_group(&"powered")
	add_to_group(&"door")
	_build_animations()
	_sprite.animation_finished.connect(_on_animation_finished)
	set_powered_silent(powered)
	EventBus.energy_changed.connect(_on_energy_changed)
	set_physics_process(true)


func _physics_process(_delta: float) -> void:
	if _bulkhead_delay > 0:
		_bulkhead_delay -= 1
		return
	set_physics_process(false)
	_measure_bulkhead()


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


func _draw() -> void:
	if _bulkhead_height <= 0.0:
		return
	var top: float = -float(BLOCK_SIZE.y) - _bulkhead_height
	draw_rect(Rect2(-15.0, top, 30.0, _bulkhead_height), BULKHEAD_BODY)
	for column: Vector2i in BULKHEAD_COLUMNS:
		var tone: Color = BULKHEAD_EDGE if column.y == 1 else BULKHEAD_OUTLINE
		draw_rect(Rect2(float(column.x), top, 1.0, _bulkhead_height), tone)
	var bolt: float = -float(BLOCK_SIZE.y) - BULKHEAD_SEAM_STEP
	while bolt > top + 1.0:
		draw_rect(Rect2(-14.0, bolt, 2.0, 1.0), BULKHEAD_EDGE)
		draw_rect(Rect2(12.0, bolt, 2.0, 1.0), BULKHEAD_EDGE)
		bolt -= BULKHEAD_SEAM_STEP
	draw_rect(Rect2(-15.0, top, 30.0, 1.0), BULKHEAD_OUTLINE)


func _measure_bulkhead() -> void:
	_bulkhead_height = _ceiling_gap()
	queue_redraw()
	if _bulkhead == null:
		return
	if _bulkhead_height <= 0.0:
		_bulkhead.set_deferred(&"disabled", true)
		return
	var shape := RectangleShape2D.new()
	shape.size = Vector2(float(BLOCK_SIZE.x), _bulkhead_height)
	_bulkhead.shape = shape
	_bulkhead.position = Vector2(0.0, -float(BLOCK_SIZE.y) - _bulkhead_height * 0.5)
	_bulkhead.set_deferred(&"disabled", false)


func _ceiling_gap() -> float:
	var world: World2D = get_world_2d()
	if world == null:
		return 0.0
	var from: Vector2 = global_position + Vector2(
		0.0, -float(BLOCK_SIZE.y) + BULKHEAD_PROBE_INSET
	)
	var to: Vector2 = from + Vector2(0.0, -(Balance.DOOR_BULKHEAD_MAX + BULKHEAD_PROBE_INSET))
	var query := PhysicsRayQueryParameters2D.create(from, to, 1, [get_rid()])
	var hit: Dictionary = world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return Balance.DOOR_BULKHEAD_MAX
	return floorf(maxf(absf(float(hit["position"].y) - from.y) - BULKHEAD_PROBE_INSET, 0.0))


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
