class_name StaticField
extends Node2D

const STATIC_PATH: String = "res://assets/sprites/fx/memory_static.png"
const ERASE_PATH: String = "res://assets/sprites/fx/memory_erase_sheet.png"
const STATIC_FRAME: Vector2i = Vector2i(32, 32)
const ERASE_FRAME: Vector2i = Vector2i(32, 16)
const STATIC_FRAMES: int = 4
const ERASE_FRAMES: int = 4
const STATIC_FPS: float = 12.0
const EDGE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)
const EDGE_GLITCH_COLOR: Color = Color("ff5fa8")
const EDGE_NOISE: int = 18
const EDGE_DEPTH: float = 10.0
const FIELD_ALPHA: float = 0.92

var front: EraseFront = null

var _frames: Array[Texture2D] = []
var _erase_frames: Array[AtlasTexture] = []
var _bursts: Array[Dictionary] = []
var _elapsed: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	z_index = 25
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var unshaded := CanvasItemMaterial.new()
	unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = unshaded
	_load_frames()


func _process(delta: float) -> void:
	_elapsed += delta
	var alive: Array[Dictionary] = []
	for burst: Dictionary in _bursts:
		burst["age"] = float(burst["age"]) + delta
		if float(burst["age"]) < Balance.MEMORY_ERASE_FX_TIME:
			alive.append(burst)
	_bursts = alive
	queue_redraw()


func burst(cells: Array[Vector2i]) -> void:
	for cell: Vector2i in cells:
		_bursts.append({"cell": cell, "age": 0.0, "flip": _rng.randf() < 0.5})


func clear_bursts() -> void:
	_bursts.clear()


func _draw() -> void:
	if front == null:
		return
	var area: Rect2 = front.swallowed_rect()
	if area.size.x > 0.0 and area.size.y > 0.0 and not _frames.is_empty():
		var index: int = int(_elapsed * STATIC_FPS) % _frames.size()
		draw_texture_rect(_frames[index], area, true, Color(1, 1, 1, FIELD_ALPHA))
		_draw_edge(area)
	_draw_bursts()


func _draw_edge(area: Rect2) -> void:
	match front.axis:
		EraseFront.AXIS_UP:
			draw_rect(Rect2(area.position.x, area.position.y - 1.0, area.size.x, 2.0), EDGE_COLOR)
			for i: int in range(EDGE_NOISE):
				var x: float = area.position.x + _rng.randf() * area.size.x
				var y: float = area.position.y - _rng.randf() * EDGE_DEPTH
				draw_rect(Rect2(floorf(x), floorf(y), 1.0, 1.0), _noise_color())
		EraseFront.AXIS_RIGHT:
			draw_rect(Rect2(area.end.x - 1.0, area.position.y, 2.0, area.size.y), EDGE_COLOR)
			for i: int in range(EDGE_NOISE):
				var y: float = area.position.y + _rng.randf() * area.size.y
				var x: float = area.end.x + _rng.randf() * EDGE_DEPTH
				draw_rect(Rect2(floorf(x), floorf(y), 1.0, 1.0), _noise_color())
		_:
			draw_rect(Rect2(area.position.x - 1.0, area.position.y, 2.0, area.size.y), EDGE_COLOR)
			for i: int in range(EDGE_NOISE):
				var y: float = area.position.y + _rng.randf() * area.size.y
				var x: float = area.position.x - _rng.randf() * EDGE_DEPTH
				draw_rect(Rect2(floorf(x), floorf(y), 1.0, 1.0), _noise_color())


func _draw_bursts() -> void:
	if _erase_frames.is_empty() or front == null:
		return
	var tile: float = float(front.tile)
	for burst: Dictionary in _bursts:
		var ratio: float = float(burst["age"]) / maxf(Balance.MEMORY_ERASE_FX_TIME, 0.01)
		var frame: int = clampi(int(ratio * float(ERASE_FRAMES)), 0, ERASE_FRAMES - 1)
		var cell: Vector2i = burst["cell"]
		var origin := Vector2(cell.x * tile, cell.y * tile)
		var size := Vector2(ERASE_FRAME)
		var rect := Rect2(origin, size)
		if bool(burst["flip"]):
			rect = Rect2(origin + Vector2(tile, 0.0), Vector2(-size.x, size.y))
		draw_texture_rect(_erase_frames[frame], rect, false)


func _noise_color() -> Color:
	if _rng.randf() < 0.2:
		return EDGE_GLITCH_COLOR
	var grey: float = _rng.randf_range(0.6, 1.0)
	return Color(grey, grey, grey, 1.0)


func _load_frames() -> void:
	var sheet: Texture2D = AssetResolver.texture(STATIC_PATH)
	if sheet != null:
		var image: Image = sheet.get_image()
		if image != null:
			for column: int in range(STATIC_FRAMES):
				var region := Rect2i(column * STATIC_FRAME.x, 0, STATIC_FRAME.x, STATIC_FRAME.y)
				_frames.append(ImageTexture.create_from_image(image.get_region(region)))
	for column: int in range(ERASE_FRAMES):
		var atlas: AtlasTexture = AssetResolver.atlas(ERASE_PATH, ERASE_FRAME, column, 0)
		if atlas != null:
			_erase_frames.append(atlas)
