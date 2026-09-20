extends Node

@export var terminal_id: StringName = &"core_hub"
@export var goal_system: StringName = &"door_habitat"
@export var goal_objective: StringName = &"obj_reach_greenhouse"


func _ready() -> void:
	EventBus.energy_changed.connect(_on_energy_changed)


func _on_energy_changed(
	changed_terminal: StringName, changed_system: StringName, powered: bool
) -> void:
	if not powered or changed_terminal != terminal_id or changed_system != goal_system:
		return
	GameState.set_objective(goal_objective)
