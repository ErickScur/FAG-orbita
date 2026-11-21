class_name Interactable
extends Area2D

signal interacted(actor: Node)

@export var prompt_text: String = "INTERAGIR"
@export var enabled: bool = true
@export var interaction_priority: int = 0

var actionable: bool = true


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_mask = 0


static func pick(candidates: Array[Interactable], origin: Vector2) -> Interactable:
	var positions := PackedVector2Array()
	var enabled_flags := PackedInt32Array()
	var priorities := PackedInt32Array()
	for candidate: Interactable in candidates:
		positions.append(candidate.global_position)
		enabled_flags.append(1 if candidate.enabled else 0)
		priorities.append(candidate.pick_priority())
	var index: int = InteractionRules.pick_index(positions, enabled_flags, priorities, origin)
	if index < 0:
		return null
	return candidates[index]


func interact(actor: Node) -> void:
	if not is_actionable():
		return
	interacted.emit(actor)


func set_enabled(value: bool) -> void:
	enabled = value


func set_prompt(text: String) -> void:
	prompt_text = text


func set_actionable(value: bool) -> void:
	actionable = value


func is_actionable() -> bool:
	return enabled and actionable


func pick_priority() -> int:
	return InteractionRules.effective_priority(interaction_priority, actionable)


func prompt_with(glyph: String) -> String:
	return InteractionRules.prompt(glyph, prompt_text, actionable)
