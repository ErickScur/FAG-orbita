extends Node

@export var sector_id: StringName = &"greenhouse"
@export var claws_dialogue: StringName = &"gh_claws"
@export var restored_dialogue: StringName = &"gh_restored"
@export var ambient_path: NodePath = ^"../CanvasModulate"

var _ending: bool = false

@onready var _ambient: CanvasModulate = get_node_or_null(ambient_path) as CanvasModulate


func _ready() -> void:
	EventBus.ability_unlocked.connect(_on_ability_unlocked)
	EventBus.sector_restored.connect(_on_sector_restored)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func is_ending() -> bool:
	return _ending


func restored_color() -> Color:
	var level: Node = get_parent()
	if level == null or not level.has_method(&"meta_color"):
		return Balance.LAMP_COLOR
	return level.call(&"meta_color", "ambient_restored")


func _on_ability_unlocked(ability_id: StringName) -> void:
	if ability_id != ClimbLogic.ABILITY_ID:
		return
	DialogueManager.play(claws_dialogue)


func _on_sector_restored(restored_id: StringName) -> void:
	if _ending or restored_id != sector_id:
		return
	_ending = true
	_light_the_sector()
	DialogueManager.play(restored_dialogue)


func _on_dialogue_finished() -> void:
	if not _ending:
		return
	_ending = false
	EventBus.demo_completed.emit()


func _light_the_sector() -> void:
	if _ambient == null:
		return
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(
		_ambient, ^"color", Balance.SECTOR_FLASH_COLOR, Balance.SECTOR_FLASH_TIME
	)
	tween.tween_property(_ambient, ^"color", restored_color(), Balance.SECTOR_SETTLE_TIME)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
