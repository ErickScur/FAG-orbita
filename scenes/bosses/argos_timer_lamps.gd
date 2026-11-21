class_name ArgosTimerLamps
extends Node2D

const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const LAMP_SIZE: float = 6.0
const SOCKET_SIZE: float = 10.0
const PLATE_PAD: float = 3.0
const SOCKET_COLOR: Color = Color("1a0d0a")
const SOCKET_EDGE: Color = Color("6a4232")
const PLATE_COLOR: Color = Color("120806")
const PLATE_EDGE: Color = Color("ffb46a")
const LAMP_ON: Color = Color("ffe8c8")
const LAMP_RIM: Color = Color("ffb46a")
const LAMP_OFF: Color = Color("3a1a16")
const LAMP_URGENT: Color = Color("ff3a2a")
const LAMP_FLASH: Color = Color("ffffff")
const GLOW_COLOR: Color = Color(1.0, 0.62, 0.3, 0.75)
const GLOW_URGENT: Color = Color(1.0, 0.2, 0.12, 0.9)
const GLOW_DIAMETER: float = 22.0
const FLASH_TIME: float = 0.35
const BLINK_HZ: float = 2.5

var _points: Array[Vector2] = []
var _glows: Array[Sprite2D] = []
var _plate: bool = false
var _lit: int = 0
var _urgent: bool = false
var _clock: float = 0.0
var _flash: Array[float] = []


func _ready() -> void:
	material = HeatZone.unshaded_material()
	(material as CanvasItemMaterial).blend_mode = CanvasItemMaterial.BLEND_MODE_MIX


func _process(delta: float) -> void:
	_clock += delta
	var flashing: bool = false
	for index: int in range(_flash.size()):
		if _flash[index] > 0.0:
			_flash[index] = maxf(0.0, _flash[index] - delta)
			flashing = true
	_refresh_glows()
	if flashing or _urgent:
		queue_redraw()


func configure(points: Array[Vector2], with_plate: bool) -> void:
	_points = points.duplicate()
	_plate = with_plate
	_flash.clear()
	_flash.resize(_points.size())
	_flash.fill(0.0)
	for glow: Sprite2D in _glows:
		glow.queue_free()
	_glows.clear()
	var texture: Texture2D = AssetResolver.texture(LIGHT_TEXTURE)
	for point: Vector2 in _points:
		var glow := Sprite2D.new()
		glow.texture = texture
		glow.position = point
		glow.material = HeatZone.unshaded_material()
		glow.z_index = -1
		if texture != null and texture.get_width() > 0:
			glow.scale = Vector2.ONE * GLOW_DIAMETER / float(texture.get_width())
		add_child(glow)
		_glows.append(glow)
	_lit = _points.size()
	_refresh_glows()
	queue_redraw()


func set_lit(count: int, animated: bool) -> void:
	var clamped: int = clampi(count, 0, _points.size())
	if clamped == _lit:
		return
	if animated and clamped < _lit:
		for index: int in range(clamped, _lit):
			_flash[index] = FLASH_TIME
	_lit = clamped
	_refresh_glows()
	queue_redraw()


func set_urgent(urgent: bool) -> void:
	if urgent == _urgent:
		return
	_urgent = urgent
	_refresh_glows()
	queue_redraw()


func lit_count() -> int:
	return _lit


func is_urgent() -> bool:
	return _urgent


func lamp_count() -> int:
	return _points.size()


func lamp_points() -> Array[Vector2]:
	return _points.duplicate()


func lamp_color(index: int) -> Color:
	if index < 0 or index >= _points.size():
		return LAMP_OFF
	if _flash[index] > 0.0:
		return LAMP_FLASH
	if index >= _lit:
		return LAMP_OFF
	if _urgent:
		return LAMP_URGENT if _blink_on() else LAMP_OFF
	return LAMP_ON


static func horseshoe(count: int, radius: float, spread: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if count <= 0:
		return points
	var start: float = PI * 0.5 + spread * 0.5
	for index: int in range(count):
		var t: float = 0.5 if count == 1 else float(index) / float(count - 1)
		var angle: float = start - spread * t
		points.append((Vector2.RIGHT.rotated(angle) * radius).round())
	return points


static func row(count: int, spacing: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var width: float = spacing * float(maxi(0, count - 1))
	for index: int in range(count):
		points.append(Vector2(-width * 0.5 + spacing * float(index), 0.0).round())
	return points


func _draw() -> void:
	if _points.is_empty():
		return
	if _plate:
		var bounds := Rect2(_points[0], Vector2.ZERO)
		for point: Vector2 in _points:
			bounds = bounds.expand(point)
		var plate: Rect2 = bounds.grow(SOCKET_SIZE * 0.5 + PLATE_PAD)
		draw_rect(plate.grow(1.0), PLATE_EDGE)
		draw_rect(plate, PLATE_COLOR)
	for index: int in range(_points.size()):
		var center: Vector2 = _points[index]
		var socket := Rect2(center - Vector2.ONE * SOCKET_SIZE * 0.5, Vector2.ONE * SOCKET_SIZE)
		draw_rect(socket, SOCKET_EDGE)
		draw_rect(socket.grow(-1.0), SOCKET_COLOR)
		var lamp := Rect2(center - Vector2.ONE * LAMP_SIZE * 0.5, Vector2.ONE * LAMP_SIZE)
		var color: Color = lamp_color(index)
		if color != LAMP_OFF and color != LAMP_FLASH and not _urgent:
			draw_rect(lamp, LAMP_RIM)
			draw_rect(lamp.grow(-1.0), color)
		else:
			draw_rect(lamp, color)


func _refresh_glows() -> void:
	for index: int in range(_glows.size()):
		var glow: Sprite2D = _glows[index]
		var color: Color = lamp_color(index)
		glow.visible = color != LAMP_OFF
		if color == LAMP_FLASH:
			glow.modulate = Color(1.0, 1.0, 1.0, _flash[index] / FLASH_TIME)
		elif _urgent:
			glow.modulate = GLOW_URGENT
		else:
			glow.modulate = GLOW_COLOR


func _blink_on() -> bool:
	return fmod(_clock * BLINK_HZ, 1.0) < 0.6
