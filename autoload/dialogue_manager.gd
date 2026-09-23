extends Node

const DIALOGUE_DIR: String = "res://data/dialogue/"
const LOGS_DIR: String = "res://data/logs/"
const BOX_SCENE: String = "res://scenes/ui/dialogue_box.tscn"
const FLAG_PREFIX: String = "dlg_"
const BLIP_EVERY: int = 3
const KIND_SEQUENCE: StringName = &"sequence"
const KIND_LOG: StringName = &"log"
const ADVANCE_ACTIONS: Array[StringName] = [&"interact", &"jump", &"ui_accept"]

var _sequences: Dictionary = {}
var _logs: Dictionary = {}
var _speakers: Dictionary = {}
var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _current_id: StringName = &""
var _current_kind: StringName = &""
var _lines: Array = []
var _line_index: int = -1
var _typed_chars: float = 0.0
var _blipped_chars: int = 0
var _ambient_timer: float = 0.0
var _started_frame: int = -1
var _blocking_active: bool = false
var _paused_world: bool = false
var _box: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_content()
	_mount_box()
	set_process(true)


func _process(delta: float) -> void:
	if _current.is_empty():
		return
	if _line_index < 0:
		return
	var length: int = _current_text().length()
	if _typed_chars < float(length):
		_typed_chars = minf(float(length), _typed_chars + Balance.DIALOGUE_CPS * delta)
		_update_box_progress()
		if _typed_chars >= float(length) and not _is_blocking():
			_ambient_timer = _ambient_hold(length)
		return
	if _is_blocking():
		return
	_ambient_timer -= delta
	if _ambient_timer <= 0.0:
		advance()


func _unhandled_input(event: InputEvent) -> void:
	if _current.is_empty() or not _is_blocking():
		return
	if Engine.get_process_frames() == _started_frame:
		return
	for action: StringName in ADVANCE_ACTIONS:
		if event.is_action_pressed(action):
			get_viewport().set_input_as_handled()
			advance()
			return
	if event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		skip()


func play(sequence_id: StringName) -> void:
	enqueue(sequence_id)


func enqueue(sequence_id: StringName) -> void:
	if sequence_id == &"":
		return
	if not _sequences.has(sequence_id):
		push_warning("DialogueManager: sequência desconhecida '%s'" % sequence_id)
		return
	if has_played(sequence_id):
		return
	if _is_queued(KIND_SEQUENCE, sequence_id):
		return
	_queue.append({"kind": KIND_SEQUENCE, "id": sequence_id})
	var mode: StringName = DialogueData.sequence_mode(_sequences, sequence_id)
	_start_or_interrupt(mode == DialogueData.MODE_BLOCKING)


func open_log(log_id: StringName) -> void:
	if not _logs.has(log_id):
		push_warning("DialogueManager: log desconhecido '%s'" % log_id)
		return
	GameState.register_pickup(PickupRules.KIND_LOG, log_id)
	if _is_queued(KIND_LOG, log_id):
		return
	_queue.append({"kind": KIND_LOG, "id": log_id})
	_start_or_interrupt(true)


func advance() -> void:
	if _current.is_empty():
		return
	var length: int = _current_text().length()
	if _typed_chars < float(length):
		skip()
		return
	if _line_index + 1 < _lines.size():
		_show_line(_line_index + 1)
		return
	_finish_current()


func skip() -> void:
	if _current.is_empty():
		return
	_typed_chars = float(_current_text().length())
	_update_box_progress()
	if not _is_blocking():
		_ambient_timer = _ambient_hold(int(_typed_chars))


func clear() -> void:
	_queue.clear()
	if not _current.is_empty():
		_finish_current()
	_queue.clear()
	if _blocking_active:
		_blocking_active = false
		_pause_world(false)
		EventBus.dialogue_finished.emit()
	_pause_world(false)


func is_active() -> bool:
	return not _current.is_empty()


func freezes_timer() -> bool:
	if _current.is_empty():
		return false
	return _current_kind == KIND_LOG or _is_blocking()


func has_played(sequence_id: StringName) -> bool:
	var data: Variant = _sequences.get(sequence_id, {})
	if data is Dictionary and not bool((data as Dictionary).get("once", true)):
		return false
	return bool(GameState.flags.get(FLAG_PREFIX + String(sequence_id), false))


func current_speaker() -> StringName:
	if _line_index < 0 or _line_index >= _lines.size():
		return &""
	return StringName(String((_lines[_line_index] as Dictionary).get("speaker", "")))


func current_text() -> String:
	return _current_text()


func current_header() -> String:
	return String(_current.get("header", ""))


func current_mode() -> StringName:
	return StringName(String(_current.get("mode", DialogueData.MODE_BLOCKING)))


func queue_size() -> int:
	return _queue.size()


func sequence_ids() -> Array:
	return _sequences.keys()


func log_ids() -> Array:
	return _logs.keys()


func speakers() -> Dictionary:
	return _speakers


func sequences() -> Dictionary:
	return _sequences


func logs() -> Dictionary:
	return _logs


func _load_content() -> void:
	var dialogue: Dictionary = DialogueData.load_dir(DIALOGUE_DIR)
	var logs: Dictionary = DialogueData.load_dir(LOGS_DIR)
	var merged: Dictionary = DialogueData.merge([dialogue, logs])
	_sequences = merged["sequences"]
	_logs = merged["logs"]
	_speakers = merged["speakers"]
	for message: String in merged["errors"] as PackedStringArray:
		push_warning("DialogueManager: %s" % message)


func _mount_box() -> void:
	if not ResourceLoader.exists(BOX_SCENE):
		push_warning("DialogueManager: caixa de legenda ausente em %s" % BOX_SCENE)
		return
	var instance: Node = load(BOX_SCENE).instantiate()
	if not (instance is CanvasLayer):
		instance.free()
		return
	_box = instance
	add_child(_box)


func _start_or_interrupt(blocking: bool) -> void:
	if blocking:
		_promote_blocking()
	if _current.is_empty():
		_start_next()
		return
	if blocking and not _is_blocking():
		_finish_current()


func _promote_blocking() -> void:
	var blocking_entries: Array[Dictionary] = []
	var ambient_entries: Array[Dictionary] = []
	for entry: Dictionary in _queue:
		if entry["kind"] == KIND_LOG or _entry_is_blocking(entry):
			blocking_entries.append(entry)
		else:
			ambient_entries.append(entry)
	if blocking_entries.is_empty():
		return
	_queue = blocking_entries
	for entry: Dictionary in ambient_entries:
		_queue.append(entry)


func _entry_is_blocking(entry: Dictionary) -> bool:
	var id: StringName = entry["id"]
	if not _sequences.has(id):
		return true
	var data: Dictionary = _sequences[id]
	return String(data.get("mode", "blocking")) != "ambient"


func _is_queued(kind: StringName, id: StringName) -> bool:
	for entry: Dictionary in _queue:
		if entry["kind"] == kind and entry["id"] == id:
			return true
	return _current_kind == kind and _current_id == id and not _current.is_empty()


func _start_next() -> void:
	if _queue.is_empty():
		return
	var entry: Dictionary = _queue.pop_front()
	_current_kind = entry["kind"]
	_current_id = entry["id"]
	if _current_kind == KIND_LOG:
		_current = DialogueData.log_to_sequence(_logs[_current_id])
	else:
		_current = (_sequences[_current_id] as Dictionary).duplicate(true)
		if bool(_current.get("once", true)):
			GameState.flags[FLAG_PREFIX + String(_current_id)] = true
	_lines = _current.get("lines", [])
	_started_frame = Engine.get_process_frames()
	if _is_blocking() and not _blocking_active:
		_blocking_active = true
		_pause_world(true)
		EventBus.dialogue_started.emit()
	if _current_kind == KIND_LOG:
		AudioManager.play_sfx(&"tape_hiss")
		EventBus.log_opened.emit(_current_id)
	if _lines.is_empty():
		_finish_current()
		return
	_show_line(0)


func _show_line(index: int) -> void:
	_line_index = index
	_typed_chars = 0.0
	_blipped_chars = 0
	_ambient_timer = 0.0
	var line: Dictionary = _lines[index]
	var sfx: String = String(line.get("sfx", ""))
	if not sfx.is_empty():
		AudioManager.play_sfx(StringName(sfx))
	if _box == null:
		return
	var speaker_id: StringName = StringName(String(line.get("speaker", "")))
	_box.call(
		"show_line",
		_speaker_data(speaker_id),
		String(line.get("text", "")),
		current_header(),
		_is_blocking(),
		StringName(String(line.get("expr", DialogueData.DEFAULT_EXPRESSION)))
	)
	_update_box_progress()


func _speaker_data(speaker_id: StringName) -> Dictionary:
	var data: Variant = _speakers.get(speaker_id, {})
	if data is Dictionary:
		return data
	return {}


func _current_text() -> String:
	if _line_index < 0 or _line_index >= _lines.size():
		return ""
	return String((_lines[_line_index] as Dictionary).get("text", ""))


func _is_blocking() -> bool:
	return current_mode() == DialogueData.MODE_BLOCKING


func _ambient_hold(length: int) -> float:
	return maxf(Balance.DIALOGUE_AMBIENT_MIN_TIME, float(length) / Balance.DIALOGUE_READ_CPS)


func _update_box_progress() -> void:
	if _box == null:
		return
	var visible_chars: int = int(_typed_chars)
	_box.call("set_progress", visible_chars, _typed_chars >= float(_current_text().length()))
	if visible_chars - _blipped_chars >= BLIP_EVERY:
		_blipped_chars = visible_chars
		AudioManager.play_sfx(&"dialogue_blip")


func _finish_current() -> void:
	var finished_kind: StringName = _current_kind
	var finished_id: StringName = _current_id
	var finished: Dictionary = _current
	_current = {}
	_current_id = &""
	_current_kind = &""
	_lines = []
	_line_index = -1
	_typed_chars = 0.0
	_apply_effects(finished)
	if finished_kind == KIND_LOG:
		EventBus.log_closed.emit(finished_id)
	if not _current.is_empty():
		if _blocking_active and not _is_blocking():
			_blocking_active = false
			_pause_world(false)
			EventBus.dialogue_finished.emit()
		return
	if _queue.is_empty() or not _next_is_blocking():
		if _blocking_active:
			_blocking_active = false
			_pause_world(false)
			EventBus.dialogue_finished.emit()
	if not _queue.is_empty():
		_start_next()
		return
	if _box != null:
		_box.call("hide_box")


func _next_is_blocking() -> bool:
	if _queue.is_empty():
		return false
	var entry: Dictionary = _queue[0]
	if entry["kind"] == KIND_LOG:
		return true
	var data: Variant = _sequences.get(entry["id"], {})
	if not (data is Dictionary):
		return false
	return StringName(String((data as Dictionary).get("mode", ""))) == DialogueData.MODE_BLOCKING


func _apply_effects(data: Dictionary) -> void:
	for value: Variant in data.get("set_flags", []) as Array:
		GameState.flags[String(value)] = true
	var objective: String = String(data.get("objective", ""))
	if not objective.is_empty() and GameState.has_method("set_objective"):
		GameState.call("set_objective", StringName(objective))
	var ability: String = String(data.get("unlock_ability", ""))
	if ability.is_empty():
		return
	GameState.unlock_ability(StringName(ability))


func _pause_world(active: bool) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	if active:
		if tree.paused:
			return
		_paused_world = true
		tree.paused = true
		return
	if not _paused_world:
		return
	_paused_world = false
	tree.paused = false
