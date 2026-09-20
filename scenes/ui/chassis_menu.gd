extends CanvasLayer

const TEXTS_PATH: String = "res://data/ui/chassis_menu.json"
const HUD_SHEET: String = "res://assets/ui/hud_sheet.png"
const HUD_FRAME: Vector2i = Vector2i(16, 16)
const HUD_COLUMNS: int = 8
const ABILITY_PREFIX: String = "ability_"
const GAMEPLAY_GROUP: StringName = &"gameplay"
const ROW_HEIGHT: float = 16.0
const COLOR_ABILITY: Color = Color(0.843137, 0.890196, 0.909804)
const COLOR_EMPTY: Color = Color(0.309804, 0.356863, 0.4)
const COLOR_VALUE: Color = Color(0.843137, 0.890196, 0.909804)
const COLOR_CRITICAL: Color = Color(1.0, 0.360784, 0.360784)

var is_open: bool = false

var _texts: Dictionary = {}

@onready var _title: Label = %Title
@onready var _reactor_label: Label = %ReactorLabel
@onready var _reactor_value: Label = %ReactorValue
@onready var _reactor_bar: ProgressBar = %ReactorBar
@onready var _integrity_label: Label = %IntegrityLabel
@onready var _integrity_value: Label = %IntegrityValue
@onready var _charge_label: Label = %ChargeLabel
@onready var _charge_value: Label = %ChargeValue
@onready var _logs_label: Label = %LogsLabel
@onready var _logs_icon: TextureRect = %LogsIcon
@onready var _logs_value: Label = %LogsValue
@onready var _research_label: Label = %ResearchLabel
@onready var _research_icon: TextureRect = %ResearchIcon
@onready var _research_value: Label = %ResearchValue
@onready var _abilities_title: Label = %AbilitiesTitle
@onready var _abilities: VBoxContainer = %Abilities
@onready var _locked_title: Label = %LockedTitle
@onready var _map_label: Label = %MapLabel
@onready var _map_value: Label = %MapValue
@onready var _sectors_label: Label = %SectorsLabel
@onready var _sectors_value: Label = %SectorsValue
@onready var _footer: Label = %Footer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	is_open = false
	_texts = HudModel.load_texts(TEXTS_PATH)
	_apply_static_texts()
	_apply_counter_icons()


func _input(event: InputEvent) -> void:
	if not is_open:
		if not event.is_action_pressed(&"map"):
			return
		if not can_open():
			return
		get_viewport().set_input_as_handled()
		open()
		return
	if (
		event.is_action_pressed(&"map")
		or event.is_action_pressed(&"ui_cancel")
		or event.is_action_pressed(&"pause")
	):
		get_viewport().set_input_as_handled()
		close()


func can_open() -> bool:
	if is_open or not is_inside_tree():
		return false
	var tree: SceneTree = get_tree()
	if tree == null or tree.paused:
		return false
	if SceneManager.is_transitioning():
		return false
	if DialogueManager.is_active() and DialogueManager.freezes_timer():
		return false
	if GameState.is_dead():
		return false
	var viewport: Viewport = get_viewport()
	if viewport != null and viewport.gui_get_focus_owner() != null:
		return false
	var scene: Node = tree.current_scene
	if scene == null:
		return false
	if ScenePaths.is_level(scene.scene_file_path):
		return true
	return scene.is_in_group(GAMEPLAY_GROUP)


func open() -> void:
	if is_open:
		return
	is_open = true
	_refresh()
	visible = true
	get_tree().paused = true
	EventBus.game_paused.emit(true)
	AudioManager.play_sfx(&"ui_confirm")


func close() -> void:
	if not is_open:
		return
	is_open = false
	visible = false
	get_tree().paused = false
	EventBus.game_paused.emit(false)
	AudioManager.play_sfx(&"ui_back")


func _apply_static_texts() -> void:
	_title.text = _text(&"title")
	_reactor_label.text = _text(&"reactor_label")
	_integrity_label.text = _text(&"integrity_label")
	_charge_label.text = _text(&"charge_label")
	_logs_label.text = _text(&"logs_label")
	_research_label.text = _text(&"research_label")
	_abilities_title.text = _text(&"abilities_title")
	_locked_title.text = _text(&"locked_title")
	_map_label.text = _text(&"map_label")
	_map_value.text = _text(&"map_value")
	_sectors_label.text = _text(&"sectors_label")
	_sectors_value.text = _text(&"sectors_value")
	_footer.text = _text(&"footer")


func _apply_counter_icons() -> void:
	_logs_icon.texture = _counter_icon(HudModel.ICON_LOG)
	_research_icon.texture = _counter_icon(HudModel.ICON_RESEARCH)


func _counter_icon(index: int) -> Texture2D:
	var cell: Vector2i = HudModel.atlas_cell(index, HUD_COLUMNS)
	return AssetResolver.atlas(HUD_SHEET, HUD_FRAME, cell.x, cell.y)


func _refresh() -> void:
	_refresh_reactor()
	_integrity_value.text = _pair(GameState.integrity, GameState.integrity_max)
	_charge_value.text = _pair(int(roundf(GameState.charge)), int(roundf(GameState.charge_max)))
	_logs_value.text = _pair(GameState.logs_collected.size(), Balance.LOGS_TOTAL)
	_research_value.text = _pair(GameState.research_collected.size(), Balance.RESEARCH_TOTAL)
	_refresh_abilities()


func _refresh_reactor() -> void:
	_reactor_bar.max_value = Balance.REACTOR_START
	if not GameState.is_reactor_online():
		_reactor_bar.value = 0.0
		_reactor_value.text = _text(&"reactor_offline")
		_reactor_value.add_theme_color_override("font_color", COLOR_EMPTY)
		return
	var percent: float = clampf(GameState.reactor_percent, 0.0, Balance.REACTOR_START)
	_reactor_bar.value = percent
	_reactor_value.text = HudModel.format_single(
		_text(&"reactor_value"), ReactorClock.display_percent(percent)
	)
	var critical: bool = GameState.is_reactor_critical() and not Settings.no_timer
	_reactor_value.add_theme_color_override(
		"font_color", COLOR_CRITICAL if critical else COLOR_VALUE
	)


func _refresh_abilities() -> void:
	for child: Node in _abilities.get_children():
		_abilities.remove_child(child)
		child.queue_free()
	if GameState.abilities.is_empty():
		_abilities.add_child(_ability_label(_text(&"abilities_empty"), COLOR_EMPTY))
		return
	for ability_id: StringName in GameState.abilities:
		_abilities.add_child(_ability_label(ability_name(ability_id), COLOR_ABILITY))


func ability_name(ability_id: StringName) -> String:
	var named: String = _text(StringName(ABILITY_PREFIX + String(ability_id)))
	if named.is_empty():
		return String(ability_id).to_upper()
	return named


func _ability_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = text
	return label


func _pair(current: int, total: int) -> String:
	return HudModel.format_pair(_text(&"value_pair"), current, total)


func _text(id: StringName) -> String:
	return HudModel.text_for(id, _texts)
