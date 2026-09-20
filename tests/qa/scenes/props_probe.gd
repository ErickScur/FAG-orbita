extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"
const PLANT_FLAG_PREFIX: String = "plant_"
const ENTITY_GROUP_PREFIX: String = "entity:"
const PROP_SCENE: String = "res://scenes/world/log_object.tscn"

@export_file("*.tscn") var level_scene: String = "res://scenes/levels/core_hub.tscn"
@export var spawn_tile: Vector2i = Vector2i.ZERO
@export var start_charge: float = 100.0
@export var silenced_sequences: Array[StringName] = []
@export var terminal_id: StringName = &"core_hub"
@export var energy_state: Array[StringName] = []
@export var abilities: Array[StringName] = []
@export var grown_plants: Array[StringName] = []
@export var prop_columns: Dictionary = {}
@export var sealed_doors: Array[StringName] = []
@export var powered_entities: Array[StringName] = []
@export var gallery_origin: Vector2i = Vector2i(-1, -1)
@export var gallery_columns: Array[int] = []
@export var gallery_spacing: int = 2

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
		push_warning("props_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	_override_props()
	_seal_doors()
	_power_entities()
	_build_gallery()
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	_mount_status()


func _process(_delta: float) -> void:
	if _status == null:
		return
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return
	var body: Node2D = players[0] as Node2D
	var tile: Vector2i = Vector2i(body.global_position) / Balance.TILE_SIZE
	_status.text = "TILE %d,%d" % [tile.x, tile.y]


func _mount_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(8, 176)
	_status.add_theme_font_size_override("font_size", 16)
	layer.add_child(_status)


func _override_props() -> void:
	for key: Variant in prop_columns:
		var group := StringName(ENTITY_GROUP_PREFIX + String(key))
		for node: Node in get_tree().get_nodes_in_group(group):
			if node.has_method("set_prop_column"):
				node.call("set_prop_column", int(prop_columns[key]))


func _build_gallery() -> void:
	if gallery_columns.is_empty() or gallery_origin.x < 0:
		return
	if not ResourceLoader.exists(PROP_SCENE):
		push_warning("props_probe: cena de prop ausente em %s" % PROP_SCENE)
		return
	var packed: PackedScene = load(PROP_SCENE)
	for index: int in range(gallery_columns.size()):
		var prop: Node2D = packed.instantiate()
		prop.set("prop_column", gallery_columns[index])
		prop.set("enabled", false)
		prop.position = Vector2(
			float((gallery_origin.x + index * gallery_spacing) * Balance.TILE_SIZE)
			+ float(Balance.TILE_SIZE) * 0.5,
			float((gallery_origin.y + 1) * Balance.TILE_SIZE)
		)
		_level.add_child(prop)


func _power_entities() -> void:
	for entity_id: StringName in powered_entities:
		var group := StringName(ENTITY_GROUP_PREFIX + String(entity_id))
		for node: Node in get_tree().get_nodes_in_group(group):
			if node.has_method("set_powered_silent"):
				node.call("set_powered_silent", true)


func _seal_doors() -> void:
	for door_id: StringName in sealed_doors:
		var group := StringName(ENTITY_GROUP_PREFIX + String(door_id))
		for node: Node in get_tree().get_nodes_in_group(group):
			var door := node as Door
			if door == null:
				continue
			door.sealed = true
			door.set_powered_silent(false)


func _place_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		push_warning("props_probe: jogador ausente em %s" % level_scene)
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
