class_name SectorPlate
extends Node2D

const PIXEL: int = 2
const BORDER: int = 2
const LED_SIZE: Vector2 = Vector2(6.0, 2.0)
const FRAME_COLOR: Color = Color("0b1016")
const BACK_COLOR: Color = Color("18232e")

var sector_id: StringName = &""

var _cells: Array[Vector2i] = []
var _color: Color = Color.WHITE
var _shows_status: bool = false


func _ready() -> void:
	var glow := CanvasItemMaterial.new()
	glow.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = glow
	Settings.accessibility_changed.connect(queue_redraw)


func setup(id: StringName, table: Dictionary) -> void:
	sector_id = id
	_cells = SectorCatalog.icon_cells(SectorCatalog.icon(id, table))
	_color = SectorCatalog.color(id, table)
	_shows_status = not SectorCatalog.is_hub(id, table)
	queue_redraw()


func plate_size() -> int:
	return SectorCatalog.ICON_SIZE * PIXEL + BORDER * 2


func is_restored() -> bool:
	return SectorRevisit.is_restored(sector_id, GameState.sectors_restored)


func shows_status() -> bool:
	return _shows_status


func _draw() -> void:
	var side: float = float(plate_size())
	var origin := Vector2(-side * 0.5, -side * 0.5)
	draw_rect(Rect2(origin, Vector2(side, side)), FRAME_COLOR)
	draw_rect(Rect2(origin + Vector2.ONE, Vector2(side - 2.0, side - 2.0)), BACK_COLOR)
	for cell: Vector2i in _cells:
		var offset := Vector2(float(BORDER + cell.x * PIXEL), float(BORDER + cell.y * PIXEL))
		draw_rect(Rect2(origin + offset, Vector2(PIXEL, PIXEL)), _color)
	if not _shows_status:
		return
	var led := Rect2(Vector2(-LED_SIZE.x * 0.5, side * 0.5 - LED_SIZE.y), LED_SIZE)
	draw_rect(led, _led_restored() if is_restored() else _led_pending())


func _led_restored() -> Color:
	return Settings.signal_color(Accessibility.ROLE_SECTOR_RESTORED)


func _led_pending() -> Color:
	return Settings.signal_color(Accessibility.ROLE_SECTOR_PENDING)
