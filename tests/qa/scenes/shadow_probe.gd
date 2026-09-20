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
@export var disable_shadows: bool = false
@export var occluder_cull: int = -1
@export var shadow_tint: Color = Color(0, 0, 0, 0)
@export var shadow_smooth: float = -1.0
@export var hide_hud: bool = true

var _level: Node2D = null


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
		push_warning("shadow_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	_apply_cull()
	_tune_shadows(get_tree().root)
	if disable_shadows:
		_strip_shadows(get_tree().root)
	if hide_hud:
		_hide_hud()


func _process(_delta: float) -> void:
	_tune_shadows(get_tree().root)
	if disable_shadows:
		_strip_shadows(get_tree().root)
	if hide_hud:
		_hide_hud()


func _apply_cull() -> void:
	if occluder_cull < 0:
		return
	for layer: Node in _find_tilemaps(get_tree().root):
		var tile_set: TileSet = (layer as TileMapLayer).tile_set
		if tile_set == null:
			continue
		for source_index: int in range(tile_set.get_source_count()):
			var source: TileSetAtlasSource = tile_set.get_source(
				tile_set.get_source_id(source_index)
			) as TileSetAtlasSource
			if source == null:
				continue
			for tile_index: int in range(source.get_tiles_count()):
				var coords: Vector2i = source.get_tile_id(tile_index)
				var data: TileData = source.get_tile_data(coords, 0)
				var polygon: OccluderPolygon2D = data.get_occluder(0)
				if polygon != null:
					polygon.cull_mode = occluder_cull as OccluderPolygon2D.CullMode


func _find_tilemaps(node: Node) -> Array[Node]:
	var found: Array[Node] = []
	if node is TileMapLayer:
		found.append(node)
	for child: Node in node.get_children():
		found.append_array(_find_tilemaps(child))
	return found


func _tune_shadows(node: Node) -> void:
	if node is LightOccluder2D and occluder_cull >= 0:
		var shape: OccluderPolygon2D = (node as LightOccluder2D).occluder
		if shape != null:
			shape.cull_mode = occluder_cull as OccluderPolygon2D.CullMode
	if node is Light2D:
		var light: Light2D = node
		if shadow_tint.a > 0.0:
			light.shadow_color = shadow_tint
		if shadow_smooth >= 0.0:
			light.shadow_filter = Light2D.SHADOW_FILTER_PCF13
			light.shadow_filter_smooth = shadow_smooth
	for child: Node in node.get_children():
		_tune_shadows(child)


func _strip_shadows(node: Node) -> void:
	if node is Light2D:
		(node as Light2D).shadow_enabled = false
	for child: Node in node.get_children():
		_strip_shadows(child)


func _hide_hud() -> void:
	for layer: Node in get_tree().get_nodes_in_group(&"hud"):
		if layer is CanvasLayer:
			(layer as CanvasLayer).visible = false
		elif layer is CanvasItem:
			(layer as CanvasItem).visible = false


func _place_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		push_warning("shadow_probe: jogador ausente em %s" % level_scene)
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
