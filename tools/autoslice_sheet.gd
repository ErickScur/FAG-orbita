extends SceneTree

const KEY_TOLERANCE: float = 0.30
const ROW_GAP: int = 8
const COLUMN_GAP: int = 6


func _init() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var source: String = _arg(args, "--in", "")
	var target: String = _arg(args, "--out", "")
	var frame_width: int = int(_arg(args, "--frame-width", "32"))
	var frame_height: int = int(_arg(args, "--frame-height", "32"))
	var columns: int = int(_arg(args, "--columns", "6"))
	var fit: String = _arg(args, "--fit", "height")
	if source.is_empty() or target.is_empty():
		print("uso: --in=<png> --out=<png> [--frame-width=32] [--frame-height=32]"
			+ " [--columns=6] [--fit=height|contain]")
		quit(2)
		return
	var image: Image = Image.load_from_file(source)
	if image == null:
		print("ERRO: não consegui abrir ", source)
		quit(3)
		return
	image.convert(Image.FORMAT_RGBA8)
	var key: Color = image.get_pixel(0, 0)
	_strip_key(image, key)
	var rows: Array = _split_rows(image)
	print("linhas detectadas: ", rows.size())
	var frames: Array = []
	var max_columns: int = 0
	for row: Vector2i in rows:
		var boxes: Array = _split_columns(image, row)
		max_columns = maxi(max_columns, boxes.size())
		frames.append(boxes)
		print("  linha y=", row.x, "..", row.y, " quadros: ", boxes.size())
	var baseline: int = _tallest(frames)
	var widest: int = _widest(frames)
	var scale: float = float(frame_height) / float(baseline)
	if fit == "contain":
		scale = minf(scale, float(frame_width) / float(widest))
	print("referencia linha 1: ", widest, "x", baseline, " escala: ", scale)
	var sheet := Image.create(columns * frame_width, rows.size() * frame_height, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0, 0, 0, 0))
	for row_index: int in range(frames.size()):
		var boxes: Array = frames[row_index]
		for column_index: int in range(mini(boxes.size(), columns)):
			var box: Rect2i = boxes[column_index]
			var frame: Image = _extract(image, box, frame_width, frame_height, scale)
			sheet.blit_rect(
				frame,
				Rect2i(Vector2i.ZERO, frame.get_size()),
				Vector2i(column_index * frame_width, row_index * frame_height)
			)
	var error: int = sheet.save_png(target)
	if error != OK:
		print("ERRO ao salvar: ", error)
		quit(4)
		return
	print("OK ", target, " ", sheet.get_width(), "x", sheet.get_height(), " (", max_columns, " colunas máx.)")
	quit(0)


func _arg(args: PackedStringArray, name: String, fallback: String) -> String:
	for argument: String in args:
		if argument.begins_with(name + "="):
			return argument.substr(name.length() + 1)
	return fallback


func _strip_key(image: Image, key: Color) -> void:
	for y: int in range(image.get_height()):
		for x: int in range(image.get_width()):
			var pixel: Color = image.get_pixel(x, y)
			var distance: float = (
				absf(pixel.r - key.r) + absf(pixel.g - key.g) + absf(pixel.b - key.b)
			)
			if distance <= KEY_TOLERANCE or _is_key_family(pixel):
				image.set_pixel(x, y, Color(0, 0, 0, 0))


func _is_key_family(pixel: Color) -> bool:
	if pixel.a < 0.1:
		return true
	var magenta: float = minf(pixel.r, pixel.b)
	return magenta > 0.35 and pixel.g < magenta * 0.75


func _row_has_content(image: Image, y: int) -> bool:
	for x: int in range(image.get_width()):
		if image.get_pixel(x, y).a > 0.1:
			return true
	return false


func _split_rows(image: Image) -> Array:
	var rows: Array = []
	var start: int = -1
	var empty_run: int = 0
	for y: int in range(image.get_height()):
		if _row_has_content(image, y):
			if start < 0:
				start = y
			empty_run = 0
			continue
		if start < 0:
			continue
		empty_run += 1
		if empty_run >= ROW_GAP:
			rows.append(Vector2i(start, y - empty_run))
			start = -1
			empty_run = 0
	if start >= 0:
		rows.append(Vector2i(start, image.get_height() - 1))
	return rows


func _column_has_content(image: Image, x: int, row: Vector2i) -> bool:
	for y: int in range(row.x, row.y + 1):
		if image.get_pixel(x, y).a > 0.1:
			return true
	return false


func _split_columns(image: Image, row: Vector2i) -> Array:
	var boxes: Array = []
	var start: int = -1
	var empty_run: int = 0
	for x: int in range(image.get_width()):
		if _column_has_content(image, x, row):
			if start < 0:
				start = x
			empty_run = 0
			continue
		if start < 0:
			continue
		empty_run += 1
		if empty_run >= COLUMN_GAP:
			boxes.append(_tight_box(image, start, x - empty_run, row))
			start = -1
			empty_run = 0
	if start >= 0:
		boxes.append(_tight_box(image, start, image.get_width() - 1, row))
	return boxes


func _tight_box(image: Image, left: int, right: int, row: Vector2i) -> Rect2i:
	var top: int = row.y
	var bottom: int = row.x
	for y: int in range(row.x, row.y + 1):
		for x: int in range(left, right + 1):
			if image.get_pixel(x, y).a > 0.1:
				top = mini(top, y)
				bottom = maxi(bottom, y)
				break
	return Rect2i(left, top, right - left + 1, bottom - top + 1)


func _tallest(frames: Array) -> int:
	if frames.is_empty():
		return 1
	var reference: Array = frames[0]
	var tallest: int = 1
	for box: Rect2i in reference:
		tallest = maxi(tallest, box.size.y)
	return tallest


func _widest(frames: Array) -> int:
	if frames.is_empty():
		return 1
	var reference: Array = frames[0]
	var widest: int = 1
	for box: Rect2i in reference:
		widest = maxi(widest, box.size.x)
	return widest


func _extract(image: Image, box: Rect2i, width: int, height: int, scale: float) -> Image:
	var cut: Image = image.get_region(box)
	var target_width: int = maxi(1, int(round(float(box.size.x) * scale)))
	var target_height: int = maxi(1, int(round(float(box.size.y) * scale)))
	cut.resize(target_width, target_height, Image.INTERPOLATE_LANCZOS)
	_strip_key(cut, Color(1, 0, 1, 1))
	var frame := Image.create(width, height, false, Image.FORMAT_RGBA8)
	frame.fill(Color(0, 0, 0, 0))
	var offset := Vector2i((width - target_width) / 2, height - target_height)
	var source_rect := Rect2i(Vector2i.ZERO, cut.get_size())
	if offset.x < 0:
		source_rect.position.x = -offset.x
		source_rect.size.x = mini(cut.get_width() + offset.x, width)
		offset.x = 0
	if offset.y < 0:
		source_rect.position.y = -offset.y
		source_rect.size.y = mini(cut.get_height() + offset.y, height)
		offset.y = 0
	frame.blit_rect(cut, source_rect, offset)
	return frame
