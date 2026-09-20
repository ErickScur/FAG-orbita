extends CanvasLayer

const HUD_SHEET: String = "res://assets/ui/hud_sheet.png"
const ATLAS_FRAME: Vector2i = Vector2i(16, 16)
const ATLAS_COLUMNS: int = 8
const MAX_TOASTS: int = 3
const FLASH_TIME: float = 0.1
const CRITICAL_COLOR: Color = Color(1.0, 0.36, 0.36)
const CRITICAL_DIM_COLOR: Color = Color(0.72, 0.16, 0.16)
const NORMAL_COLOR: Color = Color(1.0, 1.0, 1.0)
const FLASH_COLOR: Color = Color(1.0, 0.45, 0.45)
const PARTIAL_DIM: Color = Color(0.55, 0.62, 0.66)
const BLINK_MIN_ALPHA: float = 0.25
const TOAST_COLOR: Color = Color(0.498039, 0.839216, 0.784314)
const TOAST_FONT_SIZE: int = 16
const CHARGE_TOASTS: Dictionary = {
	&"energy_cell": &"toast_charge",
	&"repair_kit": &"toast_integrity",
	&"capacitor": &"toast_capacity",
}

var _texts: Dictionary = {}
var _cells: Array[TextureRect] = []
var _statuses: Dictionary = {}
var _prompt_text: String = ""
var _dialogue_active: bool = false
var _critical: bool = false
var _blink_time: float = 0.0
var _flash_left: float = 0.0
var _low_integrity: bool = false
var _cell_states: Array[int] = []

@onready var _cells_box: HBoxContainer = %Cells
@onready var _charge_bar: ProgressBar = %ChargeBar
@onready var _cost_mark: ColorRect = %CostMark
@onready var _charge_label: Label = %ChargeLabel
@onready var _status_box: HBoxContainer = %Statuses
@onready var _reactor: VBoxContainer = %Reactor
@onready var _reactor_label: Label = %ReactorLabel
@onready var _reactor_bar: ProgressBar = %ReactorBar
@onready var _reactor_state: Label = %ReactorState
@onready var _objective: Label = %Objective
@onready var _logs_label: Label = %LogsLabel
@onready var _logs_icon: TextureRect = %LogsIcon
@onready var _data_label: Label = %DataLabel
@onready var _data_icon: TextureRect = %DataIcon
@onready var _prompt_row: HBoxContainer = %PromptRow
@onready var _prompt: Label = %Prompt
@onready var _toasts: VBoxContainer = %Toasts
@onready var _beep_timer: Timer = %BeepTimer


func _ready() -> void:
	_texts = HudModel.load_texts()
	_charge_label.text = HudModel.text_for(&"charge_label", _texts)
	_build_cells()
	_build_counter_icons()
	_beep_timer.wait_time = Balance.LOW_INTEGRITY_BEEP_INTERVAL
	_beep_timer.timeout.connect(_on_beep_timeout)
	_connect_events()
	var frame_width: float = _cost_mark.get_parent().custom_minimum_size.x
	_cost_mark.position.x = roundf(
		frame_width * HudModel.charge_ratio(Balance.DASH_COST, Balance.CHARGE_MAX)
	)
	_sync_with_state()


func _process(delta: float) -> void:
	_blink_time += delta
	_update_blink()
	_update_statuses(delta)
	_update_flash(delta)
	_update_reactor_visibility()
	_update_reactor_state_text()


func _update_reactor_visibility() -> void:
	if _reactor.visible == GameState.is_reactor_online():
		return
	_on_reactor_changed(GameState.reactor_percent)


func _build_cells() -> void:
	for child: Node in _cells_box.get_children():
		child.queue_free()
	_cells.clear()
	for index: int in range(Balance.INTEGRITY_CELLS):
		var cell := TextureRect.new()
		cell.custom_minimum_size = Vector2(ATLAS_FRAME)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		_cells_box.add_child(cell)
		_cells.append(cell)


func _build_counter_icons() -> void:
	_logs_icon.texture = _icon(HudModel.ICON_LOG)
	_data_icon.texture = _icon(HudModel.ICON_RESEARCH)


func _icon(index: int) -> Texture2D:
	var cell: Vector2i = HudModel.atlas_cell(index, ATLAS_COLUMNS)
	return AssetResolver.atlas(HUD_SHEET, ATLAS_FRAME, cell.x, cell.y)


func _connect_events() -> void:
	EventBus.integrity_changed.connect(_on_integrity_changed)
	EventBus.charge_changed.connect(_on_charge_changed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_cleared.connect(_on_status_cleared)
	EventBus.reactor_changed.connect(_on_reactor_changed)
	EventBus.reactor_critical.connect(_on_reactor_critical)
	EventBus.collectible_picked.connect(_on_collectible_picked)
	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.interaction_cleared.connect(_on_interaction_cleared)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.log_opened.connect(_on_log_opened)
	EventBus.log_closed.connect(_on_log_closed)
	EventBus.objective_changed.connect(_on_objective_changed)
	EventBus.ability_unlocked.connect(_on_ability_unlocked)
	EventBus.game_paused.connect(_on_game_paused)


func _sync_with_state() -> void:
	_on_integrity_changed(GameState.integrity, GameState.integrity_max)
	_on_charge_changed(GameState.charge, GameState.charge_max)
	_critical = GameState.is_reactor_critical()
	_on_reactor_changed(GameState.reactor_percent)
	_refresh_counters()
	_objective.text = GameState.current_objective
	_cost_mark.visible = GameState.abilities.has(&"dash")


func _on_integrity_changed(current: int, maximum: int) -> void:
	_cell_states = HudModel.cell_states(current, maximum, Balance.INTEGRITY_CELLS)
	for index: int in range(_cells.size()):
		var state: int = _cell_state(index)
		var cell: TextureRect = _cells[index]
		match state:
			HudModel.STATE_FULL:
				cell.texture = _icon(HudModel.CELL_FULL)
				cell.modulate = NORMAL_COLOR
			HudModel.STATE_PARTIAL:
				cell.texture = _icon(HudModel.CELL_FULL)
				cell.modulate = PARTIAL_DIM
			_:
				cell.texture = _icon(HudModel.CELL_BLINK)
				cell.modulate = NORMAL_COLOR
	_update_low_integrity(_cell_states, current > 0)


func _cell_state(index: int) -> int:
	if index < 0 or index >= _cell_states.size():
		return HudModel.STATE_EMPTY
	return _cell_states[index]


func _update_low_integrity(states: Array[int], alive: bool) -> void:
	var low: bool = alive and HudModel.is_low_integrity(states)
	if low == _low_integrity:
		return
	_low_integrity = low
	if low:
		AudioManager.play_sfx(&"low_integrity")
		_beep_timer.start()
	else:
		_beep_timer.stop()


func _on_beep_timeout() -> void:
	if not _low_integrity:
		return
	AudioManager.play_sfx(&"low_integrity")


func _update_blink() -> void:
	var wave: float = sin(_blink_time * TAU * Balance.HUD_PULSE_HZ) * 0.5 + 0.5
	var alpha: float = lerpf(BLINK_MIN_ALPHA, 1.0, wave)
	for index: int in range(_cells.size()):
		if _cell_state(index) != HudModel.STATE_EMPTY:
			continue
		_cells[index].modulate.a = alpha
	if _critical:
		_reactor.modulate = CRITICAL_DIM_COLOR.lerp(CRITICAL_COLOR, wave)
	else:
		_reactor.modulate = NORMAL_COLOR


func _on_charge_changed(current: float, maximum: float) -> void:
	_charge_bar.max_value = maxf(maximum, 1.0)
	_charge_bar.value = clampf(current, 0.0, _charge_bar.max_value)


func _on_player_damaged(_amount: int) -> void:
	_flash_left = FLASH_TIME


func _update_flash(delta: float) -> void:
	if _flash_left <= 0.0:
		_cells_box.modulate = NORMAL_COLOR
		return
	_flash_left = maxf(0.0, _flash_left - delta)
	_cells_box.modulate = FLASH_COLOR if _flash_left > 0.0 else NORMAL_COLOR


func _on_player_died() -> void:
	_beep_timer.stop()
	_low_integrity = false
	_prompt_text = ""
	_refresh_prompt()


func _on_player_respawned() -> void:
	_sync_with_state()


func _on_status_applied(status_id: StringName, duration: float) -> void:
	if _statuses.has(status_id):
		_statuses[status_id]["remaining"] = duration
		return
	if _statuses.size() >= HudModel.MAX_STATUS_ICONS:
		return
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 1)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(ATLAS_FRAME)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = _icon(HudModel.status_icon_index(status_id))
	row.add_child(icon)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", TOAST_FONT_SIZE)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text = str(HudModel.status_seconds(duration))
	row.add_child(label)
	_status_box.add_child(row)
	_statuses[status_id] = {"row": row, "label": label, "remaining": duration}


func _update_statuses(delta: float) -> void:
	var expired: Array[StringName] = []
	for status_id: Variant in _statuses:
		var entry: Dictionary = _statuses[status_id]
		var remaining: float = float(entry.get("remaining", 0.0)) - delta
		entry["remaining"] = remaining
		var label: Label = entry.get("label")
		if is_instance_valid(label):
			label.text = str(HudModel.status_seconds(remaining))
		if remaining <= 0.0:
			expired.append(StringName(status_id))
	for status_id: StringName in expired:
		_remove_status(status_id)


func _on_status_cleared(status_id: StringName) -> void:
	_remove_status(status_id)


func _remove_status(status_id: StringName) -> void:
	if not _statuses.has(status_id):
		return
	var entry: Dictionary = _statuses[status_id]
	var row: HBoxContainer = entry.get("row")
	if is_instance_valid(row):
		row.queue_free()
	_statuses.erase(status_id)


func _on_reactor_changed(percent: float) -> void:
	_reactor.visible = GameState.is_reactor_online()
	_reactor_bar.max_value = Balance.REACTOR_START
	_reactor_bar.value = clampf(percent, 0.0, Balance.REACTOR_START)
	_reactor_label.text = HudModel.format_single(
		HudModel.text_for(&"reactor_title", _texts), ReactorClock.display_percent(percent)
	)
	_update_reactor_state_text()


func _update_reactor_state_text() -> void:
	if not _reactor.visible:
		return
	var id: StringName = &"reactor_falling"
	if Settings.no_timer:
		id = &"reactor_no_timer"
	elif GameState.is_timer_frozen():
		id = &"reactor_frozen"
	var text: String = HudModel.text_for(id, _texts)
	if _reactor_state.text != text:
		_reactor_state.text = text


func _on_reactor_critical(active: bool) -> void:
	_critical = active and not Settings.no_timer
	if not _critical:
		_reactor.modulate = NORMAL_COLOR


func _on_collectible_picked(kind: StringName, _item_id: StringName) -> void:
	_refresh_counters()
	if kind == &"log":
		_toast(
			HudModel.format_pair(
				HudModel.text_for(&"toast_log", _texts),
				GameState.logs_collected.size(),
				Balance.LOGS_TOTAL
			)
		)
		return
	if kind == &"research":
		_toast(
			HudModel.format_pair(
				HudModel.text_for(&"toast_research", _texts),
				GameState.research_collected.size(),
				Balance.RESEARCH_TOTAL
			)
		)
		return
	if not CHARGE_TOASTS.has(kind):
		return
	_toast(
		HudModel.format_single(
			HudModel.text_for(StringName(CHARGE_TOASTS[kind]), _texts), _pickup_amount(kind)
		)
	)


func _pickup_amount(kind: StringName) -> int:
	match kind:
		&"energy_cell":
			return int(Balance.ENERGY_CELL_CHARGE)
		&"repair_kit":
			return Balance.REPAIR_KIT_INTEGRITY
		&"capacitor":
			return int(Balance.CAPACITOR_BONUS)
	return 0


func _refresh_counters() -> void:
	_logs_label.text = HudModel.format_pair(
		HudModel.text_for(&"counter_logs", _texts),
		GameState.logs_collected.size(),
		Balance.LOGS_TOTAL
	)
	_data_label.text = HudModel.format_pair(
		HudModel.text_for(&"counter_research", _texts),
		GameState.research_collected.size(),
		Balance.RESEARCH_TOTAL
	)


func _on_interaction_available(prompt: String) -> void:
	_prompt_text = prompt
	_refresh_prompt()


func _on_interaction_cleared() -> void:
	_prompt_text = ""
	_refresh_prompt()


func _refresh_prompt() -> void:
	_prompt.text = _prompt_text
	_prompt_row.visible = not _prompt_text.is_empty() and not _dialogue_active


func _on_dialogue_started() -> void:
	_dialogue_active = true
	_refresh_prompt()


func _on_dialogue_finished() -> void:
	_dialogue_active = false
	_refresh_prompt()


func _on_log_opened(_log_id: StringName) -> void:
	_dialogue_active = true
	_refresh_prompt()


func _on_log_closed(_log_id: StringName) -> void:
	_dialogue_active = false
	_refresh_prompt()


func _on_objective_changed(text: String) -> void:
	_objective.text = text
	if text.is_empty():
		return
	_toast(HudModel.text_for(&"toast_objective", _texts))


func _on_ability_unlocked(ability_id: StringName) -> void:
	if ability_id != &"dash":
		return
	_cost_mark.visible = true


func _on_game_paused(_paused: bool) -> void:
	_update_reactor_state_text()


func _toast(text: String) -> void:
	if text.is_empty():
		return
	while _toasts.get_child_count() >= MAX_TOASTS:
		var oldest: Node = _toasts.get_child(0)
		_toasts.remove_child(oldest)
		oldest.queue_free()
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", TOAST_FONT_SIZE)
	label.add_theme_color_override("font_color", TOAST_COLOR)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.text = text
	_toasts.add_child(label)
	var tween: Tween = label.create_tween()
	tween.tween_interval(Balance.HUD_TOAST_TIME * 0.6)
	tween.tween_property(label, "modulate:a", 0.0, Balance.HUD_TOAST_TIME * 0.4)
	tween.tween_callback(label.queue_free)
