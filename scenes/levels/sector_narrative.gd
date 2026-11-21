class_name SectorNarrative
extends Node

const CUTSCENE_GROUP: StringName = &"sector_cutscene"

@export var sector_id: StringName = &""
@export var ability_id: StringName = &""
@export var ability_dialogue: StringName = &""
@export var ability_tutorial: StringName = &""
@export var restored_dialogue: StringName = &""
@export_file("*.tscn") var next_scene: String = ""

var _ending: bool = false
var _closing: bool = false


func _ready() -> void:
	EventBus.ability_unlocked.connect(_on_ability_unlocked)
	EventBus.sector_restored.connect(_on_sector_restored)
	EventBus.sector_cutscene_finished.connect(_on_cutscene_finished)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func is_ending() -> bool:
	return _ending


func has_next_scene() -> bool:
	return not next_scene.is_empty()


func _on_ability_unlocked(unlocked_id: StringName) -> void:
	if ability_id == &"" or unlocked_id != ability_id:
		return
	DialogueManager.play(ability_dialogue)
	if ability_tutorial != &"":
		EventBus.tutorial_requested.emit(ability_tutorial)


func _on_sector_restored(restored_id: StringName) -> void:
	if _ending or restored_id != sector_id:
		return
	_ending = true
	if has_next_scene():
		GameState.checkpoint = {"scene": next_scene, "dock_id": ""}
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
	_finish()


func _play_closing() -> void:
	_closing = true
	if not _will_play(restored_dialogue):
		_finish()
		return
	DialogueManager.play(restored_dialogue)
	if not _is_blocking(restored_dialogue):
		_finish()


func _finish() -> void:
	_ending = false
	_closing = false
	if not has_next_scene():
		push_error("SectorNarrative: setor %s sem next_scene" % sector_id)
		return
	SceneManager.goto(next_scene)


func _will_play(dialogue_id: StringName) -> bool:
	if dialogue_id == &"":
		return false
	if not DialogueManager.sequences().has(dialogue_id):
		return false
	return not DialogueManager.has_played(dialogue_id)


func _is_blocking(dialogue_id: StringName) -> bool:
	var mode: StringName = DialogueData.sequence_mode(DialogueManager.sequences(), dialogue_id)
	return mode == DialogueData.MODE_BLOCKING


func _has_cutscene() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	return tree.get_first_node_in_group(CUTSCENE_GROUP) != null
