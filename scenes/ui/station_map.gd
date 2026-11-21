extends Control

signal closed()

const TEXTS_PATH: String = "res://data/ui/station_map.json"
const LOGS_DIR: String = "res://data/logs/"
const FOOTER_CHASSIS: StringName = &"footer_chassis"
const FOOTER_OVERLAY: StringName = &"footer_overlay"
const SCREEN_SIZE: Vector2 = Vector2(384.0, 216.0)
const FRAME_RECT: Rect2 = Rect2(8.0, 18.0, 368.0, 138.0)
const GRID_STEP: int = 16
const COLUMN_SPACING: float = 120.0
const ROW_SPACING: float = 34.0
const FIRST_ROW_Y: float = 32.0
const BOX_HEIGHT: float = 18.0
const CENTER_BOX_WIDTH: float = 112.0
const SIDE_BOX_WIDTH: float = 96.0
const BRANCH_OFFSET: float = 24.0
const CORRIDOR_WALL: float = 4.0
const CORRIDOR_INNER: float = 2.0
const DASH_LENGTH: int = 2
const FOCUS_EXPAND: float = 2.0
const BLINK_PERIOD: float = 0.5
const LINE_HEIGHT: float = 16.0
const TITLE_Y: float = 1.0
const INFO_Y: float = 158.0
const FOOTER_Y: float = 198.0
const TEXT_MARGIN: float = 12.0
const COLOR_BACKGROUND: Color = Color(0.019608, 0.043137, 0.070588)
const COLOR_PAPER: Color = Color(0.043137, 0.113725, 0.180392)
const COLOR_GRID: Color = Color(0.066667, 0.156863, 0.239216)
const COLOR_FRAME: Color = Color(0.168627, 0.345098, 0.470588)
const COLOR_TITLE: Color = Color(0.372549, 0.831373, 0.784314)
const COLOR_LABEL: Color = Color(0.541176, 0.607843, 0.658824)
const COLOR_VALUE: Color = Color(0.843137, 0.890196, 0.909804)
const COLOR_HERE: Color = Color(0.372549, 0.831373, 0.784314)
const COLOR_LIT: Color = Color(0.909804, 0.941176, 0.956863)
const LIT_CORRIDOR_ALPHA: float = 0.35
const STATE_STYLE: Dictionary = {
	&"restored": {
		"wall": Color(0.909804, 0.941176, 0.956863),
		"fill": Color(0.121569, 0.27451, 0.376471),
		"text": Color(0.968627, 0.984314, 1.0),
		"rank": 3,
	},
	&"visited": {
		"wall": Color(0.498039, 0.552941, 0.596078),
		"fill": Color(0.07451, 0.156863, 0.227451),
		"text": Color(0.603922, 0.65098, 0.682353),
		"rank": 2,
	},
	&"sealed": {
		"wall": Color(0.247059, 0.329412, 0.407843),
		"fill": Color(0.043137, 0.113725, 0.180392),
		"text": Color(0.490196, 0.560784, 0.627451),
		"rank": 1,
	},
	&"unknown": {
		"wall": Color(0.211765, 0.290196, 0.364706),
		"fill": Color(0.043137, 0.113725, 0.180392),
		"text": Color(0.352941, 0.458824, 0.564706),
		"rank": 0,
	},
}
const STATE_TEXT: Dictionary = {
	&"restored": &"state_restored",
	&"visited": &"state_visited",
	&"sealed": &"state_sealed",
	&"unknown": &"state_unknown",
}
const PADLOCK_COLOR: Color = Color(0.835294, 0.866667, 0.890196)
const PADLOCK_HOLE: Color = Color(0.043137, 0.113725, 0.180392)

@export var standalone: bool = true
@export var footer_id: StringName = FOOTER_OVERLAY

var _texts: Dictionary = {}
var _sectors: Array[Dictionary] = []
var _hub: StringName = &""
var _logs: Dictionary = {}
var _snap: Dictionary = {}
var _states: Dictionary = {}
var _buttons: Dictionary = {}
var _selected: StringName = &""
var _current: StringName = &""
var _blink_on: bool = true
var _blink_left: float = BLINK_PERIOD
var _silent_focus: bool = false
var _title: Label = null
var _count: Label = null
var _info_name: Label = null
var _info_here: Label = null
var _info_state: Label = null
var _info_detail: Label = null
var _footer: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texts = HudModel.load_texts(TEXTS_PATH)
	var station: Dictionary = StationMapModel.load_station()
	_sectors = station["sectors"]
	_hub = station["hub"]
	_build_labels()
	_build_buttons()
	refresh()
	if standalone:
		focus_default()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_blink_left -= delta
	if _blink_left > 0.0:
		return
	_blink_left = BLINK_PERIOD
	_blink_on = not _blink_on
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not standalone or not is_visible_in_tree():
		return
	if (
		event.is_action_pressed(&"ui_cancel")
		or event.is_action_pressed(&"pause")
		or event.is_action_pressed(&"map")
	):
		get_viewport().set_input_as_handled()
		close()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), COLOR_BACKGROUND)
	draw_rect(FRAME_RECT, COLOR_PAPER)
	_draw_grid()
	_draw_outline(FRAME_RECT, COLOR_FRAME)
	var hub: Dictionary = StationMapModel.find(_sectors, _hub)
	if not hub.is_empty():
		for sector: Dictionary in _sectors_by_rank():
			if sector[StationMapModel.KEY_ID] != _hub:
				_draw_corridor(hub, sector)
	for sector: Dictionary in _sectors:
		_draw_box(sector)
	for sector: Dictionary in _sectors:
		if state_of(sector[StationMapModel.KEY_ID]) == StationMapModel.STATE_SEALED:
			_draw_padlock(_door_point(hub, sector))
	if _blink_on and _current != &"":
		var current: Dictionary = StationMapModel.find(_sectors, _current)
		if not current.is_empty():
			_draw_marker(box_rect(current))


func refresh() -> void:
	_logs = _load_logs()
	var scene: Node = get_tree().current_scene if is_inside_tree() else null
	var scene_path: String = scene.scene_file_path if scene != null else ""
	_snap = StationMapModel.snapshot(GameState, scene_path)
	_current = StationMapModel.current_sector(_sectors, _snap)
	_states.clear()
	for sector: Dictionary in _sectors:
		_states[sector[StationMapModel.KEY_ID]] = StationMapModel.state_of(sector, _snap, _logs)
	_apply_button_states()
	_count.text = HudModel.format_pair(
		_text(&"restored_count"),
		StationMapModel.restored_count(_sectors, _snap),
		_sectors.size()
	)
	_footer.text = _text(footer_id)
	if _selected == &"" or not _buttons.has(_selected):
		_selected = default_sector()
	_show_info(_selected)
	queue_redraw()


func focus_default() -> void:
	var target: StringName = default_sector()
	if not _buttons.has(target):
		return
	_silent_focus = true
	(_buttons[target] as Button).grab_focus()
	_silent_focus = false
	_select(target)


func release() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var owner_control: Control = viewport.gui_get_focus_owner()
	if owner_control != null and is_ancestor_of(owner_control):
		owner_control.release_focus()


func close() -> void:
	release()
	closed.emit()
	if standalone:
		queue_free()


func default_sector() -> StringName:
	if _current != &"":
		return _current
	return _hub


func selected_sector() -> StringName:
	return _selected


func current_sector() -> StringName:
	return _current


func state_of(sector_id: StringName) -> StringName:
	return StringName(_states.get(sector_id, StationMapModel.STATE_UNKNOWN))


func owns_focus() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return false
	var owner_control: Control = viewport.gui_get_focus_owner()
	return owner_control != null and is_ancestor_of(owner_control)


func button_for(sector_id: StringName) -> Button:
	return _buttons.get(sector_id, null)


func box_rect(sector: Dictionary) -> Rect2:
	var cell: Vector2i = sector[StationMapModel.KEY_CELL]
	var width: float = CENTER_BOX_WIDTH if cell.x == 0 else SIDE_BOX_WIDTH
	var center := Vector2(
		SCREEN_SIZE.x * 0.5 + float(cell.x) * COLUMN_SPACING,
		FIRST_ROW_Y + float(cell.y) * ROW_SPACING
	)
	return Rect2(
		Vector2(roundf(center.x - width * 0.5), roundf(center.y - BOX_HEIGHT * 0.5)),
		Vector2(width, BOX_HEIGHT)
	)


func corridor_points(hub: Dictionary, sector: Dictionary) -> PackedVector2Array:
	var from: Rect2 = box_rect(hub)
	var to: Rect2 = box_rect(sector)
	var delta: Vector2i = (sector[StationMapModel.KEY_CELL] as Vector2i) - (
		hub[StationMapModel.KEY_CELL] as Vector2i
	)
	var from_center: Vector2 = _center(from)
	var to_center: Vector2 = _center(to)
	if delta.y == 0:
		var start_x: float = from.position.x if delta.x < 0 else from.end.x
		var end_x: float = to.end.x if delta.x < 0 else to.position.x
		return PackedVector2Array([Vector2(start_x, to_center.y), Vector2(end_x, to_center.y)])
	var start_y: float = from.end.y if delta.y > 0 else from.position.y
	if delta.x == 0:
		var end_y: float = to.position.y if delta.y > 0 else to.end.y
		return PackedVector2Array([Vector2(to_center.x, start_y), Vector2(to_center.x, end_y)])
	var branch_x: float = from_center.x + signf(float(delta.x)) * BRANCH_OFFSET
	var side_x: float = to.end.x if delta.x < 0 else to.position.x
	return PackedVector2Array([
		Vector2(branch_x, start_y), Vector2(branch_x, to_center.y), Vector2(side_x, to_center.y)
	])


func _build_labels() -> void:
	_title = _make_label(Rect2(TEXT_MARGIN - 4.0, TITLE_Y, 200.0, LINE_HEIGHT), COLOR_TITLE)
	_title.text = _text(&"title")
	_count = _make_label(Rect2(176.0, TITLE_Y, 200.0, LINE_HEIGHT), COLOR_VALUE)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var right_width: float = SCREEN_SIZE.x * 0.5 - TEXT_MARGIN
	_info_name = _make_label(Rect2(TEXT_MARGIN, INFO_Y, 200.0, LINE_HEIGHT), COLOR_VALUE)
	_info_here = _make_label(
		Rect2(SCREEN_SIZE.x * 0.5, INFO_Y, right_width, LINE_HEIGHT), COLOR_HERE
	)
	_info_here.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_info_state = _make_label(
		Rect2(TEXT_MARGIN, INFO_Y + LINE_HEIGHT, 120.0, LINE_HEIGHT), COLOR_LABEL
	)
	_info_detail = _make_label(
		Rect2(120.0, INFO_Y + LINE_HEIGHT, SCREEN_SIZE.x - 120.0 - TEXT_MARGIN, LINE_HEIGHT),
		COLOR_VALUE
	)
	_info_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_footer = _make_label(Rect2(0.0, FOOTER_Y, SCREEN_SIZE.x, LINE_HEIGHT), COLOR_LABEL)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _make_label(rect: Rect2, color: Color) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.position = rect.position
	label.size = rect.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label


func _build_buttons() -> void:
	var focus_style := StyleBoxFlat.new()
	focus_style.draw_center = false
	focus_style.set_border_width_all(1)
	focus_style.border_color = COLOR_TITLE
	focus_style.set_expand_margin_all(FOCUS_EXPAND)
	focus_style.anti_aliasing = false
	var empty := StyleBoxEmpty.new()
	for sector: Dictionary in _sectors:
		var sector_id: StringName = sector[StationMapModel.KEY_ID]
		var button := Button.new()
		button.name = "Sector_%s" % sector_id
		button.text = String(sector[StationMapModel.KEY_NAME])
		button.focus_mode = Control.FOCUS_ALL
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		for style_name: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
			button.add_theme_stylebox_override(style_name, empty)
		button.add_theme_stylebox_override("focus", focus_style)
		var rect: Rect2 = box_rect(sector)
		button.position = rect.position
		button.size = rect.size
		button.focus_entered.connect(_on_button_focused.bind(sector_id))
		add_child(button)
		_buttons[sector_id] = button
	_link_buttons()


func _link_buttons() -> void:
	var ids: Array[StringName] = []
	for sector: Dictionary in _sectors:
		ids.append(sector[StationMapModel.KEY_ID])
	for index: int in range(ids.size()):
		var button: Button = _buttons[ids[index]]
		var own: NodePath = button.get_path_to(button)
		button.focus_neighbor_left = _neighbor_path(button, ids[index], Vector2i.LEFT, own)
		button.focus_neighbor_right = _neighbor_path(button, ids[index], Vector2i.RIGHT, own)
		button.focus_neighbor_top = _neighbor_path(button, ids[index], Vector2i.UP, own)
		button.focus_neighbor_bottom = _neighbor_path(button, ids[index], Vector2i.DOWN, own)
		button.focus_next = button.get_path_to(_buttons[ids[(index + 1) % ids.size()]])
		button.focus_previous = button.get_path_to(
			_buttons[ids[(index - 1 + ids.size()) % ids.size()]]
		)


func _neighbor_path(
	button: Button, sector_id: StringName, direction: Vector2i, fallback: NodePath
) -> NodePath:
	var target: StringName = StationMapModel.neighbor(_sectors, sector_id, direction)
	if target == &"" or not _buttons.has(target):
		return fallback
	return button.get_path_to(_buttons[target])


func _apply_button_states() -> void:
	for sector: Dictionary in _sectors:
		var sector_id: StringName = sector[StationMapModel.KEY_ID]
		var button: Button = _buttons.get(sector_id, null)
		if button == null:
			continue
		var color: Color = _style(state_of(sector_id))["text"]
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_pressed_color", color)


func _on_button_focused(sector_id: StringName) -> void:
	if not _silent_focus and sector_id != _selected:
		AudioManager.play_sfx(&"ui_move")
	_select(sector_id)


func _select(sector_id: StringName) -> void:
	_selected = sector_id
	_show_info(sector_id)


func _show_info(sector_id: StringName) -> void:
	var sector: Dictionary = StationMapModel.find(_sectors, sector_id)
	if sector.is_empty():
		return
	var state: StringName = state_of(sector_id)
	_info_name.text = String(sector[StationMapModel.KEY_NAME])
	_info_here.text = _text(&"here") if sector_id == _current else ""
	_info_state.text = _text(StringName(STATE_TEXT.get(state, &"state_unknown")))
	_info_state.add_theme_color_override("font_color", _style(state)["text"])
	_info_detail.text = _detail_for(sector, state)


func _detail_for(sector: Dictionary, state: StringName) -> String:
	if StationMapModel.shows_counts(state):
		var counts: Dictionary = StationMapModel.counts(sector, _snap, _logs)
		return "%s   %s" % [
			HudModel.format_pair(
				_text(&"logs"), int(counts["logs_found"]), int(counts["logs_total"])
			),
			HudModel.format_pair(
				_text(&"data"), int(counts["data_found"]), int(counts["data_total"])
			),
		]
	if state == StationMapModel.STATE_SEALED and StationMapModel.sealed_by_ability_only(
		sector, _snap
	):
		return _text(&"sealed_root_hint")
	if state == StationMapModel.STATE_SEALED:
		var requirement: Dictionary = StationMapModel.find(
			_sectors, sector[StationMapModel.KEY_REQUIRES]
		)
		var named: String = String(requirement.get(StationMapModel.KEY_NAME, ""))
		return _text(&"sealed_hint") % named
	return _text(&"unknown_hint")


func _load_logs() -> Dictionary:
	if DialogueManager.has_method(&"logs"):
		var loaded: Dictionary = DialogueManager.logs()
		if not loaded.is_empty():
			return loaded
	return DialogueData.load_dir(LOGS_DIR)["logs"]


func _sectors_by_rank() -> Array[Dictionary]:
	var ordered: Array[Dictionary] = _sectors.duplicate()
	ordered.sort_custom(_lower_rank_first)
	return ordered


func _lower_rank_first(a: Dictionary, b: Dictionary) -> bool:
	return _rank(a) < _rank(b)


func _rank(sector: Dictionary) -> int:
	return int(_style(state_of(sector[StationMapModel.KEY_ID]))["rank"])


func _style(state: StringName) -> Dictionary:
	return STATE_STYLE.get(state, STATE_STYLE[StationMapModel.STATE_UNKNOWN])


func _draw_grid() -> void:
	var left: int = int(FRAME_RECT.position.x)
	var top: int = int(FRAME_RECT.position.y)
	var right: int = int(FRAME_RECT.end.x)
	var bottom: int = int(FRAME_RECT.end.y)
	for x: int in range(left + GRID_STEP, right, GRID_STEP):
		draw_rect(Rect2(x, top, 1, bottom - top), COLOR_GRID)
	for y: int in range(top + GRID_STEP, bottom, GRID_STEP):
		draw_rect(Rect2(left, y, right - left, 1), COLOR_GRID)


func _draw_outline(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), color)
	draw_rect(Rect2(rect.position.x, rect.end.y - 1.0, rect.size.x, 1.0), color)
	draw_rect(Rect2(rect.position, Vector2(1.0, rect.size.y)), color)
	draw_rect(Rect2(rect.end.x - 1.0, rect.position.y, 1.0, rect.size.y), color)


func _draw_dashed_outline(rect: Rect2, color: Color) -> void:
	var step: int = DASH_LENGTH * 2
	for x: int in range(int(rect.position.x), int(rect.end.x), step):
		draw_rect(Rect2(x, rect.position.y, DASH_LENGTH, 1), color)
		draw_rect(Rect2(x, rect.end.y - 1.0, DASH_LENGTH, 1), color)
	for y: int in range(int(rect.position.y), int(rect.end.y), step):
		draw_rect(Rect2(rect.position.x, y, 1, DASH_LENGTH), color)
		draw_rect(Rect2(rect.end.x - 1.0, y, 1, DASH_LENGTH), color)


func _draw_box(sector: Dictionary) -> void:
	var rect: Rect2 = box_rect(sector)
	var state: StringName = state_of(sector[StationMapModel.KEY_ID])
	var style: Dictionary = _style(state)
	draw_rect(rect, style["fill"])
	if state == StationMapModel.STATE_UNKNOWN:
		_draw_dashed_outline(rect, style["wall"])
		return
	_draw_outline(rect, style["wall"])


func _draw_corridor(hub: Dictionary, sector: Dictionary) -> void:
	var points: PackedVector2Array = corridor_points(hub, sector)
	var state: StringName = state_of(sector[StationMapModel.KEY_ID])
	var style: Dictionary = _style(state)
	if state == StationMapModel.STATE_UNKNOWN:
		for index: int in range(points.size() - 1):
			_draw_dashed_segment(points[index], points[index + 1], style["wall"])
		return
	var inner: Color = COLOR_PAPER
	if state == StationMapModel.STATE_RESTORED:
		inner = Color(COLOR_LIT, LIT_CORRIDOR_ALPHA)
	for index: int in range(points.size() - 1):
		draw_rect(_band(points[index], points[index + 1], CORRIDOR_WALL), style["wall"])
	for index: int in range(points.size() - 1):
		draw_rect(_band(points[index], points[index + 1], CORRIDOR_INNER), COLOR_PAPER)
		draw_rect(_band(points[index], points[index + 1], CORRIDOR_INNER), inner)


func _band(from: Vector2, to: Vector2, width: float) -> Rect2:
	var half: float = width * 0.5
	var left: float = minf(from.x, to.x) - half
	var top: float = minf(from.y, to.y) - half
	var right: float = maxf(from.x, to.x) + half
	var bottom: float = maxf(from.y, to.y) + half
	return Rect2(roundf(left), roundf(top), roundf(right - left), roundf(bottom - top))


func _draw_dashed_segment(from: Vector2, to: Vector2, color: Color) -> void:
	var step: int = DASH_LENGTH * 2
	if is_equal_approx(from.y, to.y):
		var y: float = roundf(from.y)
		for x: int in range(int(minf(from.x, to.x)), int(maxf(from.x, to.x)), step):
			draw_rect(Rect2(x, y, DASH_LENGTH, 1), color)
		return
	var x_line: float = roundf(from.x)
	for y: int in range(int(minf(from.y, to.y)), int(maxf(from.y, to.y)), step):
		draw_rect(Rect2(x_line, y, 1, DASH_LENGTH), color)


func _door_point(hub: Dictionary, sector: Dictionary) -> Vector2:
	var points: PackedVector2Array = corridor_points(hub, sector)
	if points.size() < 2:
		return _center(box_rect(sector))
	var last: int = points.size() - 1
	return ((points[last - 1] + points[last]) * 0.5).round()


func _draw_padlock(at: Vector2) -> void:
	var x: float = at.x
	var y: float = at.y
	draw_rect(Rect2(x - 5.0, y - 7.0, 11.0, 12.0), COLOR_PAPER)
	draw_rect(Rect2(x - 2.0, y - 6.0, 5.0, 1.0), PADLOCK_COLOR)
	draw_rect(Rect2(x - 3.0, y - 5.0, 1.0, 3.0), PADLOCK_COLOR)
	draw_rect(Rect2(x + 3.0, y - 5.0, 1.0, 3.0), PADLOCK_COLOR)
	draw_rect(Rect2(x - 4.0, y - 2.0, 9.0, 6.0), PADLOCK_COLOR)
	draw_rect(Rect2(x, y, 1.0, 2.0), PADLOCK_HOLE)


func _draw_marker(rect: Rect2) -> void:
	var x: float = rect.position.x + 5.0
	var y: float = roundf(rect.position.y + rect.size.y * 0.5)
	draw_rect(Rect2(x, y - 2.0, 1.0, 5.0), COLOR_HERE)
	draw_rect(Rect2(x + 1.0, y - 1.0, 1.0, 3.0), COLOR_HERE)
	draw_rect(Rect2(x + 2.0, y, 1.0, 1.0), COLOR_HERE)
	draw_rect(Rect2(x - 1.0, y - 1.0, 1.0, 3.0), COLOR_HERE)
	draw_rect(Rect2(x - 2.0, y, 1.0, 1.0), COLOR_HERE)


func _center(rect: Rect2) -> Vector2:
	return (rect.position + rect.size * 0.5).round()


func _text(id: StringName) -> String:
	return HudModel.text_for(id, _texts)
