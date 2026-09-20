extends Node

const STEP_ROUTE: int = 3
const STEP_CLAWS: int = 6
const STEP_DOOR: int = 8

@export var terminal_id: StringName = &"greenhouse"
@export var sector_id: StringName = &"greenhouse"
@export var lift_system: StringName = &"lift_platform"
@export var plant_system: StringName = &"grow_light"
@export var door_system: StringName = &"node_door"
@export var lift_objective: StringName = &"obj_gh_ride_lift"
@export var plant_objective: StringName = &"obj_gh_climb_plant"
@export var claws_objective: StringName = &"obj_gh_climb_wall"
@export var door_objective: StringName = &"obj_restore_gh"
@export var claws_dialogue: StringName = &"gh_claws"
@export var restored_dialogue: StringName = &"gh_restored"
@export var ambient_path: NodePath = ^"../CanvasModulate"

var _step: int = 0
var _ending: bool = false

@onready var _ambient: CanvasModulate = get_node_or_null(ambient_path) as CanvasModulate


func _ready() -> void:
	EventBus.energy_changed.connect(_on_energy_changed)
	EventBus.ability_unlocked.connect(_on_ability_unlocked)
	EventBus.sector_restored.connect(_on_sector_restored)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)


func current_step() -> int:
	return _step


func is_ending() -> bool:
	return _ending


func restored_color() -> Color:
	var level: Node = get_parent()
	if level == null or not level.has_method(&"meta_color"):
		return Balance.LAMP_COLOR
	return level.call(&"meta_color", "ambient_restored")


func _on_energy_changed(
	changed_terminal: StringName, changed_system: StringName, powered: bool
) -> void:
	if not powered or changed_terminal != terminal_id:
		return
	if changed_system == lift_system:
		_advance(STEP_ROUTE, lift_objective, _step == 0)
	elif changed_system == plant_system:
		_advance(STEP_ROUTE, plant_objective, _step == 0)
	elif changed_system == door_system:
		_advance(STEP_DOOR, door_objective, _step >= STEP_CLAWS)


func _on_ability_unlocked(ability_id: StringName) -> void:
	if ability_id != ClimbLogic.ABILITY_ID:
		return
	_advance(STEP_CLAWS, claws_objective, true)
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


func _advance(step: int, objective: StringName, allowed: bool) -> void:
	if not allowed or step <= _step:
		return
	_step = step
	GameState.set_objective(objective)


func _light_the_sector() -> void:
	if _ambient == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(_ambient, ^"color", restored_color(), Balance.LIGHT_FADE_TIME)
