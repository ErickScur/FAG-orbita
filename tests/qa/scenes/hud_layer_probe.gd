extends Node2D

const DIALOGUE_FLAG_PREFIX: String = "dlg_"
const HUD_GROUP: StringName = &"hud"
const PLAYER_GROUP: StringName = &"player"
const LAMP_COLOR: Color = Color(1.0, 0.97, 0.82)
const LAMP_MARGIN: float = 2.0
const TEXT_MATCH: float = 0.12

@export_file("*.tscn") var level_scene: String = "res://scenes/levels/core_hub.tscn"
@export var spawn_tile: Vector2i = Vector2i.ZERO
@export var silenced_sequences: Array[StringName] = []

var _level: Node2D = null
var _lamps: Array[Sprite2D] = []
var _lamp_targets: Array[StringName] = []


func _ready() -> void:
	for sequence_id: StringName in silenced_sequences:
		GameState.flags[DIALOGUE_FLAG_PREFIX + String(sequence_id)] = true
	if not ResourceLoader.exists(level_scene):
		push_warning("hud_probe: fase ausente em %s" % level_scene)
		return
	var instance: Node = load(level_scene).instantiate()
	if not (instance is Node2D):
		instance.free()
		return
	_level = instance
	add_child(_level)
	_place_player()


func _process(_delta: float) -> void:
	for index: int in range(_lamps.size()):
		_follow(_lamps[index], _label_rect(_lamp_targets[index]))


func place_lamps() -> void:
	for target: StringName in [&"IntegrityLabel", &"ChargeLabel", &"ObjectiveLabel"]:
		var lamp := Sprite2D.new()
		lamp.name = "ProbeLamp%s" % target
		lamp.centered = false
		lamp.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
		lamp.texture = _lamp_texture()
		var glow := PointLight2D.new()
		glow.texture = lamp.texture
		glow.energy = 2.0
		glow.position = Vector2(8, 8)
		lamp.add_child(glow)
		add_child(lamp)
		_lamps.append(lamp)
		_lamp_targets.append(target)
	_process(0.0)


func clear_lamps() -> void:
	for lamp: Sprite2D in _lamps:
		lamp.queue_free()
	_lamps.clear()
	_lamp_targets.clear()


func teleport(column: int, row: int) -> void:
	spawn_tile = Vector2i(column, row)
	_place_player()


func lamp_under_hud() -> bool:
	for target: StringName in _lamp_targets:
		if label_pixels_over_lamp(target) <= 0:
			return false
	return not _lamp_targets.is_empty()


func layers_report() -> String:
	var found: Array[String] = []
	_collect_layers(get_tree().root, found)
	var text: String = ", ".join(found)
	print("HUDPROBE camadas: %s" % text)
	return text


func world_layer_above_hud() -> String:
	var hud: CanvasLayer = get_tree().get_first_node_in_group(HUD_GROUP) as CanvasLayer
	if hud == null:
		return "sem HUD"
	var offenders: Array[String] = []
	var all: Array[String] = []
	_collect_layers(get_tree().root, all)
	for entry: String in all:
		var parts: PackedStringArray = entry.split("=")
		if parts.size() != 2:
			continue
		var layer: int = int(parts[1])
		var is_hud: bool = parts[0] == _short_path(hud)
		if layer >= hud.layer and not is_hud and layer not in UiLayers.ABOVE_HUD:
			offenders.append(entry)
	if hud.layer != UiLayers.HUD:
		offenders.append("HUD=%d" % hud.layer)
	print("HUDPROBE mundo acima da HUD: %s" % str(offenders))
	return ", ".join(offenders)


func label_pixels_over_lamp(target: StringName) -> int:
	var rect: Rect2 = _label_rect(target)
	var label: Label = _hud_label(target)
	if label == null or rect.size == Vector2.ZERO:
		return -1
	RenderingServer.force_draw(false)
	var image: Image = get_viewport().get_texture().get_image()
	var color: Color = label.get_theme_color(&"font_color")
	var hits: int = 0
	for y: int in range(int(rect.position.y), int(rect.end.y)):
		for x: int in range(int(rect.position.x), int(rect.end.x)):
			if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
				continue
			var pixel: Color = image.get_pixel(x, y)
			if absf(pixel.r - color.r) + absf(pixel.g - color.g) + absf(pixel.b - color.b) \
					< TEXT_MATCH * 3.0:
				hits += 1
	print("HUDPROBE pixels de %s sobre a lâmpada: %d" % [target, hits])
	return hits


func _collect_layers(node: Node, into: Array[String]) -> void:
	for child: Node in node.get_children():
		if child is CanvasLayer and (child as CanvasLayer).visible:
			into.append("%s=%d" % [_short_path(child), (child as CanvasLayer).layer])
		_collect_layers(child, into)


func _short_path(node: Node) -> String:
	return String(get_tree().root.get_path_to(node))


func _hud_label(target: StringName) -> Label:
	var hud: Node = get_tree().get_first_node_in_group(HUD_GROUP)
	if hud == null:
		return null
	return hud.get_node_or_null("%" + String(target)) as Label


func _label_rect(target: StringName) -> Rect2:
	var label: Label = _hud_label(target)
	if label == null:
		return Rect2()
	return label.get_global_rect().grow(LAMP_MARGIN)


func _follow(lamp: Sprite2D, screen_rect: Rect2) -> void:
	if screen_rect.size == Vector2.ZERO:
		return
	var to_world: Transform2D = get_viewport().get_canvas_transform().affine_inverse()
	lamp.global_position = to_world * screen_rect.position
	lamp.scale = screen_rect.size / Vector2(lamp.texture.get_size())


func _lamp_texture() -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(LAMP_COLOR)
	return ImageTexture.create_from_image(image)


func _place_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group(PLAYER_GROUP)
	if players.is_empty():
		push_warning("hud_probe: jogador ausente em %s" % level_scene)
		return
	var body: Node2D = players[0] as Node2D
	body.global_position = Vector2(
		float(spawn_tile.x * Balance.TILE_SIZE) + float(Balance.TILE_SIZE) * 0.5,
		float((spawn_tile.y + 1) * Balance.TILE_SIZE)
	)
	if body.has_method("snap_camera"):
		body.call("snap_camera")
