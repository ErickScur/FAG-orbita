extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"
const STATUS_LAYER: int = 90
const STATUS_POSITION: Vector2 = Vector2(8, 8)

@export_file("*.tscn") var level_scene: String = "res://scenes/levels/greenhouse.tscn"
@export var spawn_tile: Vector2i = Vector2i(18, 61)
@export var silenced_sequences: Array[StringName] = [&"gh_enter"]

var _level: Node2D = null
var _status: Label = null


func _ready() -> void:
	GameState.new_game()
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	if not ResourceLoader.exists(level_scene):
		push_warning("sr3_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	_mount_status()


func _process(_delta: float) -> void:
	if _status == null:
		return
	var lines: PackedStringArray = []
	var index: int = 0
	for node: Node in get_tree().get_nodes_in_group(&"enemy"):
		var enemy: Sr3 = node as Sr3
		if enemy == null:
			continue
		index += 1
		lines.append(_describe(index, enemy))
	if lines.is_empty():
		lines.append("NENHUM SR-3 NA FASE")
	_status.text = "\n".join(lines)


func _describe(index: int, enemy: Sr3) -> String:
	var sprite: AnimatedSprite2D = enemy.get_node_or_null("AnimatedSprite2D")
	var tile: Vector2i = Vector2i(enemy.global_position) / Balance.TILE_SIZE
	var animation: String = "SEM FOLHA"
	var frame: int = -1
	var playing: String = "NAO"
	if sprite != null and sprite.sprite_frames != null:
		animation = String(sprite.animation)
		frame = sprite.frame
		playing = "SIM" if sprite.is_playing() else "NAO"
	return "SR3 %d T %d,%d DIR %d %s Q%d TOCA %s" % [
		index, tile.x, tile.y, enemy.dir, animation, frame, playing
	]


func _mount_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = STATUS_LAYER
	add_child(layer)
	_status = Label.new()
	_status.position = STATUS_POSITION
	_status.add_theme_font_size_override("font_size", 16)
	layer.add_child(_status)


func _place_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		push_warning("sr3_probe: jogador ausente em %s" % level_scene)
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
