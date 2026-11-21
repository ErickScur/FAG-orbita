class_name RootPlate
extends Node2D

const GLYPHS: Dictionary = {
	"R": ["110", "101", "110", "101", "101"],
	"O": ["010", "101", "101", "101", "010"],
	"T": ["111", "010", "010", "010", "010"],
}
const WORD: String = "ROOT"
const GLYPH_SIZE: Vector2i = Vector2i(3, 5)
const GLYPH_GAP: int = 1
const PADDING: Vector2i = Vector2i(2, 2)
const LED_SIZE: Vector2 = Vector2(2.0, 2.0)
const FRAME_COLOR: Color = Color("0b1016")
const BACK_COLOR: Color = Color("2a1240")
const TEXT_COLOR: Color = Color("d9a8ff")
const LED_LOCKED: Color = Color("ff5c5c")
const LED_READY: Color = Color("6be08a")

var ready_to_open: bool = false


func _ready() -> void:
	var glow := CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = glow


func set_ready_to_open(value: bool) -> void:
	if ready_to_open == value:
		return
	ready_to_open = value
	queue_redraw()


func plate_size() -> Vector2i:
	var letters: int = WORD.length()
	var width: int = letters * GLYPH_SIZE.x + (letters - 1) * GLYPH_GAP + PADDING.x * 2
	return Vector2i(width, GLYPH_SIZE.y + PADDING.y * 2 + int(LED_SIZE.y) + 1)


func _draw() -> void:
	var size: Vector2i = plate_size()
	var origin := Vector2(-float(size.x) * 0.5, -float(size.y) * 0.5).round()
	draw_rect(Rect2(origin - Vector2.ONE, Vector2(size) + Vector2(2.0, 2.0)), FRAME_COLOR)
	draw_rect(Rect2(origin, Vector2(size)), BACK_COLOR)
	var cursor: Vector2 = origin + Vector2(PADDING)
	for letter: String in WORD:
		var rows: Array = GLYPHS.get(letter, [])
		for row: int in range(rows.size()):
			var line: String = rows[row]
			for column: int in range(line.length()):
				if line[column] == "1":
					draw_rect(Rect2(cursor + Vector2(column, row), Vector2.ONE), TEXT_COLOR)
		cursor.x += float(GLYPH_SIZE.x + GLYPH_GAP)
	var led_origin := Vector2(
		-LED_SIZE.x * 0.5, origin.y + float(size.y) - LED_SIZE.y - 1.0
	).round()
	draw_rect(Rect2(led_origin, LED_SIZE), LED_READY if ready_to_open else LED_LOCKED)
