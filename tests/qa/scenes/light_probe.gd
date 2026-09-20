extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"

@export_file("*.tscn") var level_scene: String = "res://scenes/levels/greenhouse.tscn"
@export var spawn_tile: Vector2i = Vector2i.ZERO
@export var start_charge: float = 100.0
@export var silenced_sequences: Array[StringName] = [&"gh_enter"]
@export var terminal_id: StringName = &"greenhouse"
@export var energy_state: Array[StringName] = []
@export var abilities: Array[StringName] = []
@export var disable_magnetic_glow: bool = false
@export var report_every: int = 30

var _level: Node2D = null
var _status: Label = null
var _frames: int = 0


func _ready() -> void:
	GameState.new_game()
	GameState.charge = start_charge
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	for ability_id: StringName in abilities:
		GameState.unlock_ability(ability_id)
	if not energy_state.is_empty():
		GameState.energy_states[terminal_id] = energy_state.duplicate()
	if not ResourceLoader.exists(level_scene):
		push_warning("light_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	if disable_magnetic_glow:
		call_deferred("_kill_magnetic_glow")
	_mount_status()


func _process(_delta: float) -> void:
	_frames += 1
	var body: Node2D = _player()
	if body == null:
		return
	var tile: Vector2i = Vector2i(body.global_position) / Balance.TILE_SIZE
	if _status != null:
		_status.text = "TILE %d,%d  CARGA %d" % [tile.x, tile.y, roundi(GameState.charge)]
	if report_every > 0 and _frames % report_every == 0:
		print(_report(body))


func _player() -> Node2D:
	var players: Array[Node] = get_tree().get_nodes_in_group(&"player")
	if players.is_empty():
		return null
	return players[0] as Node2D


func _report(body: Node2D) -> String:
	var lights: Array[PointLight2D] = _lights()
	var near: int = 0
	var visible_count: int = 0
	var camera_rect := Rect2(body.global_position - Vector2(192, 108), Vector2(384, 216))
	var player_rect := Rect2(body.global_position - Vector2(16, 32), Vector2(32, 48))
	for light: PointLight2D in lights:
		var rect: Rect2 = _light_rect(light)
		if rect.intersects(camera_rect):
			visible_count += 1
		if rect.intersects(player_rect):
			near += 1
	var flashlight: PointLight2D = body.get_node_or_null("Flashlight") as PointLight2D
	var lamp_text: String = "sem lanterna"
	if flashlight != null:
		lamp_text = "lanterna energy=%.2f scale=%.3f pos=%s" % [
			flashlight.energy, flashlight.texture_scale, str(flashlight.global_position)
		]
	return "LIGHTPROBE tile=%d,%d total=%d na_camera=%d no_jogador=%d %s" % [
		int(body.global_position.x) / Balance.TILE_SIZE,
		int(body.global_position.y) / Balance.TILE_SIZE,
		lights.size(),
		visible_count,
		near,
		lamp_text
	]


func _lights() -> Array[PointLight2D]:
	var found: Array[PointLight2D] = []
	_collect_lights(self, found)
	return found


func _collect_lights(node: Node, into: Array[PointLight2D]) -> void:
	for child: Node in node.get_children():
		if child is PointLight2D and (child as PointLight2D).enabled:
			if (child as PointLight2D).energy > 0.001:
				into.append(child as PointLight2D)
		_collect_lights(child, into)


func _light_rect(light: PointLight2D) -> Rect2:
	var size: float = LightMath.TEXTURE_SIZE * light.texture_scale
	return Rect2(light.global_position - Vector2(size, size) * 0.5, Vector2(size, size))


func _kill_magnetic_glow() -> void:
	for node: Node in get_tree().get_nodes_in_group(ClimbLogic.MAGNETIC_GROUP):
		var glow: PointLight2D = node.get_node_or_null("Glow") as PointLight2D
		if glow != null:
			glow.enabled = false


func _mount_status() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(8, 176)
	_status.add_theme_font_size_override("font_size", 16)
	layer.add_child(_status)


func _place_player() -> void:
	var body: Node2D = _player()
	if body == null:
		push_warning("light_probe: jogador ausente em %s" % level_scene)
		return
	body.global_position = Vector2(
		float(spawn_tile.x * Balance.TILE_SIZE) + float(Balance.TILE_SIZE) * 0.5,
		float((spawn_tile.y + 1) * Balance.TILE_SIZE)
	)
	if body.has_method("snap_camera"):
		body.call("snap_camera")
