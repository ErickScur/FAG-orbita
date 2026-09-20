class_name DamageArea
extends Area2D

@export var contact_damage: int = 0
@export var damage_per_second: float = 0.0
@export var knockback: bool = true
@export var status_id: StringName = &""
@export var status_duration: float = 0.0
@export var active: bool = true


func _ready() -> void:
	monitoring = false
	monitorable = true
	collision_mask = 0


func set_active(value: bool) -> void:
	active = value


func hurts_on_contact() -> bool:
	return active and contact_damage > 0


func hurts_over_time() -> bool:
	return active and damage_per_second > 0.0


func notify_status() -> void:
	if status_id == &"" or status_duration <= 0.0:
		return
	EventBus.status_applied.emit(status_id, status_duration)
