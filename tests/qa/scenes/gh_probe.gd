extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"
const PLANT_FLAG_PREFIX: String = "plant_"

@export_file("*.tscn") var level_scene: String = "res://scenes/levels/greenhouse.tscn"
@export var spawn_tile: Vector2i = Vector2i.ZERO
@export var start_charge: float = 100.0
@export var silenced_sequences: Array[StringName] = [&"gh_enter"]
@export var terminal_id: StringName = &"greenhouse"
@export var energy_state: Array[StringName] = []
@export var abilities: Array[StringName] = []
@export var grown_plants: Array[StringName] = []
@export var show_status: bool = true

var _level: Node2D = null
var _status: Label = null


func _ready() -> void:
	GameState.new_game()
	GameState.charge = start_charge
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	for plant_id: StringName in grown_plants:
		GameState.flags[PLANT_FLAG_PREFIX + String(plant_id)] = true
	for ability_id: StringName in abilities:
		GameState.unlock_ability(ability_id)
	if not energy_state.is_empty():
		GameState.energy_states[terminal_id] = energy_state.duplicate()
	if not ResourceLoader.exists(level_scene):
		push_warning("gh_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	if show_status:
		_mount_status()


func _process(_delta: float) -> void:
	if _status == null:
		return
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var body: Node2D = players[0] as Node2D
	var tile: Vector2i = Vector2i(body.global_position) / Balance.TILE_SIZE
	_status.text = "TILE %d,%d  CARGA %d" % [tile.x, tile.y, roundi(GameState.charge)]


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
		push_warning("gh_probe: jogador ausente em %s" % level_scene)
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
