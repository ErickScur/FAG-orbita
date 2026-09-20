extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"

@export_file("*.tscn") var level_scene: String = ""
@export var spawn_tile: Vector2i = Vector2i.ZERO
@export var start_charge: float = 60.0
@export var silenced_sequences: Array[StringName] = []
@export var terminal_id: StringName = &""
@export var powered_systems: Array[StringName] = []
@export var unpowered_systems: Array[StringName] = []

var _level: Node2D = null
var _status: Label = null


func _ready() -> void:
	GameState.new_game()
	GameState.charge = start_charge
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	if not ResourceLoader.exists(level_scene):
		push_warning("dark_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	_power_systems()
	_mount_status()


func _process(_delta: float) -> void:
	if _status == null:
		return
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	var lamp_state: String = "?"
	if not players.is_empty() and players[0].has_method("is_flashlight_on"):
		lamp_state = "ON" if players[0].call("is_flashlight_on") else "OFF"
	_status.text = "CARGA %d  LANTERNA %s" % [roundi(GameState.charge), lamp_state]


func _power_systems() -> void:
	for system_id: StringName in powered_systems:
		EventBus.energy_changed.emit(terminal_id, system_id, true)
	for system_id: StringName in unpowered_systems:
		EventBus.energy_changed.emit(terminal_id, system_id, false)


func _mount_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(8, 176)
	_status.add_theme_font_size_override("font_size", 16)
	layer.add_child(_status)


func _place_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		push_warning("dark_probe: jogador ausente em %s" % level_scene)
		return
	var body: Node2D = players[0] as Node2D
	if body == null:
		return
	body.global_position = Vector2(
		float(spawn_tile.x * Balance.TILE_SIZE) + float(Balance.TILE_SIZE) * 0.5,
		float((spawn_tile.y + 1) * Balance.TILE_SIZE)
	)
	if body.has_method("snap_camera"):
		body.call("snap_camera")
