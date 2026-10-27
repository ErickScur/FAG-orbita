extends SceneTree

const MANIFEST_PATH: String = "res://tools/placeholders.json"
const ASSETS_ROOT: String = "res://assets/"
const PLACEHOLDER_ROOT: String = "res://assets/placeholder/"
const TRANSPARENT: Color = Color(0.0, 0.0, 0.0, 0.0)
const RADIAL_PLATEAU: float = 0.25
const GLYPHS: Dictionary = {
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
}
const LOGO_WORD: PackedStringArray = ["O", "R", "B", "I", "T", "A"]

var _rng := RandomNumberGenerator.new()
var _palettes: Dictionary = {}


func _initialize() -> void:
	var manifest: Dictionary = _load_manifest()
	if manifest.is_empty():
		push_error("make_placeholders: manifesto inválido em %s" % MANIFEST_PATH)
		quit(1)
		return
	_palettes = _parse_palettes(manifest.get("palettes", {}))
	var written: int = 0
	for value: Variant in manifest.get("images", []) as Array:
		if not (value is Dictionary):
			continue
		var entry: Dictionary = value
		if not _write_entry(entry):
			push_error("make_placeholders: falha ao gravar %s" % String(entry.get("id", "?")))
			quit(1)
			return
		written += 1
	print("GENERATED %d files" % written)
	quit(0)


func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not (parsed is Dictionary):
		return {}
	return parsed


func _parse_palettes(raw: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key: String in raw:
		var source: Dictionary = raw[key]
		var palette: Dictionary = {}
		for field: String in source:
			palette[field] = Color(String(source[field]))
		result[key] = palette
	return result


func _write_entry(entry: Dictionary) -> bool:
	var frame: Vector2i = _to_vector(entry.get("frame", [16, 16]))
	var grid: Vector2i = _to_vector(entry.get("grid", [1, 1]))
	if frame.x <= 0 or frame.y <= 0 or grid.x <= 0 or grid.y <= 0:
		return false
	var image := Image.create_empty(frame.x * grid.x, frame.y * grid.y, false, Image.FORMAT_RGBA8)
	image.fill(TRANSPARENT)
	var palette: Dictionary = _palettes.get(String(entry.get("palette", "ui")), {})
	_rng.seed = int(entry.get("seed", 20260919))
	var frames: Array = entry.get("frames", [])
	var shape: String = String(entry.get("shape", "rect_index"))
	for row: int in range(grid.y):
		var used: int = grid.x
		if row < frames.size():
			used = int(frames[row])
		for col: int in range(mini(used, grid.x)):
			var origin := Vector2i(col * frame.x, row * frame.y)
			_draw_cell(image, shape, origin, frame, palette, col, row, entry)
	var path: String = _target_path(entry)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	return image.save_png(path) == OK


func _target_path(entry: Dictionary) -> String:
	var relative: String = String(entry.get("path", ""))
	if bool(entry.get("final", false)):
		return ASSETS_ROOT + relative
	return PLACEHOLDER_ROOT + relative


func _to_vector(value: Variant) -> Vector2i:
	var list: Array = value
	if list.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(list[0]), int(list[1]))


func _draw_cell(
	image: Image,
	shape: String,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	match shape:
		"robot":
			_draw_robot(image, origin, size, palette, col, row, entry)
		"spider":
			_draw_spider(image, origin, size, palette, col, row, entry)
		"spore":
			_draw_spore(image, origin, size, palette, col, entry)
		"box_screen":
			_draw_box_screen(image, origin, size, palette, col, entry)
		"dock_frame":
			_draw_dock(image, origin, size, palette, col, entry)
		"bar_stripe":
			_draw_door(image, origin, size, palette, col, entry)
		"pickup_rows":
			_draw_pickup(image, origin, size, palette, col, row, entry)
		"rect_border":
			_draw_rect_border(image, origin, size, palette, entry)
		"grow":
			_draw_grow(image, origin, size, palette, col, entry)
		"rect_index":
			_draw_rect_index(image, origin, size, palette, col, row, entry)
		"drone":
			_draw_drone(image, origin, size, palette, col, entry)
		"hud_icons":
			_draw_hud_icon(image, origin, size, palette, col, row)
		"tileset":
			_draw_tile(image, origin, size, palette, col, row)
		"stars":
			_draw_stars(image, origin, size, palette)
		"nebula":
			_draw_nebula(image, origin, size, palette)
		"debris":
			_draw_debris(image, origin, size, palette)
		"logo_blocks":
			_draw_logo(image, origin, size, palette, entry)
		"radial":
			_draw_radial(image, origin, size)
		"cone":
			_draw_cone(image, origin, size)
		"ceiling_turret":
			_draw_ceiling_turret(image, origin, size, palette, col, row, entry)
		"steam_vent":
			_draw_steam_vent(image, origin, size, palette, entry)
		"flying_sentinel":
			_draw_flying_sentinel(image, origin, size, palette, col, row, entry)
		"ice":
			_draw_ice(image, origin, size, palette, col, row)
		"infirmary_props":
			_draw_infirmary_prop(image, origin, size, palette, col, row, entry)


func _draw_flying_sentinel(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var steel: Color = palette.get("secondary", Color.GRAY)
	var amber: Color = palette.get("danger", Color.ORANGE)
	var jet: Color = palette.get("accent", Color.CYAN)
	var off: bool = row == 1 and col == 3
	var lens: Color = jet
	if row == 1:
		lens = [amber, Color("#E0383A"), Color("#E0383A"), _shade(outline, 0.2)][col]
	var bob: int = [0, -1, 0, 1][col] if row == 0 else 0
	var dip: int = 1 if row == 1 and col == 1 else 0
	var cx: int = origin.x + size.x / 2
	var cy: int = origin.y + 13 + bob + (6 if off else 0)
	var half_h: float = 4.0 if off else 6.0
	if not off:
		var flame: int = [2, 4, 2, 4][col] if row == 0 else 3
		for side: int in [-7, 5]:
			_fill_rect(image, cx + side, cy + 4, 3, 3, steel)
			_stroke_rect(image, cx + side, cy + 4, 3, 3, outline)
			_fill_rect(image, cx + side + 1, cy + 7, 1, flame, jet)
	var claw_y: int = cy + 5
	if row == 1 and col == 2:
		_fill_rect(image, cx - 4, claw_y, 2, 6, steel)
		_fill_rect(image, cx + 2, claw_y, 2, 6, steel)
		_fill_rect(image, cx - 6, claw_y + 5, 3, 2, outline)
		_fill_rect(image, cx + 3, claw_y + 5, 3, 2, outline)
	elif not off:
		_fill_rect(image, cx - 2, claw_y, 4, 3, steel)
		_stroke_rect(image, cx - 2, claw_y, 4, 3, outline)
	_fill_ellipse(image, float(cx), float(cy) + 0.5, 11.5, half_h + 1.0, outline)
	_fill_ellipse(image, float(cx), float(cy) + 0.5, 10.5, half_h, body)
	_fill_rect(image, cx - 8, cy - int(half_h) + 1, 16, 1, _shade(body, 0.25))
	_fill_rect(image, cx - 3, cy - int(half_h), 3, int(half_h) * 2 + 1, amber)
	_put(image, cx - 2, cy - 2, _shade(amber, -0.5))
	_put(image, cx - 2, cy + 2, _shade(amber, -0.5))
	var lens_x: float = float(cx) + 6.0
	var lens_y: float = float(cy) + 0.5 + float(dip * 2)
	_fill_ellipse(image, lens_x, lens_y, 4.2, 4.2, outline)
	_fill_ellipse(image, lens_x, lens_y, 3.0, 3.0, lens)
	if not off:
		_put(image, int(lens_x) - 1, int(lens_y) - 1, _shade(lens, 0.6))


func _draw_ice(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, row: int
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var deep: Color = Color("#3E6E95")
	var mid: Color = Color("#6FA8CF")
	var pale: Color = Color("#A9DCEC")
	var shine: Color = palette.get("light", Color.WHITE)
	if row == 0:
		var slab_h: int = 6
		var pieces: Array = [[0, size.x]]
		if col == 2:
			pieces = [[0, 4], [6, 4], [12, 4]]
		for index: int in range(pieces.size()):
			var piece: Array = pieces[index]
			var drop: int = index % 2 if col == 2 else 0
			var px: int = origin.x + int(piece[0])
			var py: int = origin.y + drop
			_fill_rect(image, px, py, int(piece[1]), slab_h, mid)
			_fill_rect(image, px, py, int(piece[1]), 2, pale)
			_fill_rect(image, px, py + slab_h - 1, int(piece[1]), 1, outline)
			_put(image, px + 1, py, shine)
		if col < 2:
			for icicle: int in [3, 8, 12]:
				_fill_rect(image, origin.x + icicle, origin.y + slab_h, 2, 2, mid)
				_put(image, origin.x + icicle, origin.y + slab_h + 2, pale)
		if col == 1:
			for step: int in range(5):
				_put(image, origin.x + 3 + step * 2, origin.y + 2 + step % 2 * 2, shine)
		return
	var lump_h: int = [size.y, size.y - 4, 5][col]
	var inset: int = [0, 2, 3][col]
	var top: int = origin.y + size.y - lump_h
	_fill_rect(image, origin.x + inset, top, size.x - inset * 2, lump_h, deep)
	_fill_rect(image, origin.x + inset + 1, top + 1, size.x - inset * 2 - 2, lump_h - 2, mid)
	_fill_rect(image, origin.x + inset + 2, top + 1, 2, mini(lump_h - 2, 8), pale)
	_put(image, origin.x + inset + 2, top + 1, shine)
	if col == 0:
		_fill_rect(image, origin.x + 9, origin.y + 4, 1, 6, pale)
		_fill_rect(image, origin.x + 10, origin.y + 9, 3, 1, pale)
		return
	_fill_rect(image, origin.x + inset + 4, origin.y + size.y - 1, size.x - inset * 2 - 6, 1, pale)
	if col == 1:
		_fill_rect(image, origin.x + 11, top + lump_h - 1, 1, 1, pale)
		_put(image, origin.x + 6, top + lump_h - 2, shine)


func _draw_infirmary_prop(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var steel: Color = palette.get("secondary", Color.GRAY)
	var sheet: Color = palette.get("accent", Color.CYAN)
	var amber: Color = palette.get("danger", Color.ORANGE)
	var ground: int = origin.y + size.y
	var x: int = origin.x
	match row * 4 + col:
		0, 1:
			_fill_rect(image, x + 2, ground - 4, 2, 4, steel)
			_fill_rect(image, x + 28, ground - 4, 2, 4, steel)
			_fill_rect(image, x + 1, ground - 9, 30, 5, steel)
			_stroke_rect(image, x + 1, ground - 9, 30, 5, outline)
			_fill_rect(image, x + 1, ground - 14, 2, 6, steel)
			var mattress: Color = sheet if col == 0 else _shade(body, -0.25)
			_fill_rect(image, x + 3, ground - 12, 27, 3, mattress)
			_stroke_rect(image, x + 3, ground - 12, 27, 3, outline)
			if col == 0:
				_fill_rect(image, x + 4, ground - 14, 7, 3, body)
				_stroke_rect(image, x + 4, ground - 14, 7, 3, outline)
			else:
				_fill_rect(image, x + 21, ground - 16, 8, 4, sheet)
				_stroke_rect(image, x + 21, ground - 16, 8, 4, outline)
		2:
			_fill_rect(image, x + 3, ground - 3, 3, 3, outline)
			_fill_rect(image, x + 26, ground - 3, 3, 3, outline)
			for step: int in range(8):
				_fill_rect(image, x + 6 + step * 2, ground - 4 - step, 2, 1, steel)
				_fill_rect(image, x + 24 - step * 2, ground - 4 - step, 2, 1, steel)
			_fill_rect(image, x + 2, ground - 14, 28, 3, body)
			_stroke_rect(image, x + 2, ground - 14, 28, 3, outline)
		3:
			_fill_rect(image, x + 9, ground - 2, 14, 2, steel)
			_fill_rect(image, x + 15, ground - 30, 2, 28, steel)
			_fill_rect(image, x + 11, ground - 30, 10, 1, steel)
			_fill_rect(image, x + 18, ground - 29, 5, 7, sheet)
			_stroke_rect(image, x + 18, ground - 29, 5, 7, outline)
		4:
			_fill_rect(image, x + 8, ground - 5, 16, 5, steel)
			_stroke_rect(image, x + 8, ground - 5, 16, 5, outline)
			_fill_ellipse(image, float(x) + 16.0, float(ground) - 12.0, 15.0, 7.0, outline)
			_fill_ellipse(image, float(x) + 16.0, float(ground) - 12.0, 14.0, 6.0, body)
			_fill_rect(image, x + 7, ground - 17, 18, 4, sheet)
			_fill_rect(image, x + 4, ground - 11, 24, 1, amber)
		5:
			_fill_rect(image, x + 6, ground - 18, 20, 15, steel)
			_stroke_rect(image, x + 6, ground - 18, 20, 15, outline)
			for drawer: int in range(3):
				_fill_rect(image, x + 14, ground - 15 + drawer * 4, 4, 1, amber)
			_fill_rect(image, x + 8, ground - 3, 3, 3, outline)
			_fill_rect(image, x + 21, ground - 3, 3, 3, outline)
			_fill_rect(image, x + 9, ground - 21, 2, 3, sheet)
			_fill_rect(image, x + 13, ground - 22, 2, 4, body)
		6:
			_fill_ellipse(image, float(x) + 13.0, float(ground) - 8.0, 7.5, 7.5, outline)
			_fill_ellipse(image, float(x) + 13.0, float(ground) - 8.0, 5.5, 5.5, _shade(outline, 0.15))
			_fill_ellipse(image, float(x) + 13.0, float(ground) - 8.0, 2.0, 2.0, steel)
			_fill_rect(image, x + 22, ground - 3, 3, 3, outline)
			_fill_rect(image, x + 10, ground - 14, 14, 3, body)
			_fill_rect(image, x + 9, ground - 26, 3, 13, steel)
			_fill_rect(image, x + 22, ground - 12, 2, 9, steel)
		_:
			_fill_rect(image, x + 6, ground - 30, 20, 30, steel)
			_stroke_rect(image, x + 6, ground - 30, 20, 30, outline)
			for drawer: int in range(3):
				_stroke_rect(image, x + 8, ground - 28 + drawer * 9, 16, 8, outline)
				_fill_rect(image, x + 14, ground - 25 + drawer * 9, 4, 1, amber)
			_fill_rect(image, x + 10, ground - 32, 10, 3, body)


func _draw_ceiling_turret(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var steel: Color = _shade(body, -0.38)
	var off: bool = row == 1 and col == 3
	var lens: Color = palette.get("accent", Color.CYAN)
	if row == 1:
		lens = Color("#E0383A") if not off else _shade(outline, 0.18)
	if row == 1 and col == 1:
		lens = Color("#FF6A5A")
	var cx: int = origin.x + size.x / 2
	var swing: int = [-3, -1, 1, 3][col] if row == 0 else 0
	var droop: int = 4 if off else 0
	_fill_rect(image, cx - 9, origin.y, 18, 4, steel)
	_stroke_rect(image, cx - 9, origin.y, 18, 4, outline)
	_fill_rect(image, cx - 7, origin.y + 1, 2, 2, palette.get("danger", Color.ORANGE))
	_fill_rect(image, cx + 5, origin.y + 1, 2, 2, palette.get("danger", Color.ORANGE))
	_fill_rect(image, cx - 2, origin.y + 4, 4, 6, steel)
	_stroke_rect(image, cx - 2, origin.y + 4, 4, 6, outline)
	_fill_rect(image, cx - 3 + swing / 2, origin.y + 9, 6, 3, body)
	_stroke_rect(image, cx - 3 + swing / 2, origin.y + 9, 6, 3, outline)
	var head_x: int = cx - 7 + swing
	var head_y: int = origin.y + 12 + droop
	_fill_rect(image, head_x, head_y, 14, 9, body)
	_stroke_rect(image, head_x, head_y, 14, 9, outline)
	_fill_rect(image, head_x + 1, head_y + 1, 12, 2, _shade(body, 0.2))
	_fill_ellipse(image, float(head_x) + 7.0, float(head_y) + 8.5, 5.0, 4.0, outline)
	_fill_ellipse(image, float(head_x) + 7.0, float(head_y) + 8.5, 3.6, 2.8, lens)
	if not off:
		_put(image, head_x + 6, head_y + 7, _shade(lens, 0.5))
	if row == 1 and col == 2:
		_fill_diamond(image, head_x + 7, head_y + 15, 3, Color("#FFD9C2"))
		_fill_rect(image, head_x + 6, head_y + 12, 3, 8, Color("#FF6A5A"))


func _draw_steam_vent(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var heat: Color = palette.get("danger", Color.ORANGE)
	var top: int = origin.y + size.y - 7
	_fill_rect(image, origin.x + 1, top, size.x - 2, 7, body)
	_stroke_rect(image, origin.x + 1, top, size.x - 2, 7, outline)
	_fill_rect(image, origin.x + 2, top + 1, size.x - 4, 1, heat)
	for slot: int in range(4, size.x - 4, 3):
		_fill_rect(image, origin.x + slot, top + 3, 2, 3, _shade(outline, 0.1))
	_fill_rect(image, origin.x + 4, top - 2, size.x - 8, 2, _shade(body, 0.18))
	_stroke_rect(image, origin.x + 4, top - 2, size.x - 8, 2, outline)


func _body_color(entry: Dictionary, palette: Dictionary) -> Color:
	if entry.has("body"):
		return Color(String(entry["body"]))
	return palette.get("secondary", Color.GRAY)


func _shade(color: Color, amount: float) -> Color:
	var shaded: Color = color.lightened(amount) if amount >= 0.0 else color.darkened(-amount)
	shaded.a = color.a
	return shaded


func _put(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	image.set_pixel(x, y, color)


func _blend(image: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= image.get_width() or y >= image.get_height():
		return
	var under: Color = image.get_pixel(x, y)
	var alpha: float = color.a + under.a * (1.0 - color.a)
	if alpha <= 0.0:
		image.set_pixel(x, y, TRANSPARENT)
		return
	var red: float = (color.r * color.a + under.r * under.a * (1.0 - color.a)) / alpha
	var green: float = (color.g * color.a + under.g * under.a * (1.0 - color.a)) / alpha
	var blue: float = (color.b * color.a + under.b * under.a * (1.0 - color.a)) / alpha
	image.set_pixel(x, y, Color(red, green, blue, alpha))


func _blend_ellipse(image: Image, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for oy: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for ox: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx: float = (float(ox) + 0.5 - cx) / maxf(rx, 0.001)
			var dy: float = (float(oy) + 0.5 - cy) / maxf(ry, 0.001)
			var distance: float = dx * dx + dy * dy
			if distance > 1.0:
				continue
			var soft: Color = color
			soft.a = color.a * (1.0 - distance)
			_blend(image, ox, oy, soft)


func _fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for oy: int in range(h):
		for ox: int in range(w):
			_put(image, x + ox, y + oy, color)


func _stroke_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for ox: int in range(w):
		_put(image, x + ox, y, color)
		_put(image, x + ox, y + h - 1, color)
	for oy: int in range(h):
		_put(image, x, y + oy, color)
		_put(image, x + w - 1, y + oy, color)


func _fill_ellipse(image: Image, cx: float, cy: float, rx: float, ry: float, color: Color) -> void:
	for oy: int in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for ox: int in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx: float = (float(ox) + 0.5 - cx) / maxf(rx, 0.001)
			var dy: float = (float(oy) + 0.5 - cy) / maxf(ry, 0.001)
			if dx * dx + dy * dy <= 1.0:
				_put(image, ox, oy, color)


func _fill_diamond(image: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for oy: int in range(-radius, radius + 1):
		var span: int = radius - absi(oy)
		for ox: int in range(-span, span + 1):
			_put(image, cx + ox, cy + oy, color)


func _draw_robot(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var accent: Color = palette.get("accent", Color.CYAN)
	var body: Color = _shade(_body_color(entry, palette), -0.22 + 0.05 * float(row))
	var legs: Color = _shade(body, -0.18)
	var bob: int = [0, -1, 0, 1][col % 4]
	var body_w: int = 20
	var body_h: int = 18
	var leg_h: int = 8
	var x: int = origin.x + (size.x - body_w) / 2
	var feet: int = origin.y + size.y - 1
	var top: int = feet - leg_h - body_h + 1 + bob
	_fill_rect(image, x + 3, top + body_h, 4, leg_h, legs)
	_fill_rect(image, x + body_w - 7, top + body_h, 4, leg_h, legs)
	_stroke_rect(image, x + 3, top + body_h, 4, leg_h, outline)
	_stroke_rect(image, x + body_w - 7, top + body_h, 4, leg_h, outline)
	_fill_rect(image, x + 1, feet - 1, 8, 2, outline)
	_fill_rect(image, x + body_w - 9, feet - 1, 8, 2, outline)
	_fill_rect(image, x, top + 6, body_w, body_h - 6, body)
	_stroke_rect(image, x, top + 6, body_w, body_h - 6, outline)
	_fill_rect(image, x + 5, top, body_w - 7, 7, _shade(body, 0.12))
	_stroke_rect(image, x + 5, top, body_w - 7, 7, outline)
	_fill_rect(image, x + 2, top + body_h - 5, body_w - 4, 2, palette.get("danger", Color.YELLOW))
	_fill_rect(image, x + 3, top + 9, 5, 4, _shade(body, -0.4))
	var eye: Color = accent if row != 8 else _shade(outline, 0.25)
	_fill_rect(image, x + body_w - 8, top + 2, 3, 3, eye)
	if row == 6:
		_fill_rect(image, x + body_w - 9, top + 1, 5, 5, eye)
	_fill_rect(image, x + 6, top - 4, 1, 4, outline)
	_put(image, x + 6, top - 5, accent)


func _draw_spider(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _shade(_body_color(entry, palette), -0.1 * float(row))
	var lamp: Color = palette.get("danger", Color.ORANGE)
	if row == 1:
		lamp = _shade(lamp, -0.25 * float(col + 1))
	elif row == 2:
		lamp = _shade(outline, 0.2)
	var cx: float = float(origin.x) + float(size.x) * 0.5
	var cy: float = float(origin.y) + float(size.y) * 0.5 + 1.0
	var leg_drop: int = 4 if row == 0 else maxi(1, 4 - col)
	for index: int in range(6):
		var lx: int = origin.x + 4 + index * 4
		var phase: int = (index + col) % 2
		for step: int in range(leg_drop):
			var offset: int = 1 if step > 1 and phase == 0 else 0
			_put(image, lx + offset, int(cy) + 2 + step, outline)
			_put(image, lx + offset + 1, int(cy) + 2 + step, outline)
	_fill_ellipse(image, cx, cy, 12.0, 5.0, body)
	_fill_ellipse(image, cx, cy - 1.0, 10.0, 3.0, _shade(body, 0.12))
	_fill_rect(image, origin.x + 4, int(cy) - 5, 3, 2, lamp)
	_fill_rect(image, origin.x + size.x - 6, int(cy) - 1, 3, 2, palette.get("accent", Color.CYAN))


func _draw_spore(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, entry: Dictionary
) -> void:
	var body: Color = _body_color(entry, palette)
	body.a = 0.8
	var accent: Color = palette.get("accent", Color.PINK)
	accent.a = 0.9
	var radius: float = 3.5 - 0.5 * float(col % 3)
	var cx: float = float(origin.x) + float(size.x) * 0.5
	var cy: float = float(origin.y) + float(size.y) * 0.5
	_fill_ellipse(image, cx, cy, radius, radius, body)
	if col % 2 == 1:
		_put(image, int(cx), int(cy) - 1, accent)
	else:
		_put(image, int(cx) - 1, int(cy), accent)


func _draw_box_screen(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var big: bool = col < 3
	var w: int = 24 if big else 16
	var h: int = 28 if big else 18
	var x: int = origin.x + (size.x - w) / 2
	var y: int = origin.y + size.y - h - 1
	_fill_rect(image, x, y, w, h, body)
	_stroke_rect(image, x, y, w, h, outline)
	var screen: Color = _shade(outline, 0.1)
	if big:
		if col == 1:
			screen = palette.get("accent", Color.CYAN).darkened(0.35)
		elif col == 2:
			screen = palette.get("accent", Color.CYAN)
	elif col == 4:
		screen = Color("#5FE38A")
	_fill_rect(image, x + 3, y + 3, w - 6, h - (12 if big else 8), screen)
	_stroke_rect(image, x + 3, y + 3, w - 6, h - (12 if big else 8), outline)
	if big:
		_fill_rect(image, x + 4, y + h - 7, 8, 4, _shade(body, -0.3))
		var lever_up: bool = col == 2
		_fill_rect(image, x + w - 8, y + h - (11 if lever_up else 7), 3, 6, palette.get("danger", Color.YELLOW))
	if col == 2:
		for bar: int in range(3):
			_fill_rect(image, x + 5 + bar * 5, y + 6, 3, 8 - bar * 2, palette.get("danger", Color.YELLOW))


func _draw_dock(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var accent: Color = palette.get("accent", Color.CYAN)
	var w: int = 28
	var h: int = 44
	var x: int = origin.x + (size.x - w) / 2
	var y: int = origin.y + size.y - h - 1
	_fill_rect(image, x, y, w, h, _shade(body, -0.25))
	_stroke_rect(image, x, y, w, h, outline)
	_fill_rect(image, x + 4, y + 4, w - 8, h - 10, _shade(body, -0.45))
	_fill_rect(image, x + 2, y + h - 5, w - 4, 4, body)
	_stroke_rect(image, x + 2, y + h - 5, w - 4, 4, outline)
	_fill_rect(image, x + 1, y + 10, 3, 12, body)
	_fill_rect(image, x + w - 4, y + 10, 3, 12, body)
	var pulse: int = 0 if col == 0 else col - 1
	var band_y: int = y + h - 10 - pulse * 8
	var glow: Color = accent if col > 0 else _shade(accent, -0.5)
	_fill_rect(image, x + 4, band_y, w - 8, 3, glow)


func _draw_door(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var sealed: bool = col == 6
	var open_steps: int = 0
	if col >= 1 and col <= 4:
		open_steps = col
	elif col == 5:
		open_steps = 5
	_fill_rect(image, origin.x, origin.y, size.x, size.y, _shade(outline, 0.08))
	_stroke_rect(image, origin.x, origin.y, size.x, size.y, outline)
	var panel_h: int = size.y - 6 - open_steps * int(float(size.y - 8) / 5.0)
	if sealed:
		panel_h = size.y - 6
	if panel_h > 0:
		var py: int = origin.y + size.y - panel_h - 2
		_fill_rect(image, origin.x + 2, py, size.x - 4, panel_h, body)
		_stroke_rect(image, origin.x + 2, py, size.x - 4, panel_h, outline)
		for stripe: int in range(0, panel_h - 4, 6):
			_fill_rect(image, origin.x + 3, py + 2 + stripe, size.x - 6, 2, palette.get("danger", Color.YELLOW))
	var light: Color = Color("#5FE38A")
	if sealed:
		light = Color("#D9534F")
	elif open_steps > 0:
		light = palette.get("accent", Color.CYAN)
	_fill_rect(image, origin.x + size.x / 2 - 1, origin.y + 2, 2, 2, light)
	if sealed:
		_fill_rect(image, origin.x + 6, origin.y + size.y / 2 - 3, 4, 5, Color("#D9534F"))
		_fill_rect(image, origin.x + 7, origin.y + size.y / 2 - 5, 2, 2, Color("#D9534F"))


func _draw_pickup(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var rows: Array = entry.get("rows", [])
	var body: Color = palette.get("accent", Color.CYAN)
	if row < rows.size():
		body = Color(String(rows[row]))
	var outline: Color = palette.get("outline", Color.BLACK)
	var light: Color = palette.get("light", Color.WHITE)
	var bob: int = [0, -1, 0, 1][col % 4]
	var x: int = origin.x
	var y: int = origin.y + bob
	match row:
		0:
			_draw_pickup_cell(image, x, y, body, outline, light)
		1:
			_draw_pickup_repair_kit(image, x, y, body, outline, light)
		2:
			_draw_pickup_log(image, x, y, body, outline, light)
		3:
			_draw_pickup_research(image, x, y, body, outline, light)
		_:
			_draw_pickup_capacitor(image, x, y, body, outline, light)
	if col % 2 == 0:
		_put(image, x + 2, y + 2, light)


func _draw_pickup_cell(
	image: Image, x: int, y: int, body: Color, outline: Color, light: Color
) -> void:
	_fill_rect(image, x + 6, y + 2, 4, 2, _shade(body, 0.4))
	_stroke_rect(image, x + 6, y + 2, 4, 2, outline)
	_fill_rect(image, x + 4, y + 4, 8, 10, body)
	_stroke_rect(image, x + 4, y + 4, 8, 10, outline)
	_fill_rect(image, x + 5, y + 5, 1, 8, _shade(body, 0.4))
	_fill_rect(image, x + 6, y + 8, 4, 2, light)


func _draw_pickup_repair_kit(
	image: Image, x: int, y: int, body: Color, outline: Color, light: Color
) -> void:
	_fill_rect(image, x + 6, y + 2, 4, 3, _shade(body, -0.35))
	_stroke_rect(image, x + 6, y + 2, 4, 3, outline)
	_fill_rect(image, x + 2, y + 5, 12, 9, body)
	_stroke_rect(image, x + 2, y + 5, 12, 9, outline)
	_fill_rect(image, x + 7, y + 7, 2, 5, light)
	_fill_rect(image, x + 5, y + 9, 6, 1, light)


func _draw_pickup_log(
	image: Image, x: int, y: int, body: Color, outline: Color, light: Color
) -> void:
	_fill_rect(image, x + 3, y + 2, 10, 12, body)
	_stroke_rect(image, x + 3, y + 2, 10, 12, outline)
	_fill_rect(image, x + 5, y + 4, 6, 1, light)
	var line: Color = _shade(body, -0.6)
	_fill_rect(image, x + 5, y + 7, 6, 1, line)
	_fill_rect(image, x + 5, y + 9, 6, 1, line)
	_fill_rect(image, x + 5, y + 11, 4, 1, line)


func _draw_pickup_research(
	image: Image, x: int, y: int, body: Color, outline: Color, light: Color
) -> void:
	_fill_hexagon(image, x + 8, y + 8, 13, 13, outline)
	_fill_hexagon(image, x + 8, y + 8, 11, 11, body)
	_fill_rect(image, x + 6, y + 5, 4, 1, _shade(body, 0.45))
	_fill_rect(image, x + 6, y + 7, 1, 4, light)
	_put(image, x + 9, y + 10, light)


func _draw_pickup_capacitor(
	image: Image, x: int, y: int, body: Color, outline: Color, light: Color
) -> void:
	_fill_ring(image, x + 8, y + 8, 6.6, 3.4, outline)
	_fill_ring(image, x + 8, y + 8, 5.6, 4.2, body)
	_fill_rect(image, x + 7, y + 5, 2, 6, outline)
	_fill_rect(image, x + 7, y + 6, 2, 4, light)
	_put(image, x + 5, y + 5, _shade(body, 0.45))


func _fill_ring(image: Image, cx: int, cy: int, outer: float, inner: float, color: Color) -> void:
	var limit: int = int(ceilf(outer))
	for oy: int in range(-limit, limit + 1):
		for ox: int in range(-limit, limit + 1):
			var distance: float = sqrt(float(ox * ox + oy * oy))
			if distance > outer or distance < inner:
				continue
			_put(image, cx + ox, cy + oy, color)


func _fill_hexagon(image: Image, cx: int, cy: int, width: int, height: int, color: Color) -> void:
	var half_w: int = width / 2
	var half_h: int = height / 2
	for oy: int in range(-half_h, half_h + 1):
		var taper: int = maxi(0, absi(oy) - half_h / 2)
		for ox: int in range(-half_w + taper, half_w - taper + 1):
			_put(image, cx + ox, cy + oy, color)


func _draw_rect_border(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, entry: Dictionary
) -> void:
	var body: Color = _body_color(entry, palette)
	_fill_rect(image, origin.x, origin.y, size.x, size.y, body)
	_stroke_rect(image, origin.x, origin.y, size.x, size.y, palette.get("outline", Color.BLACK))
	_fill_rect(image, origin.x + 2, origin.y + 1, size.x - 4, 1, _shade(body, 0.3))
	for notch: int in range(4, size.x - 4, 8):
		_fill_rect(image, origin.x + notch, origin.y + size.y - 3, 4, 2, palette.get("accent", Color.CYAN))


func _draw_grow(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var pot: Color = _shade(palette.get("secondary", Color.GRAY), -0.35)
	var pot_h: int = 10
	var pot_y: int = origin.y + size.y - pot_h
	_fill_rect(image, origin.x + 6, pot_y, size.x - 12, pot_h, pot)
	_stroke_rect(image, origin.x + 6, pot_y, size.x - 12, pot_h, outline)
	var stalk_h: int = 6 + col * 8
	var stalk_y: int = pot_y - stalk_h
	_fill_rect(image, origin.x + size.x / 2 - 2, stalk_y, 4, stalk_h, body)
	_stroke_rect(image, origin.x + size.x / 2 - 2, stalk_y, 4, stalk_h, outline)
	var leaf_w: int = 8 + col * 4
	if col == 5:
		leaf_w = 30
	_fill_rect(image, origin.x + (size.x - leaf_w) / 2, stalk_y - 4, leaf_w, 5, _shade(body, 0.18))
	_stroke_rect(image, origin.x + (size.x - leaf_w) / 2, stalk_y - 4, leaf_w, 5, outline)
	if col >= 3:
		_put(image, origin.x + size.x / 2 - 4, stalk_y - 6, palette.get("accent", Color.PINK))
		_put(image, origin.x + size.x / 2 + 4, stalk_y - 6, palette.get("accent", Color.PINK))


func _draw_rect_index(
	image: Image,
	origin: Vector2i,
	size: Vector2i,
	palette: Dictionary,
	col: int,
	row: int,
	entry: Dictionary
) -> void:
	var index: int = row * 8 + col
	var body: Color = _shade(_body_color(entry, palette), -0.2 + 0.06 * float(index))
	var outline: Color = palette.get("outline", Color.BLACK)
	var inset: int = 3 if size.x >= 24 else 1
	_fill_rect(image, origin.x + inset, origin.y + inset, size.x - inset * 2, size.y - inset * 2, body)
	_stroke_rect(image, origin.x + inset, origin.y + inset, size.x - inset * 2, size.y - inset * 2, outline)
	var accent: Color = palette.get("accent", Color.CYAN)
	for pip: int in range(index + 1):
		_fill_rect(image, origin.x + inset + 2 + pip * 4, origin.y + size.y - inset - 4, 2, 2, accent)


func _draw_drone(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, entry: Dictionary
) -> void:
	var outline: Color = palette.get("outline", Color.BLACK)
	var body: Color = _body_color(entry, palette)
	var bob: int = [0, -1, 0, 1][col % 4]
	var cx: float = float(origin.x) + float(size.x) * 0.5
	var cy: float = float(origin.y) + float(size.y) * 0.5 + float(bob)
	_fill_ellipse(image, cx, cy, 5.0, 4.5, body)
	_fill_ellipse(image, cx, cy, 3.5, 3.0, _shade(body, -0.2))
	_fill_rect(image, origin.x + 2, int(cy) - 6, size.x - 4, 1, outline)
	_fill_rect(image, int(cx) + 2, int(cy) - 1, 2, 2, Color("#F2D27A"))
	if col >= 4:
		for drop: int in range(3):
			_put(image, int(cx) - 1 + drop, int(cy) + 5 + drop, palette.get("accent", Color.PINK))


func _draw_hud_icon(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, row: int
) -> void:
	var index: int = row * 8 + col
	var accent: Color = palette.get("accent", Color.CYAN)
	var outline: Color = palette.get("outline", Color.BLACK)
	var tints: PackedStringArray = [
		"#5FD4C8", "#4A1F22", "#D9534F", "#4FA3FF", "#D7E3E8",
		"#B7D35A", "#E0824A", "#9FD8F0", "#E8C15A", "#D7E3E8",
		"#5FE38A", "#E8C15A", "#D7E3E8", "#2F4F5A", "#2F4F5A", "#2F4F5A",
	]
	var tint: Color = Color(tints[index % tints.size()])
	_fill_rect(image, origin.x + 2, origin.y + 2, size.x - 4, size.y - 4, _shade(outline, 0.12))
	_stroke_rect(image, origin.x + 2, origin.y + 2, size.x - 4, size.y - 4, tint)
	if index < 3:
		_fill_rect(image, origin.x + 4, origin.y + 4, size.x - 8, size.y - 8, tint)
	elif index < 5:
		_fill_rect(image, origin.x + 4, origin.y + 6, size.x - 8, 4, tint)
	elif index == HudModel.ICON_LOG:
		_fill_rect(image, origin.x + 5, origin.y + 4, 6, 8, tint)
		var line: Color = _shade(tint, -0.65)
		_fill_rect(image, origin.x + 6, origin.y + 6, 4, 1, line)
		_fill_rect(image, origin.x + 6, origin.y + 8, 4, 1, line)
	elif index == HudModel.ICON_RESEARCH:
		_fill_hexagon(image, origin.x + size.x / 2, origin.y + size.y / 2, 7, 7, tint)
	elif index < 13:
		_fill_diamond(image, origin.x + size.x / 2, origin.y + size.y / 2, 3, tint)
	else:
		_fill_rect(image, origin.x + 5, origin.y + 5, size.x - 10, size.y - 10, accent)


func _draw_tile(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, col: int, row: int
) -> void:
	var secondary: Color = palette.get("secondary", Color.GRAY)
	var body: Color = palette.get("tile", secondary)
	var back: Color = palette.get("tile_back", _shade(body, -0.55))
	var accent: Color = palette.get("accent", Color.CYAN)
	var danger: Color = palette.get("danger", Color.YELLOW)
	var outline: Color = palette.get("outline", Color.BLACK)
	var index: int = row * 8 + col
	if index < 16:
		_fill_rect(image, origin.x, origin.y, size.x, size.y, _shade(body, 0.12))
		_fill_rect(image, origin.x + 2, origin.y + 2, size.x - 4, size.y - 4, body)
		var edge: Color = _shade(body.lerp(accent, 0.22), 0.3)
		if index & 1 == 0:
			_fill_rect(image, origin.x, origin.y, size.x, 2, edge)
		if index & 2 == 0:
			_fill_rect(image, origin.x + size.x - 2, origin.y, 2, size.y, edge)
		if index & 4 == 0:
			_fill_rect(image, origin.x, origin.y + size.y - 2, size.x, 2, _shade(body, -0.42))
		if index & 8 == 0:
			_fill_rect(image, origin.x, origin.y, 2, size.y, edge)
		_put(image, origin.x + 5, origin.y + 8, _shade(body, 0.4))
		_put(image, origin.x + 10, origin.y + 11, _shade(body, -0.4))
		_put(image, origin.x + 8, origin.y + 5, _shade(body, -0.4))
		return
	match index:
		16:
			_fill_rect(image, origin.x, origin.y + 2, size.x, 4, _shade(body, 0.34))
			_stroke_rect(image, origin.x, origin.y + 2, size.x, 4, _shade(body, -0.5))
			for slot: int in range(2, size.x - 2, 4):
				_fill_rect(image, origin.x + slot, origin.y + 3, 2, 2, _shade(body, -0.22))
		17:
			_fill_rect(image, origin.x, origin.y, size.x, size.y, back)
			_stroke_rect(image, origin.x, origin.y, size.x, size.y, _shade(back, -0.22))
			_put(image, origin.x + 4, origin.y + 4, _shade(back, 0.22))
			_put(image, origin.x + 11, origin.y + 9, _shade(back, 0.22))
		18:
			_stroke_rect(image, origin.x, origin.y, size.x, size.y, _shade(body, 0.1))
			_stroke_rect(image, origin.x + 1, origin.y + 1, size.x - 2, size.y - 2, _shade(body, -0.3))
		19:
			_fill_rect(image, origin.x, origin.y, size.x, size.y, back)
			for bar: int in range(1, size.x - 1, 3):
				_fill_rect(image, origin.x + bar, origin.y + 1, 1, size.y - 2, _shade(body, 0.15))
			_stroke_rect(image, origin.x, origin.y, size.x, size.y, outline)
		20:
			_fill_rect(image, origin.x, origin.y + 5, size.x, 6, _shade(body, -0.2))
			_fill_rect(image, origin.x, origin.y + 6, size.x, 2, _shade(body, 0.3))
		21:
			_fill_rect(image, origin.x + 5, origin.y, 6, size.y, _shade(body, -0.2))
			_fill_rect(image, origin.x + 6, origin.y, 2, size.y, _shade(body, 0.3))
		22:
			_fill_rect(image, origin.x + 4, origin.y, 8, 4, _shade(body, -0.1))
			_fill_rect(image, origin.x + 3, origin.y + 4, 10, 2, accent)
			_fill_rect(image, origin.x + 5, origin.y + 6, 6, 2, _shade(accent, 0.35))
		23:
			_fill_rect(image, origin.x, origin.y, size.x, size.y, _shade(back, -0.2))
			_diagonal_stripes(image, origin, size, danger, 6, 3)
		24:
			_fill_rect(image, origin.x, origin.y, size.x, size.y, _shade(body, -0.35))
			_stroke_rect(image, origin.x, origin.y, size.x, size.y, outline)
			_diagonal_stripes(image, origin, size, Color("#E8C15A"), 5, 2)
		_:
			return


func _diagonal_stripes(
	image: Image, origin: Vector2i, size: Vector2i, color: Color, period: int, thickness: int
) -> void:
	for y: int in range(size.y):
		for x: int in range(size.x):
			if posmod(x + y, period) < thickness:
				_put(image, origin.x + x, origin.y + y, color)


func _draw_stars(image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary) -> void:
	var base: Color = palette.get("base", Color.BLACK)
	for y: int in range(size.y):
		var blend: float = float(y) / float(size.y)
		_fill_rect(image, origin.x, origin.y + y, size.x, 1, _shade(base, 0.12 * blend))
	var light: Color = palette.get("light", Color.WHITE)
	for index: int in range(420):
		var x: int = _rng.randi_range(0, size.x - 1)
		var y: int = _rng.randi_range(0, size.y - 1)
		var brightness: float = _rng.randf_range(0.45, 1.0)
		var star: Color = light
		star.a = brightness
		_put(image, origin.x + x, origin.y + y, star)
		if brightness > 0.9:
			_put(image, origin.x + x + 1, origin.y + y, Color(light.r, light.g, light.b, 0.35))
			_put(image, origin.x + x, origin.y + y + 1, Color(light.r, light.g, light.b, 0.35))


func _draw_nebula(image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary) -> void:
	var teal: Color = palette.get("accent", Color.CYAN)
	var purple: Color = Color("#6B4E9E")
	for blob: int in range(22):
		var cx: float = _rng.randf_range(-20.0, float(size.x) + 20.0)
		var cy: float = _rng.randf_range(20.0, float(size.y) - 20.0)
		var rx: float = _rng.randf_range(34.0, 84.0)
		var ry: float = _rng.randf_range(18.0, 40.0)
		var tint: Color = teal if blob % 2 == 0 else purple
		tint.a = 0.42
		_blend_ellipse(image, float(origin.x) + cx, float(origin.y) + cy, rx, ry, tint)
	var planet: Color = Color("#3E8C7A")
	_fill_ellipse(image, float(origin.x) + 300.0, float(origin.y) + 70.0, 18.0, 18.0, planet)
	_fill_ellipse(image, float(origin.x) + 296.0, float(origin.y) + 66.0, 12.0, 12.0, _shade(planet, 0.22))
	_fill_ellipse(image, float(origin.x) + 306.0, float(origin.y) + 76.0, 8.0, 8.0, Color("#2A5E6B"))


func _draw_debris(image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary) -> void:
	var silhouette: Color = palette.get("outline", Color.BLACK)
	silhouette.a = 0.92
	_fill_rect(image, origin.x, origin.y + size.y - 24, size.x, 24, silhouette)
	for truss: int in range(0, size.x, 48):
		_fill_rect(image, origin.x + truss + 6, origin.y + size.y - 54, 6, 32, silhouette)
		_fill_rect(image, origin.x + truss + 2, origin.y + size.y - 58, 14, 5, silhouette)
		_fill_rect(image, origin.x + truss + 8, origin.y + size.y - 70, 2, 12, silhouette)
	for chunk: int in range(22):
		var x: int = _rng.randi_range(0, size.x - 4)
		var y: int = _rng.randi_range(10, size.y - 70)
		var w: int = _rng.randi_range(1, 4)
		var h: int = _rng.randi_range(1, 3)
		_fill_rect(image, origin.x + x, origin.y + y, w, h, silhouette)


func _draw_logo(
	image: Image, origin: Vector2i, size: Vector2i, palette: Dictionary, entry: Dictionary
) -> void:
	var body: Color = _body_color(entry, palette)
	var glow: Color = palette.get("accent", Color.CYAN)
	var scale: int = 4
	var glyph_w: int = 5 * scale
	var glyph_h: int = 7 * scale
	var gap: int = 4
	var total: int = LOGO_WORD.size() * glyph_w + (LOGO_WORD.size() - 1) * gap
	var x0: int = origin.x + (size.x - total) / 2
	var y0: int = origin.y + (size.y - glyph_h) / 2 + 2
	var ring: Color = Color(glow.r, glow.g, glow.b, 0.35)
	for angle_step: int in range(0, 360, 2):
		var angle: float = deg_to_rad(float(angle_step))
		var rx: float = float(x0 + glyph_w / 2) + cos(angle) * 34.0
		var ry: float = float(y0 + glyph_h / 2) + sin(angle) * 11.0
		_put(image, int(rx), int(ry), ring)
	for index: int in range(LOGO_WORD.size()):
		var rows: Array = GLYPHS[LOGO_WORD[index]]
		var gx: int = x0 + index * (glyph_w + gap)
		for ry2: int in range(rows.size()):
			var line: String = rows[ry2]
			for rx2: int in range(line.length()):
				if line[rx2] != "1":
					continue
				_fill_rect(image, gx + rx2 * scale, y0 + ry2 * scale, scale, scale, body)
	_fill_rect(image, x0 + 2 * scale, y0 - 6, scale * 2, 2, body)
	_fill_rect(image, x0 + 3 * scale, y0 - 8, scale, 2, body)


func _draw_radial(image: Image, origin: Vector2i, size: Vector2i) -> void:
	var cx: float = float(size.x) * 0.5
	var cy: float = float(size.y) * 0.5
	var radius: float = minf(cx, cy)
	for y: int in range(size.y):
		for x: int in range(size.x):
			var dx: float = (float(x) + 0.5 - cx) / radius
			var dy: float = (float(y) + 0.5 - cy) / radius
			var distance: float = sqrt(dx * dx + dy * dy)
			var fade: float = clampf((1.0 - distance) / (1.0 - RADIAL_PLATEAU), 0.0, 1.0)
			var alpha: float = fade * fade * (3.0 - 2.0 * fade)
			_put(image, origin.x + x, origin.y + y, Color(1.0, 1.0, 1.0, alpha))


func _draw_cone(image: Image, origin: Vector2i, size: Vector2i) -> void:
	var apex_y: float = float(size.y) * 0.5
	var half_angle: float = deg_to_rad(28.0)
	for y: int in range(size.y):
		for x: int in range(size.x):
			var dx: float = float(x) + 0.5
			var dy: float = float(y) + 0.5 - apex_y
			var distance: float = sqrt(dx * dx + dy * dy) / float(size.x)
			var angle: float = atan2(absf(dy), maxf(dx, 0.001))
			var angular: float = clampf(1.0 - angle / half_angle, 0.0, 1.0)
			var radial: float = clampf(1.0 - distance, 0.0, 1.0)
			var alpha: float = pow(angular, 1.4) * radial * radial
			_put(image, origin.x + x, origin.y + y, Color(1.0, 1.0, 1.0, alpha))
