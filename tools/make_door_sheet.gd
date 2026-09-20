extends SceneTree

const OUT_PATH: String = "res://assets/sprites/world/door_sheet.png"
const FRAME_W: int = 32
const FRAME_H: int = 48
const FRAME_COUNT: int = 6
const FRAME_PORTAL: int = 5

const JAMB_LEFT: int = 1
const JAMB_RIGHT: int = 30
const PASS_LEFT: int = 8
const PASS_RIGHT: int = 23
const LINTEL_BOTTOM: int = 8
const THRESHOLD_TOP: int = 41
const LEAF_TOP: int = 9
const LEAF_BOTTOM: int = 40

const OUTLINE: Color = Color("0b1118")
const STEEL_DK: Color = Color("1e2a34")
const STEEL_MD: Color = Color("3f5465")
const STEEL_LT: Color = Color("6d8698")
const STEEL_HI: Color = Color("a8bccb")
const HAZ_A: Color = Color("e0a43c")
const HAZ_B: Color = Color("23282e")
const LED_RED: Color = Color("ff6152")
const LED_AMBER: Color = Color("f2b73c")
const LED_GREEN: Color = Color("5fe38a")
const GLASS_DK: Color = Color("101b28")
const GLASS_MD: Color = Color("24455f")
const GLASS_HI: Color = Color("7fb6d2")
const PORTAL_RINGS: Array[Color] = [
	Color("0e1c19"), Color("1b3830"), Color("2f5a4a"), Color("4e8f72"), Color("9fe6c0")
]
const PORTAL_STRIP: Color = Color("2f5a4a")
const PORTAL_PLATE: Color = Color("0d1a16")
const PORTAL_TICK: Color = Color("8fe3b0")

const FRAME_OPEN: int = 4
const PORTAL_LINTEL: int = 12
const PORTAL_RECTS: Array[Vector4i] = [
	Vector4i(8, PORTAL_LINTEL, 23, 40),
	Vector4i(10, 15, 21, 37),
	Vector4i(12, 19, 19, 34),
	Vector4i(14, 23, 17, 30),
	Vector4i(15, 25, 16, 28),
]

const LEAVES: Array[Vector2i] = [
	Vector2i(24, 25),
	Vector2i(19, 30),
	Vector2i(14, 35),
	Vector2i(10, 39),
	Vector2i(8, 41),
]


func _init() -> void:
	var image := Image.create(FRAME_W * FRAME_COUNT, FRAME_H, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for index: int in range(FRAME_COUNT):
		_draw_frame(image, index * FRAME_W, index)
	var path: String = ProjectSettings.globalize_path(OUT_PATH)
	var error: int = image.save_png(path)
	print("door_sheet: %s erro=%d" % [path, error])
	quit(0 if error == OK else 1)


func _draw_frame(image: Image, ox: int, index: int) -> void:
	if index == FRAME_PORTAL:
		_draw_portal(image, ox)
		return
	var leaf: Vector2i = LEAVES[index]
	_draw_jambs(image, ox)
	_draw_lintel(image, ox, index)
	_draw_threshold(image, ox)
	if index == FRAME_OPEN:
		_haz_row(image, ox, LEAF_TOP)
		_haz_row(image, ox, LEAF_BOTTOM)
		return
	_draw_upper_leaf(image, ox, leaf.x)
	_draw_lower_leaf(image, ox, leaf.y)


func _draw_portal(image: Image, ox: int) -> void:
	var jamb: Array[Color] = [OUTLINE, STEEL_MD, STEEL_MD, STEEL_DK, STEEL_DK, STEEL_MD, OUTLINE]
	for i: int in range(jamb.size()):
		_column(image, ox + JAMB_LEFT + i, 0, FRAME_H, jamb[i])
		_column(image, ox + JAMB_RIGHT - i, 0, FRAME_H, jamb[i])
	_column(image, ox + JAMB_LEFT + 5, PORTAL_LINTEL, LEAF_BOTTOM - PORTAL_LINTEL + 1, PORTAL_STRIP)
	_column(image, ox + JAMB_RIGHT - 5, PORTAL_LINTEL, LEAF_BOTTOM - PORTAL_LINTEL + 1, PORTAL_STRIP)
	for index: int in range(PORTAL_RECTS.size()):
		var box: Vector4i = PORTAL_RECTS[index]
		_rect(image, ox + box.x, box.y, box.z - box.x + 1, box.w - box.y + 1, PORTAL_RINGS[index])
	var lintel: Array[Color] = [
		OUTLINE, STEEL_MD, STEEL_MD, STEEL_DK, STEEL_DK, STEEL_DK,
		STEEL_DK, STEEL_DK, STEEL_DK, STEEL_DK, STEEL_MD, OUTLINE
	]
	for y: int in range(lintel.size()):
		_rect(image, ox + JAMB_LEFT, y, JAMB_RIGHT - JAMB_LEFT + 1, 1, lintel[y])
	_rect(image, ox + 11, 2, 10, 7, OUTLINE)
	_rect(image, ox + 12, 3, 8, 5, PORTAL_PLATE)
	for x: int in [13, 15, 17, 19]:
		_rect(image, ox + x, 4, 1, 3, PORTAL_TICK)
	var sill: Array[Color] = [
		OUTLINE, PORTAL_TICK, STEEL_LT, STEEL_DK, STEEL_DK, STEEL_MD, OUTLINE
	]
	for y: int in range(sill.size()):
		_rect(
			image, ox + JAMB_LEFT, THRESHOLD_TOP + y, JAMB_RIGHT - JAMB_LEFT + 1, 1, sill[y]
		)
	for i: int in range(4):
		_rect(image, ox + PASS_LEFT + i, PORTAL_LINTEL + i, 4 - i, 1, STEEL_LT)
		_rect(image, ox + PASS_RIGHT - 3 + i, PORTAL_LINTEL + i, 4 - i, 1, STEEL_LT)


func _draw_jambs(image: Image, ox: int) -> void:
	var left: Array[Color] = [OUTLINE, STEEL_MD, STEEL_MD, STEEL_DK, STEEL_DK, STEEL_DK, OUTLINE]
	for i: int in range(left.size()):
		_column(image, ox + JAMB_LEFT + i, 0, FRAME_H, left[i])
		_column(image, ox + JAMB_RIGHT - i, 0, FRAME_H, left[i])
	for y: int in [13, 21, 29, 37]:
		_bolt(image, ox + 2, y)
		if y != 21:
			_bolt(image, ox + 28, y)
	_panel(image, ox + 26, 19)


func _panel(image: Image, x: int, y: int) -> void:
	_rect(image, x, y, 4, 8, OUTLINE)
	_rect(image, x + 1, y + 1, 2, 6, STEEL_MD)
	_rect(image, x + 1, y + 1, 2, 2, LED_GREEN)
	_rect(image, x + 1, y + 4, 2, 1, STEEL_LT)
	_rect(image, x + 1, y + 6, 2, 1, STEEL_LT)


func _bolt(image: Image, x: int, y: int) -> void:
	_rect(image, x, y, 2, 1, STEEL_LT)
	_rect(image, x, y + 1, 2, 1, OUTLINE)


func _draw_lintel(image: Image, ox: int, index: int) -> void:
	var rows: Array[Color] = [
		OUTLINE, STEEL_MD, STEEL_MD, STEEL_DK, STEEL_DK, STEEL_DK, STEEL_DK, STEEL_DK, OUTLINE
	]
	for y: int in range(rows.size()):
		_rect(image, ox + JAMB_LEFT, y, JAMB_RIGHT - JAMB_LEFT + 1, 1, rows[y])
	_haz_row(image, ox, 7)
	_draw_led(image, ox, index)


func _draw_led(image: Image, ox: int, index: int) -> void:
	var tint: Color = LED_RED
	if index == FRAME_OPEN:
		tint = LED_GREEN
	elif index > 0:
		tint = LED_AMBER
	_rect(image, ox + 13, 1, 6, 5, OUTLINE)
	_rect(image, ox + 14, 2, 4, 3, tint)
	_rect(image, ox + 14, 2, 1, 1, tint.lightened(0.45))


func _draw_threshold(image: Image, ox: int) -> void:
	var rows: Array[Color] = [
		OUTLINE, STEEL_DK, STEEL_DK, STEEL_DK, STEEL_DK, STEEL_MD, OUTLINE
	]
	for y: int in range(rows.size()):
		_rect(
			image, ox + JAMB_LEFT, THRESHOLD_TOP + y, JAMB_RIGHT - JAMB_LEFT + 1, 1, rows[y]
		)
	_haz_row(image, ox, THRESHOLD_TOP + 1)


func _draw_upper_leaf(image: Image, ox: int, bottom: int) -> void:
	var height: int = bottom - LEAF_TOP + 1
	if height <= 0:
		return
	_leaf_body(image, ox, LEAF_TOP, bottom)
	_porthole(image, ox, 16, LEAF_TOP, mini(bottom - 3, LEAF_BOTTOM))
	if height >= 3:
		_rect(image, ox + PASS_LEFT, bottom - 2, 16, 1, STEEL_LT)
	if height >= 2:
		_haz_row(image, ox, bottom - 1)
	_rect(image, ox + PASS_LEFT, bottom, 16, 1, OUTLINE)


func _draw_lower_leaf(image: Image, ox: int, top: int) -> void:
	var height: int = LEAF_BOTTOM - top + 1
	if height <= 0:
		return
	_leaf_body(image, ox, top, LEAF_BOTTOM)
	_porthole(image, ox, 33, maxi(top + 3, LEAF_TOP), LEAF_BOTTOM)
	if height >= 3:
		_rect(image, ox + PASS_LEFT, top + 2, 16, 1, STEEL_LT)
	if height >= 2:
		_haz_row(image, ox, top + 1)
	_rect(image, ox + PASS_LEFT, top, 16, 1, OUTLINE)


func _leaf_body(image: Image, ox: int, top: int, bottom: int) -> void:
	var height: int = bottom - top + 1
	_rect(image, ox + PASS_LEFT, top, 16, height, STEEL_MD)
	_column(image, ox + PASS_LEFT, top, height, STEEL_LT)
	_column(image, ox + PASS_LEFT + 1, top, height, STEEL_LT)
	_column(image, ox + PASS_RIGHT - 1, top, height, STEEL_DK)
	_column(image, ox + PASS_RIGHT, top, height, STEEL_DK)


func _porthole(image: Image, ox: int, cy: int, clip_top: int, clip_bottom: int) -> void:
	var cx: int = 16
	for dy: int in range(-4, 5):
		var y: int = cy + dy
		if y < clip_top or y > clip_bottom:
			continue
		for dx: int in range(-4, 5):
			var distance: float = sqrt(float(dx * dx + dy * dy))
			if distance > 4.4:
				continue
			var tone: Color = OUTLINE
			if distance <= 3.6:
				tone = GLASS_HI.lerp(GLASS_DK, clampf(float(dy + 3) / 6.0, 0.0, 1.0))
			image.set_pixel(ox + cx + dx, y, tone)


func _haz_row(image: Image, ox: int, y: int) -> void:
	for x: int in range(PASS_LEFT, PASS_RIGHT + 1):
		var band: int = int(floor(float(x - PASS_LEFT + y) / 2.0)) % 2
		image.set_pixel(ox + x, y, HAZ_A if band == 0 else HAZ_B)


func _column(image: Image, x: int, y: int, height: int, tone: Color) -> void:
	_rect(image, x, y, 1, height, tone)


func _rect(image: Image, x: int, y: int, w: int, h: int, tone: Color) -> void:
	for iy: int in range(y, y + h):
		if iy < 0 or iy >= FRAME_H:
			continue
		for ix: int in range(x, x + w):
			image.set_pixel(ix, iy, tone)
