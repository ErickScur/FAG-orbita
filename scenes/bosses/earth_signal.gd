class_name EarthSignal
extends CanvasLayer

const LAYER: int = UiLayers.EARTH_SIGNAL
const BOX_RECT: Rect2 = Rect2(96, 36, 192, 48)
const WAVE_RECT: Rect2 = Rect2(104, 40, 176, 22)
const LABEL_RECT: Rect2 = Rect2(96, 64, 192, 16)
const BOX_COLOR: Color = Color(0.02, 0.03, 0.05, 0.82)
const FRAME_COLOR: Color = Color("2b3f52")
const WAVE_COLOR: Color = Color("7fe3f0")
const NOISE_COLOR: Color = Color("6f9ab8")
const LABEL_COLOR: Color = Color("c8ecff")
const TEXT: String = "SINAL FRACO · DIREÇÃO: TERRA"
const CARRIER_CYCLES: float = 11.0
const CARRIER_SPEED: float = 5.0
const PULSE_CYCLES: float = 8.0
const PULSE_PERIOD: float = 2.4
const PULSE_WIDTH: float = 0.18
const FONT_SIZE: int = 16

var _canvas: Control = null
var _label: Label = null
var _elapsed: float = 0.0


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_canvas = Control.new()
	_canvas.name = "Wave"
	_canvas.position = Vector2.ZERO
	_canvas.size = Vector2(384, 216)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_wave)
	add_child(_canvas)
	_label = Label.new()
	_label.name = "Label"
	_label.text = TEXT
	_label.position = LABEL_RECT.position
	_label.size = LABEL_RECT.size
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", LABEL_COLOR)
	add_child(_label)


func _process(delta: float) -> void:
	_elapsed += delta
	_canvas.queue_redraw()


func text() -> String:
	return _label.text if _label != null else TEXT


func _draw_wave() -> void:
	_canvas.draw_rect(BOX_RECT, BOX_COLOR)
	_canvas.draw_rect(BOX_RECT, FRAME_COLOR, false, 1.0)
	var middle: float = floorf(WAVE_RECT.position.y + WAVE_RECT.size.y * 0.5)
	var phase: float = fmod(_elapsed, PULSE_PERIOD) / PULSE_PERIOD
	var width: int = int(WAVE_RECT.size.x)
	var noise_points := PackedVector2Array()
	var pulse_points := PackedVector2Array()
	for index: int in range(width + 1):
		var ratio: float = float(index) / float(width)
		var x: float = WAVE_RECT.position.x + float(index)
		var carrier: float = roundf(sin(ratio * TAU * CARRIER_CYCLES + _elapsed * CARRIER_SPEED))
		var distance: float = absf(ratio - phase)
		var pulse: float = 0.0
		if distance < PULSE_WIDTH:
			var local: float = 1.0 - distance / PULSE_WIDTH
			pulse = sin(ratio * TAU * PULSE_CYCLES) * local * WAVE_RECT.size.y * 0.45
		var point := Vector2(x, middle + roundf(pulse) + (carrier if pulse == 0.0 else 0.0))
		noise_points.append(point)
		if pulse != 0.0:
			pulse_points.append(point)
	_canvas.draw_polyline(noise_points, NOISE_COLOR, -1.0)
	if pulse_points.size() > 1:
		_canvas.draw_polyline(pulse_points, WAVE_COLOR, -1.0)
