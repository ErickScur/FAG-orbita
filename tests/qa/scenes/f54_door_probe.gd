extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"
const ENTITY_GROUP_PREFIX: String = "entity:"

@export_file("*.tscn") var level_scene: String = "res://scenes/levels/core_hub.tscn"
@export var spawn_tile: Vector2i = Vector2i(66, 11)
@export var terminal_id: StringName = &"core_hub"
@export var energy_state: Array[StringName] = []
@export var silenced_sequences: Array[StringName] = []
@export var powered_entities: Array[StringName] = []
@export var sealed_entities: Array[StringName] = []
@export var open_entity: StringName = &""
@export var open_at_frame: int = -1
@export var clear_enemies: bool = true
@export var portal_tile: Vector2i = Vector2i(-1, -1)
@export var portal_frame: int = 5

var _frame: int = 0
var _level: Node2D = null


func _ready() -> void:
	GameState.new_game()
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	if not energy_state.is_empty():
		GameState.energy_states[terminal_id] = energy_state.duplicate()
	if not ResourceLoader.exists(level_scene):
		push_warning("f54_door_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	_power_entities()
	_seal_entities()
	if clear_enemies:
		_clear_enemies()
	_spawn_portal_preview()


func _process(_delta: float) -> void:
	_frame += 1
	if open_at_frame < 0 or _frame != open_at_frame:
		return
	for node: Node in _entity_nodes(open_entity):
		if node.has_method("set_powered"):
			node.call("set_powered", true)


func _spawn_portal_preview() -> void:
	if portal_tile.x < 0 or _level == null:
		return
	var atlas: AtlasTexture = AssetResolver.atlas(
		Door.SHEET_PATH, Door.FRAME_SIZE, portal_frame, 0
	)
	if atlas == null:
		push_warning("f54_door_probe: quadro %d ausente" % portal_frame)
		return
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.position = Vector2(
		float(portal_tile.x * Balance.TILE_SIZE) + float(Balance.TILE_SIZE) * 0.5,
		float((portal_tile.y + 1) * Balance.TILE_SIZE) - float(Door.FRAME_SIZE.y) * 0.5
	)
	_level.add_child(sprite)


func _entity_nodes(entity_id: StringName) -> Array[Node]:
	return get_tree().get_nodes_in_group(StringName(ENTITY_GROUP_PREFIX + String(entity_id)))


func _power_entities() -> void:
	for entity_id: StringName in powered_entities:
		for node: Node in _entity_nodes(entity_id):
			if node.has_method("set_powered_silent"):
				node.call("set_powered_silent", true)


func _seal_entities() -> void:
	for entity_id: StringName in sealed_entities:
		for node: Node in _entity_nodes(entity_id):
			var door := node as Door
			if door == null:
				continue
			door.sealed = true
			door.set_powered_silent(false)


func _clear_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemy"):
		node.queue_free()


func _place_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		push_warning("f54_door_probe: jogador ausente em %s" % level_scene)
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
