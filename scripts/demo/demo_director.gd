class_name DemoDirector
extends Node

enum Phase { IDLE, PLAYING, ENDING, DONE }

const FLAG_PLAYLIST: String = "--qa-playlist="
const FLAG_CHAPTER: String = "--qa-chapter="
const FLAG_FINAL: String = "--qa-final="
const FLAG_VERIFY: String = "--qa-demo-verify"
const FLAG_NO_PACE: String = "--qa-demo-sem-ritmo"
const FLAG_NO_BADGE: String = "--qa-demo-sem-selo"
const FLAG_WINDOW: String = "--qa-demo-janela"
const FLAG_PAUSES: String = "--qa-demo-pausas="
const DEMO_DEVICE: int = 7707
const GATE_PRIORITY: int = 1000000
const FRAME_MIN_USEC: int = 16000
const FRAME_LATE_USEC: int = 100000
const QUIT_HOLD_TIME: float = 1.0
const CURTAIN_IN_FRAMES: int = 15
const CURTAIN_OUT_FRAMES: int = 24
const CUT_LEAD_FRAMES: int = 6
const CUT_TAIL_FRAMES: int = 16
const TRANSITION_TIMEOUT: float = 25.0
const BLACK_ALPHA: float = 0.99
const THEME_PATH: String = "res://assets/ui/theme.tres"
const WARM_SCENES: Array[String] = [
	ScenePaths.MAIN_MENU, ScenePaths.ENDING_CUTSCENE, ScenePaths.ENDING_EPILOGUE,
	ScenePaths.CREDITS, "res://scenes/boot/briefing.tscn",
]
const BADGE_TITLE: String = "PAUSADO"
const BADGE_HINT: String = "P continua   N próximo   R reinicia"
const BADGE_MARGIN: float = 4.0
const BADGE_COLOR: Color = Color(0.372549, 0.831373, 0.784314)
const BADGE_BACK: Color = Color(0.0, 0.0, 0.0, 0.7)

var _qa: Node = null
var _chapters: Array = []
var _playlist_name: String = ""
var _index: int = -1
var _phase: Phase = Phase.IDLE
var _start_wanted: String = ""
var _final_id: String = DemoPlaylist.DEFAULT_FINAL
var _verify: bool = false
var _pace: bool = true
var _badge_on: bool = true
var _windowed: bool = false
var _pauses: Array[Dictionary] = []
var _pending_switch: int = -1
var _pending_target: int = -1
var _user_paused: bool = false
var _toggle_requested: bool = false
var _hold_left: float = 0.0
var _hold_keys: Dictionary = {}
var _frozen: bool = false
var _pause_pending: bool = false
var _saved_paused: bool = false
var _saved_time_scale: float = 1.0
var _test_resume_at: int = -1
var _ending_wait: float = 0.0
var _ending_time: float = 0.0
var _saw_transition: bool = false
var _curtain: float = 0.0
var _curtain_out_left: int = 0
var _teleports: Array[int] = []
var _escape_down_at: int = -1
var _last_tick: int = 0
var _next_frame_at: int = 0
var _demo_started_at: int = 0
var _chapter_checks: Vector2i = Vector2i.ZERO
var _summary: PackedStringArray = []
var _saved_devices: Array = []
var _filtering: bool = false
var _warm: Array[Resource] = []
var _layer: CanvasLayer = null
var _curtain_rect: ColorRect = null
var _badge: PanelContainer = null
var _badge_chapter: Label = null


func setup(qa: Node, arguments: PackedStringArray) -> void:
	_qa = qa
	var playlist_path: String = ""
	var pauses_spec: String = ""
	for argument: String in arguments:
		if argument.begins_with(FLAG_PLAYLIST):
			playlist_path = argument.substr(FLAG_PLAYLIST.length())
		elif argument.begins_with(FLAG_CHAPTER):
			_start_wanted = argument.substr(FLAG_CHAPTER.length())
		elif argument.begins_with(FLAG_FINAL):
			_final_id = DemoPlaylist.valid_final(argument.substr(FLAG_FINAL.length()))
		elif argument.begins_with(FLAG_PAUSES):
			pauses_spec = argument.substr(FLAG_PAUSES.length())
		elif argument == FLAG_VERIFY:
			_verify = true
		elif argument == FLAG_NO_PACE:
			_pace = false
		elif argument == FLAG_NO_BADGE:
			_badge_on = false
		elif argument == FLAG_WINDOW:
			_windowed = true
	_pauses = DemoPlaylist.parse_pauses(pauses_spec)
	_load_playlist(playlist_path)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = GATE_PRIORITY
	get_tree().physics_frame.connect(_on_frame_started)
	get_tree().process_frame.connect(_on_frame_started)
	_build_overlay()
	_isolate_input()
	if not _verify:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	_last_tick = Time.get_ticks_usec()
	_demo_started_at = Time.get_ticks_msec()
	_announce("teclas: P pausa/retoma · N próximo capítulo · R reinicia · Esc segurado sai")
	call_deferred(&"_present_window")


func demo_device() -> int:
	return DEMO_DEVICE


func wants_focus() -> bool:
	return not _verify


func captures() -> bool:
	return _verify


func holds_timeline() -> bool:
	return _frozen or _phase != Phase.PLAYING


func script_finished() -> void:
	if _phase != Phase.PLAYING:
		return
	_close_chapter()
	_begin_ending(DemoPlaylist.next_index(_index, _chapters.size()), true)


func _process(_delta: float) -> void:
	_limit_frame_rate()
	var now: int = Time.get_ticks_usec()
	var real_delta: float = float(now - _last_tick) / 1000000.0
	_last_tick = now
	_check_quit_hold()
	if _phase == Phase.DONE:
		return
	if _phase == Phase.IDLE:
		_warm_scenes()
		_start_first()
		return
	_run_test_pauses()
	_apply_toggle()
	if _hold_left > 0.0 and not _user_paused:
		_hold_left = maxf(0.0, _hold_left - real_delta)
	if _phase == Phase.PLAYING and not _frozen and _pending_switch < 0:
		_maybe_hold()
		_reassert_held()
	_settle_freeze()
	if _pending_switch >= 0 and not _frozen:
		var target: int = _pending_switch
		_pending_switch = -1
		_close_chapter()
		_begin_ending(target, false)
	if _phase == Phase.ENDING and not _frozen:
		_tick_ending(real_delta)
	_update_curtain()


func _limit_frame_rate() -> void:
	var now: int = Time.get_ticks_usec()
	if _next_frame_at > now:
		OS.delay_usec(_next_frame_at - now)
		now = Time.get_ticks_usec()
	if now - _next_frame_at > FRAME_LATE_USEC:
		_next_frame_at = now
	_next_frame_at += FRAME_MIN_USEC


func _input(event: InputEvent) -> void:
	if not _is_real(event):
		return
	if event is InputEventKey:
		_on_key(event as InputEventKey)
	if _filtering:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_reassert_held(true)
	elif what == NOTIFICATION_WM_WINDOW_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_reassert_held(true)


func _load_playlist(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		_log("ERRO playlist inexistente %s" % path)
		return
	var parsed: Dictionary = DemoPlaylist.parse(JSON.parse_string(FileAccess.get_file_as_string(path)))
	for message: String in parsed["errors"] as PackedStringArray:
		_log("ERRO playlist: %s" % message)
	_chapters = parsed["chapters"]
	_playlist_name = String(parsed["name"])


func _start_first() -> void:
	var first: int = DemoPlaylist.chapter_index(_chapters, _start_wanted)
	if first < 0:
		_log("ERRO capítulo desconhecido '%s'" % _start_wanted)
		_finish_demo()
		return
	_log("playlist %s: %d capítulo(s), final %s, ritmo %s" % [
		_playlist_name, _chapters.size(), _final_id, "ligado" if _pace else "desligado"
	])
	_curtain = 1.0
	_start_chapter(first)


func _warm_scenes() -> void:
	var paths: Array[String] = WARM_SCENES.duplicate()
	for file_name: String in DirAccess.get_files_at(ScenePaths.LEVELS_DIR):
		var path: String = ScenePaths.LEVELS_DIR + file_name.trim_suffix(".remap")
		if ScenePaths.is_level(path) and not paths.has(path):
			paths.append(path)
	var started: int = Time.get_ticks_msec()
	for path: String in paths:
		if ResourceLoader.exists(path):
			_warm.append(ResourceLoader.load(path))
	_log("cenas pré-carregadas: %d em %d ms" % [_warm.size(), Time.get_ticks_msec() - started])


func _start_chapter(index: int) -> void:
	_reset_world()
	_index = index
	var chapter: Dictionary = _chapters[index]
	var path: String = DemoPlaylist.script_path(chapter, _final_id)
	var events: Array[Dictionary] = _qa.call(&"load_script_file", path)
	_teleports = DemoPlaylist.teleport_frames(events)
	_hold_keys.clear()
	_chapter_checks = _qa.call(&"check_totals")
	_qa.call(&"begin_script", events, path)
	_phase = Phase.PLAYING
	_curtain_out_left = CURTAIN_OUT_FRAMES if _curtain > 0.0 else 0
	_badge_chapter.text = _chapter_caption()
	_announce("%s capítulo %d/%d %s" % [
		DemoPlaylist.clock(_elapsed()), index + 1, _chapters.size(), String(chapter["title"])
	])


func _close_chapter() -> void:
	if _index < 0 or _index >= _chapters.size():
		return
	var totals: Vector2i = _qa.call(&"check_totals")
	var delta: Vector2i = totals - _chapter_checks
	_chapter_checks = totals
	var line: String = "capítulo %d %s: %d marco(s), %d falha(s)" % [
		_index + 1, String((_chapters[_index] as Dictionary)["id"]), delta.x, delta.y
	]
	_summary.append(line)
	_announce(line)


func _begin_ending(target: int, natural: bool) -> void:
	_phase = Phase.ENDING
	_qa.call(&"release_held")
	_pending_switch = -1
	_ending_time = 0.0
	_saw_transition = false
	_ending_wait = 0.0
	if natural and _index >= 0 and _index < _chapters.size():
		_ending_wait = float((_chapters[_index] as Dictionary)["wait_transition"])
	_curtain_out_left = 0
	_pending_target = target


func _tick_ending(real_delta: float) -> void:
	_ending_time += real_delta
	var transitioning: bool = _scene_busy()
	if _manager_black():
		_curtain = 1.0
	if transitioning:
		_saw_transition = true
		if _ending_time < TRANSITION_TIMEOUT:
			return
		_force_scene_manager_idle()
	elif not _saw_transition and _ending_time < _ending_wait:
		return
	if _curtain < 1.0:
		_curtain = minf(1.0, _curtain + 1.0 / float(CURTAIN_IN_FRAMES))
		return
	if DemoPlaylist.is_past_end(_pending_target, _chapters.size()):
		_finish_demo()
		return
	_start_chapter(_pending_target)


func _finish_demo() -> void:
	_phase = Phase.DONE
	_thaw()
	_qa.call(&"release_held")
	_restore_input()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Engine.time_scale = 1.0
	var save: Node = get_tree().root.get_node_or_null("SaveManager")
	if save != null:
		save.set(&"save_path", "user://save.json")
	_curtain = 0.0
	_curtain_out_left = 0
	_update_curtain()
	_badge.visible = false
	for line: String in _summary:
		_log("resumo da demo: %s" % line)
	_announce("%s fim da demonstração" % DemoPlaylist.clock(_elapsed()))
	if _verify:
		_qa.call(&"finish")


func _reset_world() -> void:
	_thaw()
	_user_paused = false
	_hold_left = 0.0
	_toggle_requested = false
	_qa.call(&"release_held")
	DialogueManager.clear()
	var pause_menu: CanvasLayer = SceneManager.pause_menu()
	if pause_menu != null:
		pause_menu.call(&"close")
	SceneManager.call(&"_dismiss_chassis_lost")
	if SceneManager.is_transitioning():
		_force_scene_manager_idle()
	AudioManager.stop_layer(0.0)
	AudioManager.stop_voice()
	if AudioManager.is_one_shot_playing():
		AudioManager.stop_one_shot(0.0)
	get_tree().paused = false
	Engine.time_scale = 1.0


func _force_scene_manager_idle() -> void:
	_log("AVISO transição do SceneManager forçada a terminar")
	SceneManager.set(&"_transitioning", false)
	SceneManager.pending_path = ""
	var overlay: Variant = SceneManager.get(&"_overlay")
	if overlay is ColorRect:
		(overlay as ColorRect).modulate.a = 0.0
		(overlay as ColorRect).visible = false


func _scene_busy() -> bool:
	if SceneManager.is_transitioning():
		return true
	var current: Node = get_tree().current_scene
	return current != null and current.scene_file_path == ScenePaths.LOADING


func _manager_black() -> bool:
	var overlay: Variant = SceneManager.get(&"_overlay")
	if not (overlay is ColorRect):
		return false
	var rect: ColorRect = overlay
	return rect.visible and rect.modulate.a >= BLACK_ALPHA


func _maybe_hold() -> void:
	if not _pace:
		return
	var frame: int = int(_qa.call(&"current_frame"))
	if not DemoPlaylist.can_freeze_after(frame, int(_qa.call(&"last_input_frame"))):
		return
	var advancing: bool = false
	for event: Dictionary in _qa.call(&"upcoming", frame + 1) as Array[Dictionary]:
		if DemoPlaylist.is_advance_press(event):
			advancing = true
			break
	if not advancing:
		return
	var reader: Dictionary = _reader()
	if reader.is_empty() or _hold_keys.has(reader["key"]):
		return
	_hold_keys[reader["key"]] = true
	_hold_left = DemoPlaylist.reading_hold(int(reader["chars"]))
	_log("frame %d segura leitura %.1f s" % [frame, _hold_left])


func _reader() -> Dictionary:
	if not DialogueManager.is_active() or not DialogueManager.freezes_timer():
		return {}
	if not DialogueManager.is_box_visible():
		return {}
	var text: String = DialogueManager.current_text()
	if text.is_empty() or float(DialogueManager.get(&"_typed_chars")) < float(text.length()):
		return {}
	var key: String = "%d:%s:%d" % [
		int(DialogueManager.get(&"_started_frame")),
		String(DialogueManager.get(&"_current_id")),
		int(DialogueManager.get(&"_line_index")),
	]
	return {"key": key, "chars": text.length()}


func _settle_freeze() -> void:
	var wanted: bool = _user_paused or _hold_left > 0.0
	if wanted and not _frozen:
		if _phase != Phase.PLAYING or DemoPlaylist.can_freeze_after(
			int(_qa.call(&"current_frame")), int(_qa.call(&"last_input_frame"))
		):
			_freeze()
	elif not wanted and _frozen:
		_thaw()
	_badge.visible = _badge_on and _user_paused


func _freeze() -> void:
	if _frozen:
		return
	_frozen = true
	_saved_paused = get_tree().paused
	_saved_time_scale = Engine.time_scale
	Engine.time_scale = 0.0
	_pause_pending = true


func _thaw() -> void:
	if not _frozen:
		return
	_frozen = false
	_pause_pending = false
	get_tree().paused = _saved_paused
	Engine.time_scale = _saved_time_scale


func _on_frame_started() -> void:
	if not _pause_pending:
		return
	_pause_pending = false
	if _frozen:
		get_tree().paused = true


func _apply_toggle() -> void:
	if not _toggle_requested:
		return
	_toggle_requested = false
	_user_paused = not _user_paused
	_announce("%s %s" % [
		DemoPlaylist.clock(_elapsed()), "pausado" if _user_paused else "retomado"
	])


func _on_key(key: InputEventKey) -> void:
	var code: Key = key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if code == KEY_ESCAPE:
		_escape_down_at = Time.get_ticks_msec() if key.pressed else -1
		return
	if not key.pressed or key.echo or _phase == Phase.DONE:
		return
	match code:
		KEY_P:
			_toggle_requested = true
		KEY_N:
			_request_switch(DemoPlaylist.next_index(_index, _chapters.size()))
		KEY_R:
			_request_switch(_index)


func _request_switch(target: int) -> void:
	if _phase != Phase.PLAYING or _index < 0:
		if _phase == Phase.ENDING and target != _index:
			_pending_target = target
		return
	_user_paused = false
	_hold_left = 0.0
	_pending_switch = target
	var verb: String = "reiniciando" if target == _index else "pulando para"
	_announce("%s %s o capítulo %d" % [DemoPlaylist.clock(_elapsed()), verb, target + 1])


func _check_quit_hold() -> void:
	if _escape_down_at < 0:
		return
	if float(Time.get_ticks_msec() - _escape_down_at) / 1000.0 < QUIT_HOLD_TIME:
		return
	_escape_down_at = -1
	_announce("saindo (Esc segurado)")
	get_tree().quit(0)


func _run_test_pauses() -> void:
	var now: int = Time.get_ticks_msec()
	if _test_resume_at >= 0 and now >= _test_resume_at and _user_paused:
		_test_resume_at = -1
		_send_fake_key(KEY_P)
		return
	if _phase != Phase.PLAYING or _index < 0 or _user_paused:
		return
	var chapter_id: String = String((_chapters[_index] as Dictionary)["id"])
	var frame: int = int(_qa.call(&"current_frame"))
	for pause: Dictionary in _pauses:
		if bool(pause["done"]) or String(pause["chapter"]) != chapter_id:
			continue
		if frame < int(pause["frame"]):
			continue
		pause["done"] = true
		var key_name: String = String(pause["key"])
		if key_name != "P":
			_log("tecla de teste %s no capítulo %s, frame %d" % [key_name, chapter_id, frame])
			_send_fake_key(KEY_N if key_name == "N" else KEY_R)
			return
		_test_resume_at = now + int(float(pause["seconds"]) * 1000.0)
		_log("pausa de teste no capítulo %s, frame %d, %.1f s" % [
			chapter_id, frame, float(pause["seconds"])
		])
		_send_fake_key(KEY_P)
		return


func _send_fake_key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)


func _reassert_held(immediate: bool = false) -> void:
	if _phase != Phase.PLAYING:
		return
	var frame: int = int(_qa.call(&"current_frame"))
	if not immediate and not DemoPlaylist.can_freeze_after(
		frame, int(_qa.call(&"last_input_frame"))
	):
		return
	var held: Dictionary = _qa.call(&"held_actions")
	for action: Variant in held.keys():
		var action_name: StringName = StringName(action)
		if bool(held[action]) and not Input.is_action_pressed(action_name):
			Input.action_press(action_name)
			_log("frame %d reaplica %s" % [frame, action_name])


func _is_real(event: InputEvent) -> bool:
	if event is InputEventAction:
		return false
	return event.device != DEMO_DEVICE


func _isolate_input() -> void:
	_saved_devices.clear()
	for action: StringName in InputMap.get_actions():
		for event: InputEvent in InputMap.action_get_events(action):
			_saved_devices.append([event, event.device])
			event.device = DEMO_DEVICE
	_filtering = true


func _restore_input() -> void:
	for pair: Array in _saved_devices:
		(pair[0] as InputEvent).device = int(pair[1])
	_saved_devices.clear()
	_filtering = false


func _present_window() -> void:
	if DisplayServer.get_name() == "headless" or _verify:
		return
	if not _windowed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_move_to_foreground()


func _build_overlay() -> void:
	_layer = CanvasLayer.new()
	_layer.name = "DemoOverlay"
	_layer.layer = UiLayers.DEMO_OVERLAY
	add_child(_layer)
	_curtain_rect = ColorRect.new()
	_curtain_rect.name = "Curtain"
	_curtain_rect.color = Color.BLACK
	_curtain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_curtain_rect)
	_curtain_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_curtain_rect.modulate.a = 0.0
	_curtain_rect.visible = false
	_badge = PanelContainer.new()
	_badge.name = "Badge"
	_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(THEME_PATH):
		_badge.theme = load(THEME_PATH) as Theme
	var style := StyleBoxFlat.new()
	style.bg_color = BADGE_BACK
	style.content_margin_left = BADGE_MARGIN
	style.content_margin_right = BADGE_MARGIN
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	_badge.add_theme_stylebox_override(&"panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_badge.add_child(column)
	column.add_child(_badge_label(BADGE_TITLE, BADGE_COLOR))
	_badge_chapter = _badge_label("", Color.WHITE)
	column.add_child(_badge_chapter)
	column.add_child(_badge_label(BADGE_HINT, Color(0.75, 0.8, 0.82)))
	_layer.add_child(_badge)
	_badge.position = Vector2(BADGE_MARGIN, BADGE_MARGIN)
	_badge.visible = false


func _badge_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override(&"font_color", color)
	return label


func _chapter_caption() -> String:
	if _index < 0 or _index >= _chapters.size():
		return ""
	return "%d/%d %s" % [
		_index + 1, _chapters.size(), String((_chapters[_index] as Dictionary)["title"])
	]


func _update_curtain() -> void:
	var alpha: float = _curtain
	if _phase == Phase.PLAYING:
		if _curtain_out_left > 0:
			if not _frozen:
				_curtain_out_left -= 1
			_curtain = float(_curtain_out_left) / float(CURTAIN_OUT_FRAMES)
			alpha = _curtain
		else:
			_curtain = 0.0
			alpha = 0.0
		var frame: int = int(_qa.call(&"current_frame"))
		alpha = maxf(alpha, DemoPlaylist.cut_alpha(
			frame, _teleports, CUT_LEAD_FRAMES, CUT_TAIL_FRAMES
		))
	_curtain_rect.modulate.a = alpha
	_curtain_rect.visible = alpha > 0.0


func _elapsed() -> float:
	return float(Time.get_ticks_msec() - _demo_started_at) / 1000.0


func _announce(line: String) -> void:
	print("[DEMO] %s" % line)
	if _qa != null:
		_qa.call(&"log_line", "demo %s" % line)


func _log(line: String) -> void:
	if _qa != null:
		_qa.call(&"log_line", line)
	else:
		print("[QA] %s" % line)
