extends Node2D

const LEVEL_TRACK: StringName = &"core"
const EMPTY_TEXT: String = "—"

@onready var track_label: Label = %TrackLabel
@onready var moment_label: Label = %MomentLabel
@onready var layer_label: Label = %LayerLabel
@onready var chassis_button: Button = %ChassisButton
@onready var sector_button: Button = %SectorButton
@onready var critical_on_button: Button = %CriticalOnButton
@onready var critical_off_button: Button = %CriticalOffButton
@onready var orbit_button: Button = %OrbitButton


func _ready() -> void:
	GameState.new_game()
	AudioManager.play_music(LEVEL_TRACK, 0.0)
	chassis_button.pressed.connect(_on_chassis)
	sector_button.pressed.connect(_on_sector)
	critical_on_button.pressed.connect(_on_critical_on)
	critical_off_button.pressed.connect(_on_critical_off)
	orbit_button.pressed.connect(_on_orbit)
	EventBus.player_respawned.connect(_on_respawned)
	_refresh()
	chassis_button.grab_focus()


func _process(_delta: float) -> void:
	_refresh()


func _refresh() -> void:
	track_label.text = "TRILHA: %s" % _text(AudioManager.current_music())
	moment_label.text = "MOMENTO: %s" % _text(AudioManager.current_one_shot())
	layer_label.text = "CAMADA: %s" % _text(AudioManager.current_layer())


func _text(id: StringName) -> String:
	return EMPTY_TEXT if id == &"" else String(id)


func _on_chassis() -> void:
	EventBus.player_died.emit()


func _on_sector() -> void:
	EventBus.sector_restored.emit(&"greenhouse")


func _on_critical_on() -> void:
	EventBus.reactor_critical.emit(true)


func _on_critical_off() -> void:
	EventBus.reactor_critical.emit(false)


func _on_orbit() -> void:
	EventBus.game_over.emit(&"reactor")


func _on_respawned() -> void:
	chassis_button.grab_focus()
