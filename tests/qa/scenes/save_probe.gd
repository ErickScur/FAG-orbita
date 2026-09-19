extends Node2D

const CHECKPOINT_ID: StringName = &"probe_dock_1"
const CHECKPOINT_SCENE: String = "res://tests/qa/scenes/save_probe.tscn"
const CHANGE_DAMAGE: int = 30
const CHANGE_CHARGE: float = 25.0
const CHANGE_REACTOR: float = -12.5

@onready var change_button: Button = %ChangeButton
@onready var save_button: Button = %SaveButton
@onready var reset_button: Button = %ResetButton
@onready var load_button: Button = %LoadButton
@onready var reactor_label: Label = %Reactor
@onready var integrity_label: Label = %Integrity
@onready var charge_label: Label = %Charge
@onready var logs_label: Label = %Logs
@onready var deaths_label: Label = %Deaths

var _changes: int = 0


func _ready() -> void:
	change_button.pressed.connect(_on_change)
	save_button.pressed.connect(_on_save)
	reset_button.pressed.connect(_on_reset)
	load_button.pressed.connect(_on_load)
	EventBus.integrity_changed.connect(_on_vitals_changed)
	EventBus.charge_changed.connect(_on_vitals_changed)
	EventBus.reactor_changed.connect(_on_reactor_changed)
	_refresh()
	change_button.grab_focus()


func _on_change() -> void:
	_changes += 1
	if GameState.integrity > CHANGE_DAMAGE:
		GameState.apply_damage(CHANGE_DAMAGE)
	GameState.spend_charge(CHANGE_CHARGE)
	GameState.change_reactor(CHANGE_REACTOR)
	GameState.register_pickup(&"log", StringName("log_probe_%02d" % _changes))
	GameState.deaths += 1
	GameState.flags["secret_probe_01"] = true
	GameState.checkpoint = {"scene": CHECKPOINT_SCENE, "dock_id": String(CHECKPOINT_ID)}
	_refresh()


func _on_save() -> void:
	EventBus.checkpoint_reached.emit(CHECKPOINT_ID)


func _on_reset() -> void:
	GameState.new_game()
	_refresh()


func _on_load() -> void:
	SaveManager.load_game()
	_refresh()


func _on_vitals_changed(_current: Variant, _maximum: Variant) -> void:
	_refresh()


func _on_reactor_changed(_percent: float) -> void:
	_refresh()


func _refresh() -> void:
	reactor_label.text = "REATOR      %.1f%%" % GameState.reactor_percent
	integrity_label.text = "INTEGRIDADE %d" % GameState.integrity
	charge_label.text = "CARGA       %.0f" % GameState.charge
	logs_label.text = "LOGS        %d" % GameState.logs_collected.size()
	deaths_label.text = "MORTES      %d" % GameState.deaths
