extends Node2D

const SAMPLE_PLAY_TIME: float = 754.2
const SAMPLE_LOGS: int = 6
const SAMPLE_RESEARCH: int = 4
const SAMPLE_DEATHS: int = 2
const SAMPLE_SECRET: String = "secret_greenhouse_01"

@onready var death_button: Button = %DeathButton
@onready var game_over_button: Button = %GameOverButton
@onready var demo_button: Button = %DemoButton
@onready var status_label: Label = %Status


func _ready() -> void:
	_seed_state()
	death_button.pressed.connect(_on_death)
	game_over_button.pressed.connect(_on_game_over)
	demo_button.pressed.connect(_on_demo)
	EventBus.player_respawned.connect(_on_respawned)
	_refresh()
	death_button.grab_focus()


func _seed_state() -> void:
	GameState.new_game()
	for index in range(SAMPLE_LOGS):
		GameState.register_pickup(&"log", StringName("log_probe_%02d" % index))
	for index in range(SAMPLE_RESEARCH):
		GameState.register_pickup(&"research", StringName("res_probe_%02d" % index))
	GameState.deaths = SAMPLE_DEATHS
	GameState.play_time = SAMPLE_PLAY_TIME
	GameState.flags[SAMPLE_SECRET] = true


func _refresh() -> void:
	status_label.text = "LOGS %d/%d  DADOS %d/%d  MORTES %d  TEMPO %s" % [
		GameState.logs_collected.size(),
		Balance.LOGS_TOTAL,
		GameState.research_collected.size(),
		Balance.RESEARCH_TOTAL,
		GameState.deaths,
		RunStats.format_time(GameState.play_time),
	]


func _on_death() -> void:
	EventBus.player_died.emit()


func _on_game_over() -> void:
	EventBus.game_over.emit(&"reactor")


func _on_demo() -> void:
	EventBus.demo_completed.emit()


func _on_respawned() -> void:
	_refresh()
	death_button.grab_focus()
