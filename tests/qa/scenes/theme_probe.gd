extends Control

const SPARK_SCENE: String = "res://scenes/fx/spark_burst.tscn"
const ACCENT_TEXT: String = "ÓRBITA ÁÃÇÉÊÍÓÔÕÚ áãçéêíóôõú"
const SAMPLES: Array[Dictionary] = [
	{"path": "res://assets/sprites/mu7/mu7_sheet.png", "frame": Vector2i(32, 32), "cell": Vector2i(0, 0)},
	{"path": "res://assets/sprites/enemies/sr3_sheet.png", "frame": Vector2i(32, 16), "cell": Vector2i(0, 0)},
	{"path": "res://assets/sprites/world/terminal_sheet.png", "frame": Vector2i(32, 32), "cell": Vector2i(1, 0)},
	{"path": "res://assets/sprites/world/dock_sheet.png", "frame": Vector2i(32, 48), "cell": Vector2i(2, 0)},
	{"path": "res://assets/sprites/pickups/pickups_sheet.png", "frame": Vector2i(16, 16), "cell": Vector2i(0, 0)},
	{"path": "res://assets/sprites/world/grow_plant_sheet.png", "frame": Vector2i(32, 64), "cell": Vector2i(5, 0)},
	{"path": "res://assets/tiles/core_tiles.png", "frame": Vector2i(16, 16), "cell": Vector2i(0, 0)},
	{"path": "res://assets/tiles/greenhouse_tiles.png", "frame": Vector2i(16, 16), "cell": Vector2i(0, 0)},
	{"path": "res://assets/ui/hud_sheet.png", "frame": Vector2i(16, 16), "cell": Vector2i(0, 0)},
	{"path": "res://assets/sprites/world/door_sheet.png", "frame": Vector2i(16, 48), "cell": Vector2i(0, 0)},
	{"path": "res://assets/sprites/npc/botanico_sheet.png", "frame": Vector2i(16, 16), "cell": Vector2i(0, 0)},
	{"path": "res://assets/sprites/props/props_sheet.png", "frame": Vector2i(32, 32), "cell": Vector2i(0, 0)},
]

var _spark: SparkBurst = null
var _first_button: Button = null


func _ready() -> void:
	_build_background()
	_build_widgets()
	_build_gallery()
	_build_spark()
	if _first_button != null:
		_first_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"):
		return
	if _spark == null:
		return
	_spark.emit(size * 0.5, SparkBurst.DEFAULT_TINT, false)


func _build_background() -> void:
	var background := ColorRect.new()
	background.color = Color(0.043137, 0.058824, 0.078431, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)


func _build_widgets() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(6, 6)
	panel.size = Vector2(186, 204)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)
	var title := Label.new()
	title.text = "SONDA DE TEMA"
	column.add_child(title)
	var accents := Label.new()
	accents.text = ACCENT_TEXT
	accents.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(accents)
	_first_button = Button.new()
	_first_button.text = "CONTINUAR"
	column.add_child(_first_button)
	var disabled := Button.new()
	disabled.text = "SELADO"
	disabled.disabled = true
	column.add_child(disabled)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(0, 10)
	slider.value = 70.0
	column.add_child(slider)
	var check := CheckBox.new()
	check.text = "MODO SEM TIMER"
	check.button_pressed = true
	column.add_child(check)
	var options := OptionButton.new()
	options.add_item("NORMAL")
	options.add_item("FÁCIL")
	column.add_child(options)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 8)
	bar.value = 60.0
	column.add_child(bar)


func _build_gallery() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(198, 6)
	panel.size = Vector2(180, 204)
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	panel.add_child(grid)
	for sample: Dictionary in SAMPLES:
		var slot := TextureRect.new()
		slot.custom_minimum_size = Vector2(42, 48)
		slot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		slot.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.texture = AssetResolver.atlas(
			String(sample["path"]), sample["frame"], sample["cell"].x, sample["cell"].y
		)
		grid.add_child(slot)


func _build_spark() -> void:
	if not ResourceLoader.exists(SPARK_SCENE):
		return
	var packed: PackedScene = load(SPARK_SCENE)
	var instance: Node = packed.instantiate()
	if not (instance is SparkBurst):
		instance.queue_free()
		return
	_spark = instance
	add_child(_spark)
