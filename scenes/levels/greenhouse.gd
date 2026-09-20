extends Node

const CUTSCENE_GROUP: StringName = &"sector_cutscene"

@export var sector_id: StringName = &"greenhouse"
@export var claws_dialogue: StringName = &"gh_claws"
@export var restored_dialogue: StringName = &"gh_restored"

var _ending: bool = false
var _closing: bool = false


func _ready() -> void:
	EventBus.ability_unlocked.connect(_on_ability_unlocked)
	EventBus.sector_restored.connect(_on_sector_restored)
	EventBus.sector_cutscene_finished.connect(_on_cutscene_finished)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func is_ending() -> bool:
	return _ending


func _on_ability_unlocked(ability_id: StringName) -> void:
	if ability_id != ClimbLogic.ABILITY_ID:
		return
	DialogueManager.play(claws_dialogue)


func _on_sector_restored(restored_id: StringName) -> void:
	if _ending or restored_id != sector_id:
		return
	_ending = true
	if _has_cutscene():
		return
	_play_closing()


func _on_cutscene_finished(restored_id: StringName) -> void:
	if not _ending or _closing or restored_id != sector_id:
		return
	_play_closing()


func _on_dialogue_finished() -> void:
	if not _closing:
		return
	_ending = false
	_closing = false
	EventBus.demo_completed.emit()


func _play_closing() -> void:
	_closing = true
	DialogueManager.play(restored_dialogue)


func _has_cutscene() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	return tree.get_first_node_in_group(CUTSCENE_GROUP) != null
