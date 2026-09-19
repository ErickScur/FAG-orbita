extends Control

const ZOOM: int = 4
const ITEMS: Array[Dictionary] = [
	{
		"label": "MU-7 32x32",
		"path": "res://assets/sprites/mu7/mu7_sheet.png",
		"frame": Vector2i(32, 32),
		"cell": Vector2i(0, 0),
		"position": Vector2(24, 56),
	},
	{
		"label": "NÚCLEO 16x16",
		"path": "res://assets/tiles/core_tiles.png",
		"frame": Vector2i(16, 16),
		"cell": Vector2i(0, 0),
		"position": Vector2(172, 72),
	},
	{
		"label": "ESTUFA 16x16",
		"path": "res://assets/tiles/greenhouse_tiles.png",
		"frame": Vector2i(16, 16),
		"cell": Vector2i(0, 0),
		"position": Vector2(268, 72),
	},
]


func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.043137, 0.058824, 0.078431, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var title := Label.new()
	title.text = "CONTATO-PROVA DE PLACEHOLDERS"
	title.position = Vector2(0, 12)
	title.size = Vector2(384, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	for item: Dictionary in ITEMS:
		_build_item(item)


func _build_item(item: Dictionary) -> void:
	var path: String = String(item["path"])
	var frame: Vector2i = item["frame"]
	var cell: Vector2i = item["cell"]
	var origin: Vector2 = item["position"]
	var view := TextureRect.new()
	view.texture = AssetResolver.atlas(path, frame, cell.x, cell.y)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_SCALE
	view.position = origin
	view.size = Vector2(frame) * float(ZOOM)
	add_child(view)
	var caption := Label.new()
	caption.text = String(item["label"])
	caption.position = Vector2(origin.x - 12.0, origin.y + view.size.y + 4.0)
	caption.size = Vector2(view.size.x + 24.0, 12.0)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(caption)
	var source := Label.new()
	source.text = "placeholder" if AssetResolver.is_placeholder(path) else "definitivo"
	source.position = Vector2(origin.x - 12.0, origin.y + view.size.y + 16.0)
	source.size = Vector2(view.size.x + 24.0, 12.0)
	source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	source.add_theme_color_override("font_color", Color(0.372549, 0.831373, 0.784314, 1.0))
	add_child(source)
