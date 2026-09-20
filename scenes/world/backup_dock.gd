class_name BackupDock
extends Node2D

const SHEET_PATH: String = "res://assets/sprites/world/dock_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 48)
const ANIMATION_ROWS: Array[Dictionary] = [
	{"name": &"idle", "row": 0, "frames": 1, "fps": 1.0, "loop": true},
	{"name": &"charging", "row": 0, "frames": 5, "fps": 8.0, "loop": true},
]
const REST_SPEED: float = 1.0
const CORROSION: StringName = &"corrosion"

@export var dock_id: StringName = &"dock"

var _player: CharacterBody2D = null
var _repair_accumulator: float = 0.0
var _corroded: bool = false
var _charging: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _zone: Area2D = $ChargeZone


func _ready() -> void:
	add_to_group(&"backup_dock")
	_build_animations()
	_zone.body_entered.connect(_on_body_entered)
	_zone.body_exited.connect(_on_body_exited)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_cleared.connect(_on_status_cleared)
	_set_charging(false)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_set_charging(false)
		return
	if GameState.is_dead() or not _is_resting():
		_set_charging(false)
		return
	_set_charging(true)
	if not _corroded:
		GameState.add_charge(Balance.CHARGE_DOCK_REGEN * delta)
	var repaired: Vector2 = Vitals.accumulate(
		_repair_accumulator, Balance.DOCK_REPAIR_RATE, delta
	)
	_repair_accumulator = repaired.y
	if repaired.x > 0.0:
		GameState.repair(int(repaired.x))


func spawn_position() -> Vector2:
	return global_position


func is_charging() -> bool:
	return _charging


func activate() -> void:
	var scene_path: String = _current_scene_path()
	if _is_current_checkpoint(scene_path):
		return
	GameState.checkpoint = {"scene": scene_path, "dock_id": String(dock_id)}
	AudioManager.play_sfx(&"power_on")
	EventBus.checkpoint_reached.emit(dock_id)


func _build_animations() -> void:
	var texture: Texture2D = AssetResolver.texture(SHEET_PATH)
	if texture == null:
		push_warning("BackupDock: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.sprite_frames = SpriteSheet.build_frames(texture, FRAME_SIZE, ANIMATION_ROWS)


func _is_resting() -> bool:
	return _player.is_on_floor() and absf(_player.velocity.x) < REST_SPEED


func _set_charging(value: bool) -> void:
	if _charging == value:
		return
	_charging = value
	if not value:
		_repair_accumulator = 0.0
	if _sprite.sprite_frames == null:
		return
	_sprite.play(&"charging" if value else &"idle")


func _is_current_checkpoint(scene_path: String) -> bool:
	if String(GameState.checkpoint.get("dock_id", "")) != String(dock_id):
		return false
	return String(GameState.checkpoint.get("scene", "")) == scene_path


func _current_scene_path() -> String:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return ""
	return scene.scene_file_path


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player") or not (body is CharacterBody2D):
		return
	_player = body
	activate()


func _on_body_exited(body: Node2D) -> void:
	if body != _player:
		return
	_player = null
	_set_charging(false)


func _on_status_applied(status_id: StringName, _duration: float) -> void:
	if status_id == CORROSION:
		_corroded = true


func _on_status_cleared(status_id: StringName) -> void:
	if status_id == CORROSION:
		_corroded = false
