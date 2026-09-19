extends Control

const BACKGROUND_FAR: String = "res://assets/backgrounds/space_far.png"
const CLOSING_TEXT: String = "A ESTUFA VOLTOU A RESPIRAR. A ESTAÇÃO AINDA NÃO."
const ROW_LABEL_COLOR: Color = Color(0.541176, 0.607843, 0.658824)
const ROW_VALUE_COLOR: Color = Color(0.372549, 0.831373, 0.784314)
const ROW_HEIGHT: int = 14

@onready var stars: TextureRect = %Stars
@onready var stats: VBoxContainer = %Stats
@onready var closing: Label = %Closing
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	get_tree().paused = false
	stars.texture = AssetResolver.texture(BACKGROUND_FAR)
	closing.text = CLOSING_TEXT
	_build_stats()
	AudioManager.play_music(&"menu")
	menu_button.pressed.connect(_on_menu)
	menu_button.focus_entered.connect(_play_move)
	menu_button.grab_focus()


func _build_stats() -> void:
	for child: Node in stats.get_children():
		child.queue_free()
	for row: PackedStringArray in RunStats.summary_rows(GameState):
		stats.add_child(_build_row(row[0], row[1]))


func _build_row(name_text: String, value_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	var name_label := Label.new()
	name_label.text = name_text
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", ROW_LABEL_COLOR)
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", ROW_VALUE_COLOR)
	row.add_child(value_label)
	return row


func _on_menu() -> void:
	AudioManager.play_sfx(&"ui_confirm")
	SceneManager.goto(ScenePaths.MAIN_MENU)


func _play_move() -> void:
	AudioManager.play_sfx(&"ui_move")
