extends Node

const FLAG_ENABLE: String = "--qa"
const FLAG_SCENE: String = "--qa-scene="
const FLAG_SCRIPT: String = "--qa-script="
const FLAG_OUT: String = "--qa-out="
const FLAG_SCALE: String = "--qa-scale="
const FLAG_NEW_GAME: String = "--qa-new-game"
const FLAG_SCREEN: String = "--qa-screen="
const ENV_SCREEN: String = "ORBITA_QA_SCREEN"
const DEFAULT_OUT: String = "user://qa/"
const LOG_FILE: String = "qa_log.txt"
const TAIL_FRAMES: int = 30
const SAFETY_FRAMES: int = 10800

var is_active: bool = false
var _events: Array[Dictionary] = []
var _next_event: int = 0
var _frame: int = 0
var _end_frame: int = 0
var _scale: int = 1
var _out_dir: String = DEFAULT_OUT
var _log_lines: PackedStringArray = []
var _finishing: bool = false
var _pending_scene: String = ""
var _scene_opened: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if not arguments.has(FLAG_ENABLE):
		return
	is_active = true
	var scene_path: String = ""
	var script_path: String = ""
	var new_game: bool = false
	var screen_index: int = -1
	if OS.has_environment(ENV_SCREEN):
		screen_index = int(OS.get_environment(ENV_SCREEN))
	for argument: String in arguments:
		if argument.begins_with(FLAG_SCENE):
			scene_path = argument.substr(FLAG_SCENE.length())
		elif argument.begins_with(FLAG_SCRIPT):
			script_path = argument.substr(FLAG_SCRIPT.length())
		elif argument.begins_with(FLAG_OUT):
			_out_dir = argument.substr(FLAG_OUT.length())
		elif argument.begins_with(FLAG_SCALE):
			_scale = maxi(1, int(argument.substr(FLAG_SCALE.length())))
		elif argument.begins_with(FLAG_SCREEN):
			screen_index = int(argument.substr(FLAG_SCREEN.length()))
		elif argument == FLAG_NEW_GAME:
			new_game = true
	_place_window(screen_index)
	_prepare_out_dir()
	_events = _load_script(script_path)
	_end_frame = _last_frame() + TAIL_FRAMES
	_log("qa iniciado (roteiro %s, %d eventos)" % [script_path, _events.size()])
	if new_game:
		var state: Node = get_tree().root.get_node_or_null("GameState")
		if state != null and state.has_method("new_game"):
			state.call("new_game")
			_log("game_state new_game")
	_pending_scene = scene_path
	set_process(true)


func _process(_delta: float) -> void:
	if not is_active or _finishing:
		return
	if not _scene_opened:
		_scene_opened = true
		if not _pending_scene.is_empty():
			if ResourceLoader.exists(_pending_scene):
				get_tree().change_scene_to_file(_pending_scene)
				_log("cena %s" % _pending_scene)
			else:
				_log("ERRO cena inexistente %s" % _pending_scene)
		return
	_frame += 1
	while _next_event < _events.size():
		var event: Dictionary = _events[_next_event]
		if int(event.get("frame", 0)) > _frame:
			break
		_next_event += 1
		_run_event(event)
	if _finishing:
		return
	if _next_event >= _events.size() and _frame >= _end_frame:
		_finish()
	elif _frame >= SAFETY_FRAMES:
		_log("tempo esgotado em %d frames" % SAFETY_FRAMES)
		_finish()


func _run_event(event: Dictionary) -> void:
	if event.has("action"):
		var action: StringName = StringName(String(event.get("action", "")))
		var pressed: bool = bool(event.get("pressed", true))
		_inject(action, pressed)
	if event.has("scene"):
		var scene_path: String = String(event.get("scene", ""))
		if ResourceLoader.exists(scene_path):
			get_tree().change_scene_to_file(scene_path)
			_log("frame %d cena %s" % [_frame, scene_path])
		else:
			_log("frame %d ERRO cena inexistente %s" % [_frame, scene_path])
	if event.has("screenshot"):
		_capture(String(event.get("screenshot", "")))
	if bool(event.get("quit", false)):
		_log("frame %d quit" % _frame)
		_finish()


func _inject(action: StringName, pressed: bool) -> void:
	if not InputMap.has_action(action):
		_log("frame %d ERRO ação inexistente %s" % [_frame, action])
		return
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	event.strength = 1.0
	Input.parse_input_event(event)
	_log("frame %d action %s %s" % [_frame, action, "pressed" if pressed else "released"])


func _capture(shot_name: String) -> void:
	if shot_name.is_empty():
		return
	var frame_index: int = _frame
	RenderingServer.force_draw(false)
	var viewport := get_viewport()
	if viewport == null:
		return
	var image: Image = viewport.get_texture().get_image()
	if image == null:
		_log("frame %d ERRO captura vazia %s" % [frame_index, shot_name])
		return
	if _scale > 1:
		image.resize(
			image.get_width() * _scale, image.get_height() * _scale, Image.INTERPOLATE_NEAREST
		)
	var file_name: String = "%s.png" % shot_name
	var error: int = image.save_png(_out_dir.path_join(file_name))
	if error != OK:
		_log("frame %d ERRO ao salvar %s (%d)" % [frame_index, file_name, error])
		return
	_log("frame %d screenshot %s (%dx%d)%s" % [
		frame_index, file_name, image.get_width(), image.get_height(), _player_mark()
	])


func _player_mark() -> String:
	var tree: SceneTree = get_tree()
	if tree == null:
		return ""
	var players: Array[Node] = tree.get_nodes_in_group(&"player")
	if players.is_empty():
		return ""
	var body := players[0] as Node2D
	if body == null:
		return ""
	var tile: Vector2i = Vector2i(body.global_position) / Balance.TILE_SIZE
	return " jogador em %d,%d" % [tile.x, tile.y]


func _finish() -> void:
	if _finishing:
		return
	_finishing = true
	set_process(false)
	var audio: Node = get_tree().root.get_node_or_null("AudioManager")
	if audio != null and audio.has_method("stop_all"):
		audio.call("stop_all")
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	_write_log()
	get_tree().quit(0)


func _prepare_out_dir() -> void:
	if _out_dir.is_empty():
		_out_dir = DEFAULT_OUT
	if _out_dir.begins_with("user://") or _out_dir.begins_with("res://"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_out_dir))
	else:
		DirAccess.make_dir_recursive_absolute(_out_dir)


func _load_script(path: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if path.is_empty():
		return result
	if not FileAccess.file_exists(path):
		_log("ERRO roteiro inexistente %s" % path)
		return result
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Array):
		_log("ERRO roteiro inválido %s" % path)
		return result
	var raw: Array = parsed
	for entry: Variant in raw:
		if entry is Dictionary:
			result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("frame", 0)) < int(b.get("frame", 0)))
	return result


func _last_frame() -> int:
	var last: int = 0
	for event: Dictionary in _events:
		last = maxi(last, int(event.get("frame", 0)))
	return last


func _log(line: String) -> void:
	_log_lines.append(line)
	print("[QA] %s" % line)


func _write_log() -> void:
	var path: String = _out_dir.path_join(LOG_FILE)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("QACapture: não foi possível escrever %s" % path)
		return
	for line: String in _log_lines:
		file.store_line(line)
	file.close()


func _place_window(screen_index: int) -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	if screen_index < 0 or screen_index >= DisplayServer.get_screen_count():
		return
	DisplayServer.window_set_current_screen(screen_index)
	var screen_size: Vector2i = DisplayServer.screen_get_size(screen_index)
	var window_size: Vector2i = DisplayServer.window_get_size()
	var offset: Vector2i = (screen_size - window_size) / 2
	DisplayServer.window_set_position(DisplayServer.screen_get_position(screen_index) + offset)
	_log("janela movida para a tela %d" % screen_index)
