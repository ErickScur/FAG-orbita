extends Area2D

@export var tutorial_id: StringName = &""
@export var once: bool = true

var _fired: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _fired or tutorial_id == &"" or not body.is_in_group(&"player"):
		return
	_fired = once
	EventBus.tutorial_requested.emit(tutorial_id)
