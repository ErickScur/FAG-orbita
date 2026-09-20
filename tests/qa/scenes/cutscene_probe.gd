extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"
const POWERED_GROUP: StringName = &"powered"

@export_file("*.tscn") var level_scene: String = ""
@export var spawn_tile: Vector2i = Vector2i.ZERO
@export var sector_id: StringName = &"probe"
@export var trigger_frame: int = 30
@export var silenced_sequences: Array[StringName] = []

var _level: Node2D = null
var _status: Label = null
var _frames: int = 0
var _fired: bool = false
var _total: int = 0


func _ready() -> void:
	GameState.new_game()
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	if not ResourceLoader.exists(level_scene):
		push_warning("cutscene_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	_darken.call_deferred()
	_mount_status()


func _process(_delta: float) -> void:
	_frames += 1
	if not _fired and _frames >= trigger_frame:
		_fired = true
		EventBus.sector_restored.emit(sector_id)
	_refresh_status()


func _darken() -> void:
	_total = 0
	for node: Node in get_tree().get_nodes_in_group(POWERED_GROUP):
		if not node.has_method(&"set_powered_silent"):
			continue
		_total += 1
		node.call(&"set_powered_silent", node is SporeSwarm)


func _lit_count() -> int:
	var lit: int = 0
	for node: Node in get_tree().get_nodes_in_group(POWERED_GROUP):
		if not node.has_method(&"set_powered_silent"):
			continue
		if bool(node.get(&"powered")) != (node is SporeSwarm):
			lit += 1
	return lit


func _refresh_status() -> void:
	if _status == null:
		return
	var camera: Camera2D = get_viewport().get_camera_2d()
	var spot: Vector2 = Vector2.ZERO if camera == null else camera.global_position
	_status.text = "CAM %d,%d  LIGADOS %d/%d  CONTROLE %s" % [
		roundi(spot.x), roundi(spot.y), _lit_count(), _total, _control_state()
	]


func _control_state() -> String:
	var cutscene: Node = get_tree().get_first_node_in_group(&"sector_cutscene")
	if cutscene != null and bool(cutscene.call(&"is_running")):
		return "CUTSCENE"
	return "JOGADOR"


func _mount_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(8, 184)
	_status.add_theme_font_size_override("font_size", 16)
	layer.add_child(_status)


func _place_player() -> void:
	if spawn_tile == Vector2i.ZERO:
		return
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		push_warning("cutscene_probe: jogador ausente em %s" % level_scene)
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
