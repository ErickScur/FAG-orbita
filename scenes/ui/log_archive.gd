extends Control

signal closed()

const TEXTS_PATH: String = "res://data/ui/log_archive.json"
const LOGS_DIR: String = "res://data/logs/"
const SPEAKERS_DIR: String = "res://data/dialogue/"
const SCREEN_SIZE: Vector2 = Vector2(384.0, 216.0)
const LINE_HEIGHT: float = 16.0
const MARGIN: float = 8.0
const HEADER_Y: float = 1.0
const TABS_Y: float = 17.0
const RULE_Y: float = 34.0
const BODY_Y: float = 36.0
const BODY_HEIGHT: float = 160.0
const LIST_WIDTH: float = 176.0
const PANE_X: float = 190.0
const TAB_WIDTH: float = 72.0
const FOOTER_Y: float = 198.0
const ENTRY_INDENT: float = 8.0
const PREVIEW_LINES: int = 3
const SCROLL_STEP: int = 16
const TEXT_LINE_SPACING: int = 1
const COLOR_BACKGROUND: Color = Color(0.027451, 0.0509804, 0.0666667)
const COLOR_RULE: Color = Color(0.207843, 0.435294, 0.435294)
const COLOR_TITLE: Color = Color(0.372549, 0.831373, 0.784314)
const COLOR_LABEL: Color = Color(0.541176, 0.607843, 0.658824)
const COLOR_VALUE: Color = Color(0.843137, 0.890196, 0.909804)
const COLOR_MISSING: Color = Color(0.360784, 0.415686, 0.470588)
const COLOR_GROUP: Color = Color(0.372549, 0.831373, 0.784314)
const COLOR_AUTHOR_FALLBACK: Color = Color(0.941176, 0.760784, 0.498039)

static var _last_log_id: StringName = &""
static var _last_grouping: StringName = LogCatalog.GROUP_BY_SECTOR

@export var uses_override: bool = false

var collected_override: Array = []

var _texts: Dictionary = {}
var _logs: Dictionary = {}
var _speakers: Dictionary = {}
var _sectors: Array[Dictionary] = []
var _entries: Array[Dictionary] = []
var _ordered: Array[Dictionary] = []
var _buttons: Array[Button] = []
var _grouping: StringName = LogCatalog.GROUP_BY_SECTOR
var _selected: StringName = &""
var _reading: bool = false
var _silent_focus: bool = false
var _header: Label = null
var _counter: Label = null
var _tab_sector: Label = null
var _tab_author: Label = null
var _list_scroll: ScrollContainer = null
var _list: VBoxContainer = null
var _pane: VBoxContainer = null
var _pane_title: Label = null
var _pane_author: Label = null
var _pane_role: Label = null
var _pane_sector: Label = null
var _pane_preview: Label = null
var _pane_hint: Label = null
var _reader_title: Label = null
var _reader_author: Label = null
var _reader_scroll: ScrollContainer = null
var _reader_text: Label = null
var _footer: Label = null
var _empty: Label = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_texts = HudModel.load_texts(TEXTS_PATH)
	_sectors = StationMapModel.load_station()["sectors"]
	_logs = _load_logs()
	_speakers = _load_speakers()
	_build()
	_grouping = _last_grouping
	_selected = _last_log_id
	refresh()
	AudioManager.play_sfx(&"ui_confirm")


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), COLOR_BACKGROUND)
	draw_rect(Rect2(MARGIN, RULE_Y, SCREEN_SIZE.x - MARGIN * 2.0, 1.0), COLOR_RULE)
	if not _reading:
		draw_rect(Rect2(PANE_X - 6.0, BODY_Y, 1.0, BODY_HEIGHT), COLOR_RULE)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed(&"log_archive"):
		_consume()
		close()
		return
	if _reading:
		_reader_input(event)
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		_consume()
		close()
	elif _is_side(event):
		_consume()
		toggle_grouping()
	elif event.is_action_pressed(&"ui_accept"):
		_consume()
		open_selected()


func refresh() -> void:
	_entries = LogCatalog.entries(_logs, _collected())
	var groups: Array[Dictionary] = _groups()
	_ordered = LogCatalog.flatten(groups)
	_rebuild_list(groups)
	_counter.text = HudModel.format_pair(
		_text(&"counter"), LogCatalog.collected_count(_logs, _collected()), Balance.LOGS_TOTAL
	)
	_apply_tabs()
	_empty.visible = _ordered.is_empty()
	if _ordered.is_empty():
		_selected = &""
		_show_pane({})
		return
	if LogCatalog.index_of(_ordered, _selected) < 0:
		_selected = _ordered[0][LogCatalog.KEY_ID]
	_focus_selected()


func toggle_grouping() -> void:
	if _grouping == LogCatalog.GROUP_BY_SECTOR:
		_grouping = LogCatalog.GROUP_BY_AUTHOR
	else:
		_grouping = LogCatalog.GROUP_BY_SECTOR
	_last_grouping = _grouping
	AudioManager.play_sfx(&"ui_move")
	refresh()


func open_selected() -> bool:
	var entry: Dictionary = selected_entry()
	if entry.is_empty() or not bool(entry[LogCatalog.KEY_COLLECTED]):
		AudioManager.play_sfx(&"ui_error")
		return false
	_reading = true
	_reader_title.text = String(entry[LogCatalog.KEY_TITLE])
	var author: StringName = entry[LogCatalog.KEY_AUTHOR]
	_reader_author.text = LogCatalog.author_name(author, _speakers)
	_reader_author.add_theme_color_override(
		"font_color", LogCatalog.author_color(author, _speakers, COLOR_AUTHOR_FALLBACK)
	)
	_reader_text.text = "\n".join(entry[LogCatalog.KEY_LINES] as PackedStringArray)
	_reader_scroll.scroll_vertical = 0
	_release_focus()
	_apply_mode()
	AudioManager.play_sfx(&"tape_hiss")
	_play_voice(String(entry[LogCatalog.KEY_VOICE]))
	return true


func close_reader() -> void:
	if not _reading:
		return
	_reading = false
	AudioManager.stop_voice()
	AudioManager.play_sfx(&"ui_back")
	_apply_mode()
	_focus_selected()


func close() -> void:
	if _reading:
		AudioManager.stop_voice()
	_reading = false
	_release_focus()
	AudioManager.play_sfx(&"ui_back")
	closed.emit()
	queue_free()


func is_reading() -> bool:
	return _reading


func grouping() -> StringName:
	return _grouping


func selected_entry() -> Dictionary:
	var index: int = LogCatalog.index_of(_ordered, _selected)
	if index < 0:
		return {}
	return _ordered[index]


func entry_count() -> int:
	return _ordered.size()


func owns_focus() -> bool:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return false
	var owner_control: Control = viewport.gui_get_focus_owner()
	return owner_control != null and is_ancestor_of(owner_control)


func reader_text() -> String:
	return _reader_text.text if _reading else ""


func _reader_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		_consume()
		close_reader()
	elif event.is_action_pressed(&"ui_down", true) or event.is_action_pressed(&"move_down", true):
		_consume()
		_reader_scroll.scroll_vertical += SCROLL_STEP
	elif event.is_action_pressed(&"ui_up", true) or event.is_action_pressed(&"move_up", true):
		_consume()
		_reader_scroll.scroll_vertical -= SCROLL_STEP
	elif event.is_action_pressed(&"ui_accept") or _is_side(event):
		_consume()


func _is_side(event: InputEvent) -> bool:
	for action: StringName in [&"ui_left", &"ui_right", &"move_left", &"move_right"]:
		if event.is_action_pressed(action):
			return true
	return false


func _consume() -> void:
	var viewport: Viewport = get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()


func _collected() -> Array:
	if uses_override:
		return collected_override
	return GameState.collected_ids


func _groups() -> Array[Dictionary]:
	if _grouping == LogCatalog.GROUP_BY_AUTHOR:
		return LogCatalog.group_by_author(_entries, _speakers, _text(&"unknown_author"))
	return LogCatalog.group_by_sector(_entries, _sectors)


func _build() -> void:
	_header = _label(Rect2(MARGIN, HEADER_Y, 200.0, LINE_HEIGHT), COLOR_TITLE)
	_header.text = _text(&"title")
	_counter = _label(Rect2(176.0, HEADER_Y, 200.0, LINE_HEIGHT), COLOR_VALUE)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_tab_sector = _label(Rect2(MARGIN, TABS_Y, TAB_WIDTH, LINE_HEIGHT), COLOR_LABEL)
	_tab_sector.text = _text(&"by_sector")
	_tab_author = _label(Rect2(MARGIN + TAB_WIDTH, TABS_Y, TAB_WIDTH, LINE_HEIGHT), COLOR_LABEL)
	_tab_author.text = _text(&"by_author")
	_build_list()
	_build_pane()
	_build_reader()
	_footer = _label(Rect2(0.0, FOOTER_Y, SCREEN_SIZE.x, LINE_HEIGHT), COLOR_LABEL)
	_footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty = _label(Rect2(MARGIN, BODY_Y, LIST_WIDTH, LINE_HEIGHT), COLOR_MISSING)
	_empty.text = _text(&"empty")
	_apply_mode()


func _build_list() -> void:
	_list_scroll = ScrollContainer.new()
	_list_scroll.position = Vector2(MARGIN, BODY_Y)
	_list_scroll.size = Vector2(LIST_WIDTH, BODY_HEIGHT)
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_list_scroll.follow_focus = true
	_list_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_list_scroll)
	_list = VBoxContainer.new()
	_list.custom_minimum_size = Vector2(LIST_WIDTH, 0.0)
	_list.add_theme_constant_override("separation", 0)
	_list_scroll.add_child(_list)


func _build_pane() -> void:
	_pane = VBoxContainer.new()
	_pane.position = Vector2(PANE_X, BODY_Y)
	_pane.size = Vector2(SCREEN_SIZE.x - PANE_X - MARGIN, BODY_HEIGHT)
	_pane.add_theme_constant_override("separation", 0)
	_pane.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_pane)
	_pane_title = _pane_label(COLOR_VALUE, true)
	_pane_author = _pane_label(COLOR_AUTHOR_FALLBACK, false)
	_pane_role = _pane_label(COLOR_LABEL, false)
	_pane_sector = _pane_label(COLOR_LABEL, false)
	_pane_preview = _pane_label(COLOR_VALUE, true)
	_pane_preview.max_lines_visible = PREVIEW_LINES
	_pane_preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pane_preview.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_pane_hint = _pane_label(COLOR_TITLE, false)


func _build_reader() -> void:
	_reader_title = _label(Rect2(MARGIN, TABS_Y, 200.0, LINE_HEIGHT), COLOR_VALUE)
	_reader_author = _label(Rect2(176.0, TABS_Y, 200.0, LINE_HEIGHT), COLOR_AUTHOR_FALLBACK)
	_reader_author.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reader_scroll = ScrollContainer.new()
	_reader_scroll.position = Vector2(MARGIN, BODY_Y)
	_reader_scroll.size = Vector2(SCREEN_SIZE.x - MARGIN * 2.0, BODY_HEIGHT)
	_reader_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_reader_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_reader_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_reader_scroll)
	_reader_text = Label.new()
	_reader_text.custom_minimum_size = Vector2(SCREEN_SIZE.x - MARGIN * 2.0, 0.0)
	_reader_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reader_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reader_text.add_theme_color_override("font_color", COLOR_VALUE)
	_reader_text.add_theme_constant_override("line_spacing", TEXT_LINE_SPACING)
	_reader_scroll.add_child(_reader_text)


func _label(rect: Rect2, color: Color) -> Label:
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


func _pane_label(color: Color, wraps: bool) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.focus_mode = Control.FOCUS_NONE
	label.custom_minimum_size = Vector2(0.0, LINE_HEIGHT)
	label.add_theme_color_override("font_color", color)
	if wraps:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label.clip_text = true
	_pane.add_child(label)
	return label


func _rebuild_list(groups: Array[Dictionary]) -> void:
	for child: Node in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for group: Dictionary in groups:
		var header := Label.new()
		header.text = String(group[LogCatalog.KEY_LABEL])
		header.custom_minimum_size = Vector2(0.0, LINE_HEIGHT)
		header.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.focus_mode = Control.FOCUS_NONE
		header.clip_text = true
		header.add_theme_color_override("font_color", COLOR_GROUP)
		_list.add_child(header)
		for value: Variant in group[LogCatalog.KEY_ENTRIES] as Array:
			_list.add_child(_entry_button(value as Dictionary))
	_link_buttons()


func _entry_button(entry: Dictionary) -> Button:
	var collected: bool = bool(entry[LogCatalog.KEY_COLLECTED])
	var button := Button.new()
	button.text = String(entry[LogCatalog.KEY_TITLE]) if collected else _text(&"missing_title")
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.clip_text = true
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(0.0, LINE_HEIGHT)
	var plain := StyleBoxEmpty.new()
	plain.content_margin_left = ENTRY_INDENT
	var focus := StyleBoxFlat.new()
	focus.draw_center = true
	focus.bg_color = Color(COLOR_TITLE, 0.18)
	focus.content_margin_left = ENTRY_INDENT
	focus.border_width_left = 2
	focus.border_color = COLOR_TITLE
	focus.anti_aliasing = false
	for style_name: String in ["normal", "hover", "pressed", "disabled", "hover_pressed"]:
		button.add_theme_stylebox_override(style_name, plain)
	button.add_theme_stylebox_override("focus", focus)
	var color: Color = COLOR_VALUE if collected else COLOR_MISSING
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", color)
	button.add_theme_color_override("font_pressed_color", color)
	var log_id: StringName = entry[LogCatalog.KEY_ID]
	button.set_meta(&"log_id", log_id)
	button.focus_entered.connect(_on_entry_focused.bind(log_id))
	button.pressed.connect(_on_entry_pressed.bind(log_id))
	_buttons.append(button)
	return button


func _link_buttons() -> void:
	var total: int = _buttons.size()
	for index: int in range(total):
		var button: Button = _buttons[index]
		var own: NodePath = button.get_path_to(button)
		var previous: NodePath = button.get_path_to(_buttons[(index - 1 + total) % total])
		var next: NodePath = button.get_path_to(_buttons[(index + 1) % total])
		button.focus_neighbor_top = previous
		button.focus_previous = previous
		button.focus_neighbor_bottom = next
		button.focus_next = next
		button.focus_neighbor_left = own
		button.focus_neighbor_right = own


func _focus_selected() -> void:
	for button: Button in _buttons:
		if StringName(button.get_meta(&"log_id", &"")) == _selected:
			_silent_focus = true
			button.grab_focus()
			_silent_focus = false
			break
	_show_pane(selected_entry())


func _on_entry_focused(log_id: StringName) -> void:
	if not _silent_focus and log_id != _selected:
		AudioManager.play_sfx(&"ui_move")
	_selected = log_id
	_last_log_id = log_id
	_show_pane(selected_entry())


func _on_entry_pressed(log_id: StringName) -> void:
	_selected = log_id
	open_selected()


func _show_pane(entry: Dictionary) -> void:
	if entry.is_empty():
		for label: Label in [_pane_title, _pane_author, _pane_role, _pane_sector, _pane_preview]:
			label.text = ""
		_pane_hint.text = ""
		return
	var collected: bool = bool(entry[LogCatalog.KEY_COLLECTED])
	_pane_sector.text = _sector_name(entry[LogCatalog.KEY_SECTOR])
	if not collected:
		_pane_title.text = _text(&"missing_title")
		_pane_author.text = ""
		_pane_role.text = ""
		_pane_preview.text = _text(&"missing_body")
		_pane_hint.text = ""
		return
	var author: StringName = entry[LogCatalog.KEY_AUTHOR]
	_pane_title.text = String(entry[LogCatalog.KEY_TITLE])
	_pane_author.text = LogCatalog.author_name(author, _speakers)
	_pane_author.add_theme_color_override(
		"font_color", LogCatalog.author_color(author, _speakers, COLOR_AUTHOR_FALLBACK)
	)
	_pane_role.text = String(entry[LogCatalog.KEY_SUBTITLE])
	var lines: PackedStringArray = entry[LogCatalog.KEY_LINES]
	_pane_preview.text = lines[0] if not lines.is_empty() else ""
	_pane_hint.text = _text(&"read_hint")


func _sector_name(sector_key: StringName) -> String:
	for sector: Dictionary in _sectors:
		var keys: Array = [sector[StationMapModel.KEY_ID], sector[StationMapModel.KEY_LEVEL]]
		if keys.has(sector_key):
			return String(sector[StationMapModel.KEY_NAME])
	return String(sector_key).to_upper()


func _apply_tabs() -> void:
	var by_sector: bool = _grouping == LogCatalog.GROUP_BY_SECTOR
	_tab_sector.add_theme_color_override("font_color", COLOR_TITLE if by_sector else COLOR_LABEL)
	_tab_author.add_theme_color_override("font_color", COLOR_LABEL if by_sector else COLOR_TITLE)


func _apply_mode() -> void:
	_list_scroll.visible = not _reading
	_pane.visible = not _reading
	_tab_sector.visible = not _reading
	_tab_author.visible = not _reading
	_reader_scroll.visible = _reading
	_reader_title.visible = _reading
	_reader_author.visible = _reading
	_footer.text = _text(&"footer_reader") if _reading else _text(&"footer_list")
	if _empty != null:
		_empty.visible = not _reading and _ordered.is_empty()
	queue_redraw()


func _release_focus() -> void:
	var viewport: Viewport = get_viewport()
	if viewport == null:
		return
	var owner_control: Control = viewport.gui_get_focus_owner()
	if owner_control != null and is_ancestor_of(owner_control):
		owner_control.release_focus()


func _play_voice(path: String) -> void:
	if path.is_empty():
		return
	var stream: AudioStream = AssetResolver.audio(path)
	if stream != null:
		AudioManager.play_voice(stream)


func _load_logs() -> Dictionary:
	if DialogueManager.has_method(&"logs"):
		var loaded: Dictionary = DialogueManager.logs()
		if not loaded.is_empty():
			return loaded
	return DialogueData.load_dir(LOGS_DIR)["logs"]


func _load_speakers() -> Dictionary:
	if DialogueManager.has_method(&"speakers"):
		var loaded: Dictionary = DialogueManager.speakers()
		if not loaded.is_empty():
			return loaded
	return DialogueData.load_dir(SPEAKERS_DIR)["speakers"]


func _text(id: StringName) -> String:
	return HudModel.text_for(id, _texts)
