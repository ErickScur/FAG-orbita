class_name Interactable
extends Area2D

signal interacted(actor: Node)

@export var prompt_text: String = "INTERAGIR"
@export var enabled: bool = true
@export var interaction_priority: int = 0


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_mask = 0


func interact(actor: Node) -> void:
	if not enabled:
		return
	interacted.emit(actor)


func set_enabled(value: bool) -> void:
	enabled = value


func set_prompt(text: String) -> void:
	prompt_text = text
