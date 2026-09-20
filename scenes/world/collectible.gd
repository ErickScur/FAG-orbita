class_name Collectible
extends Area2D

const SHEET_PATH: String = "res://assets/sprites/pickups/pickups_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(16, 16)
const FRAME_COUNT: int = 4
const ANIMATION_ID: StringName = &"idle"
const ANIMATION_FPS: float = 6.0
const PICKUP_LAYER: int = 32
const PLAYER_MASK: int = 2

@export var kind: StringName = &"cell"
@export var item_id: StringName = &""
@export var log_id: StringName = &""

var _collected: bool = false
var _base_y: float = 0.0
var _bob_time: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	collision_layer = PICKUP_LAYER
	collision_mask = PLAYER_MASK
	monitorable = false
	_normalize_ids()
	if is_already_collected():
		queue_free()
		return
	monitoring = true
	_base_y = position.y
	_bob_time = _phase_offset()
	_build_frames()
	body_entered.connect(_on_body_entered)
	set_process(true)


func _process(delta: float) -> void:
	_bob_time += delta * Balance.PICKUP_BOB_SPEED
	position.y = _base_y + roundf(sin(_bob_time) * Balance.PICKUP_BOB_AMPLITUDE)


func configure(params: Dictionary) -> void:
	if params.has("kind"):
		kind = StringName(String(params["kind"]))
	if params.has("item_id"):
		item_id = StringName(String(params["item_id"]))
	if params.has("log"):
		log_id = StringName(String(params["log"]))
	_normalize_ids()


func is_already_collected() -> bool:
	if item_id == &"":
		return false
	return GameState.collected_ids.has(item_id)


func was_collected() -> bool:
	return _collected


func _normalize_ids() -> void:
	if not PickupRules.is_known(kind):
		push_warning("Collectible: tipo desconhecido '%s'" % kind)
		kind = PickupRules.KIND_CELL
	if kind != PickupRules.KIND_LOG:
		return
	if log_id == &"":
		log_id = item_id
	elif item_id == &"":
		item_id = log_id


func _phase_offset() -> float:
	return float(int(absf(position.x) + absf(position.y)) % 16) * 0.25


func _build_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(ANIMATION_ID)
	frames.set_animation_speed(ANIMATION_ID, ANIMATION_FPS)
	frames.set_animation_loop(ANIMATION_ID, true)
	var row: int = PickupRules.sheet_row(kind)
	var added: int = 0
	for column: int in range(FRAME_COUNT):
		var texture: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, row)
		if texture == null:
			break
		frames.add_frame(ANIMATION_ID, texture)
		added += 1
	if added == 0:
		push_warning("Collectible: sprite sheet ausente em %s" % SHEET_PATH)
		return
	frames.remove_animation(&"default")
	_sprite.sprite_frames = frames
	_sprite.animation = ANIMATION_ID
	_sprite.play()


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group(&"player"):
		return
	collect()


func collect() -> bool:
	if _collected:
		return false
	if not PickupRules.can_collect(
		kind, GameState.charge, GameState.charge_max, GameState.integrity, GameState.integrity_max
	):
		return false
	if kind == PickupRules.KIND_CELL and GameState.statuses.blocks_charge_gain():
		return false
	_collected = true
	set_deferred(&"monitoring", false)
	AudioManager.play_sfx(PickupRules.sfx_for(kind))
	Fx.burst(self, Fx.PICKUP_SPARKLE, global_position, Fx.SPARKLE_TINT)
	match kind:
		PickupRules.KIND_CELL:
			GameState.add_charge(Balance.ENERGY_CELL_CHARGE)
			GameState.register_pickup(kind, item_id)
		PickupRules.KIND_REPAIR_KIT:
			GameState.repair(Balance.REPAIR_KIT_INTEGRITY)
			GameState.register_pickup(kind, item_id)
		PickupRules.KIND_CAPACITOR:
			GameState.expand_charge_max(Balance.CAPACITOR_BONUS)
			GameState.register_pickup(kind, item_id)
		PickupRules.KIND_LOG:
			_collect_log()
		_:
			GameState.register_pickup(kind, item_id)
	queue_free()
	return true


func _collect_log() -> void:
	DialogueManager.open_log(log_id)
	if GameState.collected_ids.has(log_id):
		return
	GameState.register_pickup(PickupRules.KIND_LOG, item_id)
