extends CanvasLayer

signal closed()

const ROW_HEIGHT: float = 17.0
const LAMP_SIZE: Vector2 = Vector2(8.0, 8.0)
const CELL_SIZE: Vector2 = Vector2(6.0, 10.0)
const TAG_WIDTH: float = 46.0
const COST_WIDTH: float = 22.0
const STATE_WIDTH: float = 74.0
const ROW_MARGIN: float = 4.0
const COLOR_ON: Color = Color(0.372549, 0.831373, 0.784314, 1.0)
const COLOR_OFF: Color = Color(0.184314, 0.309804, 0.352941, 1.0)
const COLOR_LOCKED: Color = Color(0.337255, 0.376471, 0.415686, 1.0)
const COLOR_TEXT: Color = Color(0.843137, 0.890196, 0.909804, 1.0)
const COLOR_MUTED: Color = Color(0.552941, 0.65098, 0.686275, 1.0)
const COLOR_ALERT: Color = Color(0.85098, 0.32549, 0.309804, 1.0)
const COLOR_GOAL: Color = Color(0.878431, 0.705882, 0.235294, 1.0)
const STATE_ON: String = "LIGADO"
const STATE_OFF: String = "DESLIGADO"
const STATE_LOCKED: String = "SELADO"
const STATE_BLOCKED: String = "REQUER"
const TEXT_NO_BUDGET: String = "ENERGIA INSUFICIENTE - DESLIGUE UM SISTEMA"
const TEXT_NO_BUDGET_LIST: String = "ENERGIA INSUFICIENTE - DESLIGUE: %s"
const TEXT_TRADE: String = "LIGAR EXIGE DESLIGAR: %s"
const TEXT_OR: String = " ou "
const TEXT_GOAL: String = "META: %s"
const TEXT_GOAL_DONE: String = "META CUMPRIDA: %s"
const TEXT_ENABLE: String = "AO LIGAR: %s"
const TEXT_DISABLE: String = "AO DESLIGAR: %s"
const TEXT_LOCKED: String = "CIRCUITO SELADO"
const TEXT_UNAVAILABLE: String = "SISTEMA INDISPONÍVEL"
const TEXT_REQUIRES: String = "REQUER: %s"
const TEXT_ONLINE: String = "%s: ONLINE"
const TEXT_OFFLINE: String = "%s: OFFLINE"
const TEXT_CASCADE: String = "DESLIGADO EM CADEIA: %s"
const TEXT_BUDGET: String = "ORÇAMENTO DE ENERGIA: %d/%d EM USO"

var _terminal_id: StringName = &""
var _network: EnergyNetwork = null
var _grid: EnergyGrid = null
var _ids: Array[StringName] = []
var _rows: Array[Button] = []
var _lamps: Array[ColorRect] = []
var _names: Array[Label] = []
var _tags: Array[Label] = []
var _costs: Array[Label] = []
var _states: Array[Label] = []
var _cells: Array[ColorRect] = []
var _trap: FocusTrap = FocusTrap.new()
var _selected: int = -1
var _message_left: float = 0.0
var _opened_frame: int = -1
var _closing: bool = false

@onready var _title: Label = %Title
@onready var _goal: Label = %Goal
@onready var _budget: Label = %Budget
@onready var _meter: HBoxContainer = %Meter
@onready var _list: VBoxContainer = %List
@onready var _description: Label = %Description
@onready var _message: Label = %Message


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_message.text = ""
	_description.text = ""
	_goal.text = ""


func _process(delta: float) -> void:
	if _message_left <= 0.0:
		return
	_message_left = maxf(0.0, _message_left - delta)
	if _message_left <= 0.0:
		_refresh_hint()


func _input(event: InputEvent) -> void:
	if _grid == null or _closing:
		return
	if Engine.get_process_frames() == _opened_frame:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		close()
		return
	if event.is_action_pressed(&"interact"):
		get_viewport().set_input_as_handled()
		toggle_selected()
		return
	if event.is_action_pressed(&"move_down"):
		get_viewport().set_input_as_handled()
		_step(1)
		return
	if event.is_action_pressed(&"move_up"):
		get_viewport().set_input_as_handled()
		_step(-1)


func open(terminal_id: StringName, network: EnergyNetwork) -> void:
	_terminal_id = terminal_id
	_network = network
	_grid = network.grid(terminal_id) if network != null else null
	if _grid == null:
		push_warning("EnergyTerminalUI: terminal '%s' não carregado" % terminal_id)
		close()
		return
	_title.text = _grid.title
	_build_rows()
	_refresh()
	_opened_frame = Engine.get_process_frames()
	AudioManager.play_sfx(&"ui_confirm")
	var allowed: Array[Control] = []
	for row: Button in _rows:
		allowed.append(row)
	_trap.capture(allowed)
	if not _rows.is_empty():
		_rows[0].grab_focus()


func close() -> void:
	if _closing:
		return
	_closing = true
	_trap.release()
	AudioManager.play_sfx(&"ui_back")
	closed.emit()
	queue_free()


func toggle_selected() -> void:
	if _grid == null or _selected < 0 or _selected >= _ids.size():
		return
	var system_id: StringName = _ids[_selected]
	var outcome: Dictionary = _network.toggle(_terminal_id, system_id)
	_report(system_id, outcome)
	_refresh()


func selected_index() -> int:
	return _selected


func system_rows() -> Array[Button]:
	return _rows.duplicate()


func _build_rows() -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_ids = _grid.system_ids()
	_rows.clear()
	_lamps.clear()
	_names.clear()
	_tags.clear()
	_costs.clear()
	_states.clear()
	for index: int in range(_ids.size()):
		_list.add_child(_make_row(index))
	_build_meter()


func _make_row(index: int) -> Button:
	var button := Button.new()
	button.name = "Row%d" % index
	button.custom_minimum_size = Vector2(0.0, ROW_HEIGHT)
	button.focus_mode = Control.FOCUS_ALL
	button.pressed.connect(_on_row_pressed.bind(index))
	button.focus_entered.connect(_on_row_focused.bind(index))
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = ROW_MARGIN
	row.offset_right = -ROW_MARGIN
	row.add_theme_constant_override(&"separation", 4)
	var lamp := ColorRect.new()
	lamp.custom_minimum_size = LAMP_SIZE
	lamp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tag := Label.new()
	tag.custom_minimum_size = Vector2(TAG_WIDTH, 0.0)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.clip_text = true
	var title := Label.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.clip_text = true
	var cost := Label.new()
	cost.custom_minimum_size = Vector2(COST_WIDTH, 0.0)
	cost.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var state := Label.new()
	state.custom_minimum_size = Vector2(STATE_WIDTH, 0.0)
	state.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lamp)
	row.add_child(tag)
	row.add_child(title)
	row.add_child(cost)
	row.add_child(state)
	button.add_child(row)
	_rows.append(button)
	_lamps.append(lamp)
	_tags.append(tag)
	_names.append(title)
	_costs.append(cost)
	_states.append(state)
	return button


func _build_meter() -> void:
	for child: Node in _meter.get_children():
		_meter.remove_child(child)
		child.queue_free()
	_cells.clear()
	for index: int in range(_grid.budget):
		var cell := ColorRect.new()
		cell.custom_minimum_size = CELL_SIZE
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_meter.add_child(cell)
		_cells.append(cell)


func _refresh() -> void:
	if _grid == null:
		return
	var used: int = _grid.used()
	_budget.text = TEXT_BUDGET % [used, _grid.budget]
	_refresh_goal()
	for index: int in range(_cells.size()):
		_cells[index].color = COLOR_ON if index < used else COLOR_OFF
	for index: int in range(_ids.size()):
		_refresh_row(index)
	_refresh_description()
	if _message_left <= 0.0:
		_refresh_hint()


func _refresh_row(index: int) -> void:
	var system_id: StringName = _ids[index]
	var on: bool = _grid.is_powered(system_id)
	var locked: bool = _grid.is_locked(system_id)
	var blocked: bool = not on and _grid.missing_requirement(system_id) != &""
	_names[index].text = _grid.system_name(system_id)
	_tags[index].text = _grid.tag_of(system_id)
	_costs[index].text = "%du" % _grid.cost_of(system_id)
	if locked:
		_lamps[index].color = COLOR_LOCKED
		_states[index].text = STATE_LOCKED
	elif on:
		_lamps[index].color = COLOR_ON
		_states[index].text = STATE_ON
	elif blocked:
		_lamps[index].color = COLOR_LOCKED
		_states[index].text = STATE_BLOCKED
	else:
		_lamps[index].color = COLOR_OFF
		_states[index].text = STATE_OFF
	var tint: Color = COLOR_LOCKED if locked or blocked else COLOR_TEXT
	_names[index].add_theme_color_override(&"font_color", tint)
	_costs[index].add_theme_color_override(&"font_color", tint)
	_states[index].add_theme_color_override(&"font_color", tint)
	var goal: bool = _grid.goal_systems().has(system_id)
	_tags[index].add_theme_color_override(
		&"font_color", COLOR_GOAL if goal and not locked else tint
	)


func _refresh_goal() -> void:
	var text: String = _grid.goal_line()
	if text.is_empty():
		_goal.text = ""
		return
	var done: bool = _grid.goal_met()
	_goal.text = (TEXT_GOAL_DONE if done else TEXT_GOAL) % text
	_goal.add_theme_color_override(&"font_color", COLOR_ON if done else COLOR_GOAL)


func _refresh_description() -> void:
	if _selected < 0 or _selected >= _ids.size():
		_description.text = ""
		return
	var system_id: StringName = _ids[_selected]
	var on: bool = _grid.is_powered(system_id)
	var text: String = (
		TEXT_DISABLE % _grid.effect_off_of(system_id)
		if on
		else TEXT_ENABLE % _grid.system_description(system_id)
	)
	var missing: StringName = _grid.missing_requirement(system_id)
	if not on and missing != &"":
		text = "%s · %s" % [TEXT_REQUIRES % _grid.system_name(missing), text]
	_description.text = text


func _refresh_hint() -> void:
	if _selected < 0 or _selected >= _ids.size():
		_message.text = ""
		return
	var names: String = _candidate_names(_ids[_selected])
	_message.text = "" if names.is_empty() else TEXT_TRADE % names
	_message.add_theme_color_override(&"font_color", COLOR_MUTED)


func _candidate_names(system_id: StringName) -> String:
	if _grid == null or not _grid.has_system(system_id):
		return ""
	var candidates: Array[StringName] = _grid.shutdown_candidates(system_id)
	if candidates.is_empty():
		return ""
	var names := PackedStringArray()
	for candidate: StringName in candidates:
		names.append(_grid.system_name(candidate))
	return TEXT_OR.join(names)


func _step(direction: int) -> void:
	if _rows.is_empty():
		return
	var total: int = _rows.size()
	var next: int = posmod(_selected + direction, total)
	_rows[next].grab_focus()


func _report(system_id: StringName, outcome: Dictionary) -> void:
	var code: int = int(outcome["result"])
	var switched_on: Array[StringName] = outcome["on"]
	var switched_off: Array[StringName] = outcome["off"]
	if code != EnergyGrid.Result.OK:
		_show_message(_failure_text(system_id, code), COLOR_ALERT)
		return
	if not switched_on.is_empty():
		_show_message(TEXT_ONLINE % _grid.system_name(system_id), COLOR_ON)
		return
	if switched_off.size() > 1:
		var names := PackedStringArray()
		for index: int in range(1, switched_off.size()):
			names.append(_grid.system_name(switched_off[index]))
		_show_message(TEXT_CASCADE % ", ".join(names), COLOR_ALERT)
		return
	_show_message(TEXT_OFFLINE % _grid.system_name(system_id), COLOR_MUTED)


func _failure_text(system_id: StringName, code: int) -> String:
	match code:
		EnergyGrid.Result.NO_BUDGET:
			var names: String = _candidate_names(system_id)
			return TEXT_NO_BUDGET if names.is_empty() else TEXT_NO_BUDGET_LIST % names
		EnergyGrid.Result.MISSING_DEPENDENCY:
			return TEXT_REQUIRES % _grid.system_name(_grid.missing_requirement(system_id))
		EnergyGrid.Result.LOCKED:
			return TEXT_LOCKED
	return TEXT_UNAVAILABLE


func _show_message(text: String, color: Color) -> void:
	_message.text = text
	_message.add_theme_color_override(&"font_color", color)
	_message_left = Balance.HUD_TOAST_TIME


func _on_row_pressed(index: int) -> void:
	_selected = index
	toggle_selected()


func _on_row_focused(index: int) -> void:
	if _selected == index:
		return
	_selected = index
	AudioManager.play_sfx(&"ui_move")
	_message_left = 0.0
	_refresh_description()
	_refresh_hint()
