extends SceneTree

const TILE: int = 16
const COLUMNS: int = 8
const ROWS: int = 4
const KEY_TOLERANCE: float = 0.22
const BACKGROUND_TOLERANCE: float = 0.28
const DILATE_PASSES: int = 12
const HIGHLIGHT_KNEE: float = 0.72
const UNLIT_TINT: Color = Color(0.90, 0.97, 1.12, 1.0)
const UNLIT_DIM: float = 0.32
const DEFAULT_MAGENTA_FLOOR: float = 0.45
const CORE_MASKS: Array = [
	{"cell": "0:0"},
	{"cell": "0:6"},
	{"cell": "0:6", "rotate": 90},
	{"cell": "0:4"},
	{"cell": "0:6", "flip_v": true},
	{"cell": "0:3"},
	{"cell": "0:4", "flip_v": true},
	{"cell": "0:1", "rotate": 270},
	{"cell": "0:6", "rotate": 270},
	{"cell": "0:5"},
	{"cell": "0:3", "rotate": 90},
	{"cell": "0:2"},
	{"cell": "0:5", "flip_v": true},
	{"cell": "0:1", "rotate": 90},
	{"cell": "0:1"},
	{"cell": "1:4"},
]
const CORE_EXTRAS: Array = [
	{"cell": "1:6", "mode": "top"},
	{"cell": "2:0"},
	{"cell": "2:7"},
	{"cell": "2:6"},
	{"cell": "3:0"},
	{"cell": "3:1"},
	{"cell": "3:5", "cut_background": true},
	{"cell": "1:7"},
	{"cell": "3:6"},
	{"cell": "3:5", "cut_background": true, "unlit": true},
	{"cell": "2:4"},
	{"cell": "2:5"},
	{"cell": "3:2"},
	{"cell": "3:3"},
	{"cell": "3:4"},
	{"cell": "3:7"},
]
const GREENHOUSE_BASE: Dictionary = {"cell": "0:1", "sub": [0.14, 0.52, 0.86, 0.90]}
const GREENHOUSE_EDGES: Dictionary = {
	"up": {"cell": "0:1", "span": 0.46},
	"down": {"cell": "0:2", "span": 0.44},
	"left": {"cell": "0:3", "span": 0.34},
	"right": {"cell": "0:4", "span": 0.34},
}
const GREENHOUSE_EXTRAS: Array = [
	{"cell": "1:0", "mode": "top"},
	{"cell": "4:1"},
	{"cell": "3:1"},
	{"cell": "4:0"},
	{"cell": "4:7"},
	{"cell": "2:1"},
	{"cell": "1:6", "mode": "top"},
	{"cell": "4:8"},
	{"cell": "4:8"},
	{"cell": "1:7", "mode": "top"},
	{"cell": "2:0"},
	{"cell": "2:3"},
	{"cell": "4:3"},
	{"cell": "4:5"},
	{"cell": "1:2", "mode": "top"},
	{"cell": "1:9", "mode": "top"},
]

var _image: Image = null
var _key: Color = Color.MAGENTA
var _magenta_floor: float = DEFAULT_MAGENTA_FLOOR
var _boxes: Array = []


func _initialize() -> void:
	var options: Dictionary = _options()
	var source: String = String(options.get("in", ""))
	var target: String = String(options.get("out", ""))
	var kind: String = String(options.get("kind", ""))
	if source.is_empty() or target.is_empty() or kind.is_empty():
		print("uso: --in=<png> --out=<png> --kind=core|greenhouse [--gain=1.0] [--magenta=0.45]")
		quit(2)
		return
	_image = Image.load_from_file(source)
	if _image == null:
		print("entrada inválida: %s" % source)
		quit(2)
		return
	_image.convert(Image.FORMAT_RGBA8)
	_magenta_floor = float(options.get("magenta", str(DEFAULT_MAGENTA_FLOOR)))
	_key = _image.get_pixel(0, 0)
	_dilate_key()
	_boxes = _detect_grid()
	var gain: float = float(options.get("gain", "1.0"))
	var sheet := Image.create(COLUMNS * TILE, ROWS * TILE, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	var masks: Array = _mask_tiles(kind)
	for mask: int in range(masks.size()):
		_place(sheet, masks[mask], mask % COLUMNS, mask / COLUMNS)
	var extras: Array = CORE_EXTRAS if kind == "core" else GREENHOUSE_EXTRAS
	for index: int in range(extras.size()):
		_place(sheet, _render(extras[index]), index % COLUMNS, 2 + index / COLUMNS)
	if not is_equal_approx(gain, 1.0):
		_apply_gain(sheet, gain)
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	if sheet.save_png(target) != OK:
		print("falha ao gravar %s" % target)
		quit(3)
		return
	print("OK %s %dx%d luma_solidos=%.3f" % [
		target, sheet.get_width(), sheet.get_height(), _solid_luma(sheet)
	])
	quit(0)


func _mask_tiles(kind: String) -> Array:
	var tiles: Array = []
	if kind == "core":
		for entry: Dictionary in CORE_MASKS:
			tiles.append(_render(entry))
		return tiles
	for mask: int in range(16):
		tiles.append(_compose(mask))
	return tiles


func _compose(mask: int) -> Image:
	var tile: Image = _render(GREENHOUSE_BASE)
	if mask & 1 == 0:
		_blit_strip(tile, "up")
	if mask & 4 == 0:
		_blit_strip(tile, "down")
	if mask & 8 == 0:
		_blit_strip(tile, "left")
	if mask & 2 == 0:
		_blit_strip(tile, "right")
	return tile


func _blit_strip(tile: Image, side: String) -> void:
	var entry: Dictionary = GREENHOUSE_EDGES[side]
	var span: float = float(entry["span"])
	var sub: Array = []
	var at := Vector2i.ZERO
	match side:
		"up":
			sub = [0.0, 0.0, 1.0, span]
		"down":
			sub = [0.0, 1.0 - span, 1.0, 1.0]
			at = Vector2i(0, TILE - int(round(TILE * span)))
		"left":
			sub = [0.0, 0.0, span, 1.0]
		"right":
			sub = [1.0 - span, 0.0, 1.0, 1.0]
			at = Vector2i(TILE - int(round(TILE * span)), 0)
	var piece: Dictionary = {"cell": entry["cell"], "sub": sub}
	var horizontal: bool = side == "up" or side == "down"
	var width: int = TILE if horizontal else int(round(TILE * span))
	var height: int = int(round(TILE * span)) if horizontal else TILE
	var strip: Image = _cell(piece, width, height)
	tile.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), at)


func _render(entry: Dictionary) -> Image:
	var mode: String = String(entry.get("mode", "fill"))
	var tile: Image
	if mode == "top":
		tile = Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
		tile.fill(Color(0, 0, 0, 0))
		var box: Rect2i = _box(entry)
		var height: int = maxi(1, int(round(float(TILE * box.size.y) / float(box.size.x))))
		var piece: Image = _cell(entry, TILE, mini(height, TILE))
		tile.blit_rect(piece, Rect2i(Vector2i.ZERO, piece.get_size()), Vector2i.ZERO)
	else:
		tile = _cell(entry, TILE, TILE)
	if bool(entry.get("unlit", false)):
		_make_unlit(tile)
	if bool(entry.get("flip_h", false)):
		tile.flip_x()
	if bool(entry.get("flip_v", false)):
		tile.flip_y()
	var rotate: int = int(entry.get("rotate", 0))
	if rotate != 0:
		tile = _rotated(tile, rotate)
	return tile


func _rotated(tile: Image, degrees: int) -> Image:
	var result := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	for y: int in range(TILE):
		for x: int in range(TILE):
			var source := Vector2i(x, y)
			match degrees:
				90:
					source = Vector2i(y, TILE - 1 - x)
				180:
					source = Vector2i(TILE - 1 - x, TILE - 1 - y)
				270:
					source = Vector2i(TILE - 1 - y, x)
			result.set_pixel(x, y, tile.get_pixel(source.x, source.y))
	return result


func _cell(entry: Dictionary, width: int, height: int) -> Image:
	var box: Rect2i = _box(entry)
	var sub: Array = entry.get("sub", [0.0, 0.0, 1.0, 1.0])
	var region := Rect2i(
		box.position.x + int(float(box.size.x) * float(sub[0])),
		box.position.y + int(float(box.size.y) * float(sub[1])),
		maxi(1, int(float(box.size.x) * (float(sub[2]) - float(sub[0])))),
		maxi(1, int(float(box.size.y) * (float(sub[3]) - float(sub[1]))))
	)
	var cut: Image = _image.get_region(region)
	if bool(entry.get("cut_background", false)):
		_cut_background(cut)
	cut.resize(width, height, Image.INTERPOLATE_LANCZOS)
	for y: int in range(height):
		for x: int in range(width):
			var pixel: Color = cut.get_pixel(x, y)
			if pixel.a < 0.5:
				cut.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			pixel.a = 1.0
			cut.set_pixel(x, y, pixel)
	return cut


func _box(entry: Dictionary) -> Rect2i:
	var parts: PackedStringArray = String(entry["cell"]).split(":")
	var row: int = int(parts[0])
	var column: int = int(parts[1])
	return _boxes[row][column]


func _place(sheet: Image, tile: Image, column: int, row: int) -> void:
	sheet.blit_rect(
		tile, Rect2i(Vector2i.ZERO, tile.get_size()), Vector2i(column * TILE, row * TILE)
	)


func _cut_background(tile: Image) -> void:
	var width: int = tile.get_width()
	var height: int = tile.get_height()
	var reference: Color = tile.get_pixel(width / 2, height - 3)
	var queue: Array[Vector2i] = []
	for x: int in range(width):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, height - 1))
	for y: int in range(height):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(width - 1, y))
	var seen: Dictionary = {}
	while not queue.is_empty():
		var at: Vector2i = queue.pop_back()
		if seen.has(at) or at.x < 0 or at.y < 0 or at.x >= width or at.y >= height:
			continue
		seen[at] = true
		var pixel: Color = tile.get_pixel(at.x, at.y)
		if pixel.a < 0.5:
			continue
		var distance: float = (
			absf(pixel.r - reference.r) + absf(pixel.g - reference.g) + absf(pixel.b - reference.b)
		)
		if distance > BACKGROUND_TOLERANCE:
			continue
		tile.set_pixel(at.x, at.y, Color(reference.r, reference.g, reference.b, 0.0))
		queue.append(at + Vector2i.LEFT)
		queue.append(at + Vector2i.RIGHT)
		queue.append(at + Vector2i.UP)
		queue.append(at + Vector2i.DOWN)


func _make_unlit(tile: Image) -> void:
	for y: int in range(TILE):
		for x: int in range(TILE):
			var pixel: Color = tile.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			var value: float = _luma(pixel) * UNLIT_DIM
			tile.set_pixel(
				x,
				y,
				Color(value * UNLIT_TINT.r, value * UNLIT_TINT.g, value * UNLIT_TINT.b, 1.0)
			)


func _apply_gain(sheet: Image, gain: float) -> void:
	for y: int in range(sheet.get_height()):
		for x: int in range(sheet.get_width()):
			var pixel: Color = sheet.get_pixel(x, y)
			if pixel.a < 0.5:
				continue
			sheet.set_pixel(
				x,
				y,
				Color(_knee(pixel.r * gain), _knee(pixel.g * gain), _knee(pixel.b * gain), 1.0)
			)


func _knee(value: float) -> float:
	if value <= HIGHLIGHT_KNEE:
		return value
	var head: float = 1.0 - HIGHLIGHT_KNEE
	return HIGHLIGHT_KNEE + head * (1.0 - exp(-(value - HIGHLIGHT_KNEE) / head))


func _solid_luma(sheet: Image) -> float:
	var total: float = 0.0
	var count: int = 0
	for y: int in range(2 * TILE):
		for x: int in range(sheet.get_width()):
			var pixel: Color = sheet.get_pixel(x, y)
			if pixel.a <= 0.01:
				continue
			total += _luma(pixel)
			count += 1
	return total / maxf(float(count), 1.0)


func _luma(color: Color) -> float:
	return 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b


func _is_key(pixel: Color) -> bool:
	if pixel.a < 0.5:
		return true
	var distance: float = (
		absf(pixel.r - _key.r) + absf(pixel.g - _key.g) + absf(pixel.b - _key.b)
	)
	if distance <= KEY_TOLERANCE:
		return true
	var magenta: float = minf(pixel.r, pixel.b)
	if magenta <= _magenta_floor or absf(pixel.r - pixel.b) > 0.35:
		return false
	return pixel.g < magenta * 0.55


func _dilate_key() -> void:
	var width: int = _image.get_width()
	var height: int = _image.get_height()
	var filled: Array = []
	filled.resize(width * height)
	for y: int in range(height):
		for x: int in range(width):
			var is_key: bool = _is_key(_image.get_pixel(x, y))
			filled[y * width + x] = not is_key
			if is_key:
				_image.set_pixel(x, y, Color(0, 0, 0, 0))
	for pass_index: int in range(DILATE_PASSES):
		var grown: Array = filled.duplicate()
		var changed: bool = false
		for y: int in range(height):
			for x: int in range(width):
				if filled[y * width + x]:
					continue
				var sum := Color(0, 0, 0, 0)
				var neighbors: int = 0
				for offset: Vector2i in [
					Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN
				]:
					var at := Vector2i(x + offset.x, y + offset.y)
					if at.x < 0 or at.y < 0 or at.x >= width or at.y >= height:
						continue
					if not filled[at.y * width + at.x]:
						continue
					var pixel: Color = _image.get_pixel(at.x, at.y)
					sum += Color(pixel.r, pixel.g, pixel.b, 0.0)
					neighbors += 1
				if neighbors == 0:
					continue
				_image.set_pixel(
					x,
					y,
					Color(
						sum.r / float(neighbors), sum.g / float(neighbors), sum.b / float(neighbors), 0.0
					)
				)
				grown[y * width + x] = true
				changed = true
		filled = grown
		if not changed:
			break


func _detect_grid() -> Array:
	var width: int = _image.get_width()
	var height: int = _image.get_height()
	var bands: Array = []
	var start: int = -1
	for y: int in range(height):
		var count: int = 0
		for x: int in range(width):
			if _image.get_pixel(x, y).a > 0.5:
				count += 1
		var has_content: bool = count > width / 200
		if has_content and start < 0:
			start = y
		elif not has_content and start >= 0:
			bands.append(Vector2i(start, y - 1))
			start = -1
	if start >= 0:
		bands.append(Vector2i(start, height - 1))
	var rows: Array = []
	for band: Vector2i in bands:
		rows.append(_row_boxes(band))
	return rows


func _row_boxes(band: Vector2i) -> Array:
	var width: int = _image.get_width()
	var boxes: Array = []
	var start: int = -1
	for x: int in range(width):
		var filled: bool = false
		for y: int in range(band.x, band.y + 1):
			if _image.get_pixel(x, y).a > 0.5:
				filled = true
				break
		if filled and start < 0:
			start = x
		elif not filled and start >= 0:
			boxes.append(_tight(start, x - 1, band))
			start = -1
	if start >= 0:
		boxes.append(_tight(start, width - 1, band))
	return boxes


func _tight(left: int, right: int, band: Vector2i) -> Rect2i:
	var top: int = band.y
	var bottom: int = band.x
	for y: int in range(band.x, band.y + 1):
		for x: int in range(left, right + 1):
			if _image.get_pixel(x, y).a > 0.5:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				break
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _options() -> Dictionary:
	var options: Dictionary = {}
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--"):
			continue
		var body: String = argument.substr(2)
		var separator: int = body.find("=")
		if separator < 0:
			options[body] = "true"
			continue
		options[body.substr(0, separator)] = body.substr(separator + 1)
	return options
