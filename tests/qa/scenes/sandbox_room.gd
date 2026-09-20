class_name SandboxRoom
extends Node2D

const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const WORLD_LAYER: int = 1
const HAZARD_LAYER: int = 16
const BACKGROUND_COLOR: Color = Color("#10161c")
const SOLID_COLOR: Color = Color("#2f4f5a")
const SOLID_TOP_COLOR: Color = Color("#4a7284")
const HUD_MARGIN: float = 6.0

var solid_color: Color = SOLID_COLOR
var player: Mu7 = null
var overlay: CanvasLayer = null

var _room: Rect2i = Rect2i()


func build_room(rect: Rect2i) -> void:
	_room = rect
	var background: Polygon2D = _make_panel(
		Vector2(rect.size), BACKGROUND_COLOR, Vector2(rect.position) + Vector2(rect.size) * 0.5
	)
	background.z_index = -10
	add_child(background)
	overlay = CanvasLayer.new()
	overlay.name = "Overlay"
	add_child(overlay)


func add_solid(rect: Rect2, occluder: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = WORLD_LAYER
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	body.add_child(shape)
	body.add_child(_make_panel(rect.size, solid_color, Vector2.ZERO))
	body.add_child(
		_make_panel(
			Vector2(rect.size.x, 2.0), SOLID_TOP_COLOR, Vector2(0.0, (-rect.size.y + 2.0) * 0.5)
		)
	)
	if occluder:
		body.add_child(_make_occluder(rect.size))
	add_child(body)
	return body


func add_hazard(rect: Rect2, contact: int, per_second: float, knockback: bool) -> DamageArea:
	var area := DamageArea.new()
	area.collision_layer = HAZARD_LAYER
	area.position = rect.position + rect.size * 0.5
	area.contact_damage = contact
	area.damage_per_second = per_second
	area.knockback = knockback
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	area.add_child(shape)
	add_child(area)
	return area


func spawn_player(at: Vector2) -> Mu7:
	if not ResourceLoader.exists(PLAYER_SCENE):
		push_warning("SandboxRoom: cena do jogador ausente")
		return null
	var scene: PackedScene = load(PLAYER_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is Mu7):
		instance.free()
		return null
	player = instance
	player.position = at
	add_child(player)
	player.set_camera_limits(_room)
	player.snap_camera()
	return player


func add_label(anchor: Control.LayoutPreset, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(label)
	label.set_anchors_and_offsets_preset(anchor, Control.PRESET_MODE_MINSIZE, int(HUD_MARGIN))
	return label


func _make_panel(size: Vector2, color: Color, offset: Vector2) -> Polygon2D:
	var panel := Polygon2D.new()
	var half: Vector2 = size * 0.5
	panel.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	panel.color = color
	panel.position = offset
	return panel


func _make_occluder(size: Vector2) -> LightOccluder2D:
	var occluder := LightOccluder2D.new()
	var polygon := OccluderPolygon2D.new()
	var half: Vector2 = size * 0.5
	polygon.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	occluder.occluder = polygon
	return occluder
