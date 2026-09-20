extends SandboxRoom

const ROOM: Rect2i = Rect2i(0, 0, 768, 216)
const SPAWN: Vector2 = Vector2(96, 160)
const TERMINAL_SCENE: String = "res://scenes/world/terminal.tscn"
const LOG_OBJECT_SCENE: String = "res://scenes/world/log_object.tscn"
const FLOOR: Rect2 = Rect2(0, 160, 768, 56)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(768, -64, 16, 280)
const TERMINAL_POSITION: Vector2 = Vector2(208, 160)
const LOG_POSITION: Vector2 = Vector2(288, 160)
const BROKEN_POSITION: Vector2 = Vector2(400, 160)
const BROKEN_PROMPT: String = "TERMINAL SEM ENERGIA"

var _count: int = 0
var _prompt: Label = null
var _status: Label = null


func _ready() -> void:
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	_spawn_terminal(TERMINAL_POSITION, "ACESSAR TERMINAL", true)
	_spawn_log_object(LOG_POSITION, "LER REGISTRO")
	_spawn_terminal(BROKEN_POSITION, BROKEN_PROMPT, false)
	spawn_player(SPAWN)
	_status = add_label(Control.PRESET_TOP_LEFT, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_prompt = add_label(Control.PRESET_CENTER_BOTTOM, "")
	EventBus.interaction_available.connect(_on_interaction_available)
	EventBus.interaction_cleared.connect(_on_interaction_cleared)
	_refresh_status()


func _spawn_terminal(at: Vector2, prompt: String, enabled: bool) -> void:
	if not ResourceLoader.exists(TERMINAL_SCENE):
		push_warning("interaction_sandbox: terminal ausente")
		return
	var scene: PackedScene = load(TERMINAL_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is Terminal):
		instance.free()
		return
	var terminal: Terminal = instance
	terminal.position = at
	terminal.prompt_text = prompt
	terminal.enabled = enabled
	terminal.interacted.connect(_on_interacted)
	add_child(terminal)


func _spawn_log_object(at: Vector2, prompt: String) -> void:
	if not ResourceLoader.exists(LOG_OBJECT_SCENE):
		push_warning("interaction_sandbox: objeto de log ausente")
		return
	var scene: PackedScene = load(LOG_OBJECT_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is LogObject):
		instance.free()
		return
	var object: LogObject = instance
	object.position = at
	object.prompt_text = prompt
	object.prop_column = 3
	object.interacted.connect(_on_interacted)
	add_child(object)


func _refresh_status() -> void:
	if _status == null:
		return
	_status.text = "INTERAÇÕES %d" % _count


func _on_interacted(_actor: Node) -> void:
	_count += 1
	_refresh_status()


func _on_interaction_available(prompt: String) -> void:
	if _prompt != null:
		_prompt.text = prompt


func _on_interaction_cleared() -> void:
	if _prompt != null:
		_prompt.text = ""
