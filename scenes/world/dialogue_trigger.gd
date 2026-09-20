extends Area2D

@export var trigger_id: StringName = &""
@export var dialogue_id: StringName = &""
@export var objective_id: StringName = &""
@export var flag_id: StringName = &""
@export var once: bool = true

var _fired: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _fired or not body.is_in_group(&"player"):
		return
	if once and _already_fired():
		_fired = true
		return
	_fired = once
	if once and trigger_id != &"":
		GameState.flags["trg_" + String(trigger_id)] = true
	if dialogue_id != &"":
		DialogueManager.play(dialogue_id)
	if objective_id != &"" and GameState.has_method("set_objective"):
		GameState.call("set_objective", objective_id)
	if flag_id != &"":
		GameState.flags[String(flag_id)] = true


func _already_fired() -> bool:
	if trigger_id == &"":
		return false
	return bool(GameState.flags.get("trg_" + String(trigger_id), false))
