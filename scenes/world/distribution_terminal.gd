class_name DistributionTerminal
extends Interactable

const UI_SCENE: String = "res://scenes/ui/energy_terminal_ui.tscn"
const SHEET_PATH: String = "res://assets/sprites/world/terminal_sheet.png"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const COLUMN_OFF: int = 0
const COLUMN_ON: int = 1
const COLUMN_ACTIVE: int = 2
const ROLE_CONSOLE: StringName = &"console"
const ROLE_SECTOR_NODE: StringName = &"sector_node"
const PROMPT_CONSOLE: String = "ACESSAR TERMINAL"
const PROMPT_NODE: String = "RELIGAR NÓ DO SETOR"
const PROMPT_NODE_DONE: String = "NÓ DO SETOR RELIGADO"
const PROMPT_NO_POWER: String = "TERMINAL SEM ENERGIA"

@export var terminal_id: StringName = &""
@export var role: StringName = &"console"
@export var sector_id: StringName = &""
@export var log_on_restore: StringName = &""

var _ui: CanvasLayer = null
var _actor: Node = null
var _restored: bool = false

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super()
	interacted.connect(_on_interacted)
	_refresh.call_deferred()


func configure(params: Dictionary) -> void:
	if params.has("terminal"):
		terminal_id = StringName(String(params["terminal"]))
	if params.has("role"):
		role = StringName(String(params["role"]))
	if params.has("sector"):
		sector_id = StringName(String(params["sector"]))
	if params.has("log_on_restore"):
		log_on_restore = StringName(String(params["log_on_restore"]))
	_refresh.call_deferred()


func is_sector_node() -> bool:
	return role == ROLE_SECTOR_NODE


func is_open() -> bool:
	return _ui != null and is_instance_valid(_ui)


func network() -> EnergyNetwork:
	var tree: SceneTree = get_tree()
	if tree == null:
		return null
	var node: Node = tree.get_first_node_in_group(&"energy_network")
	return node as EnergyNetwork


func _refresh() -> void:
	if not is_inside_tree():
		return
	if is_sector_node():
		_restored = GameState.sectors_restored.has(sector_id)
		enabled = true
		prompt_text = PROMPT_NODE_DONE if _restored else PROMPT_NODE
		_apply_column(COLUMN_ON if _restored else COLUMN_OFF)
		return
	var live: bool = _has_grid()
	enabled = live
	prompt_text = PROMPT_CONSOLE if live else PROMPT_NO_POWER
	_apply_column(COLUMN_ON if live else COLUMN_OFF)


func _has_grid() -> bool:
	var found: EnergyNetwork = network()
	return found != null and found.has_terminal(terminal_id)


func _apply_column(column: int) -> void:
	if _sprite == null:
		return
	var atlas: AtlasTexture = AssetResolver.atlas(SHEET_PATH, FRAME_SIZE, column, 0)
	if atlas == null:
		push_warning("DistributionTerminal: sprite sheet ausente em %s" % SHEET_PATH)
		return
	_sprite.texture = atlas


func _on_interacted(actor: Node) -> void:
	if is_sector_node():
		_restore_sector()
		return
	_open_ui(actor)


func _restore_sector() -> void:
	if _restored or sector_id == &"":
		return
	_restored = true
	prompt_text = PROMPT_NODE_DONE
	_apply_column(COLUMN_ON)
	if not GameState.sectors_restored.has(sector_id):
		GameState.sectors_restored.append(sector_id)
	AudioManager.play_sfx(&"sector_restored")
	EventBus.sector_restored.emit(sector_id)
	SaveManager.save_game()
	if log_on_restore != &"":
		DialogueManager.open_log(log_on_restore)


func _open_ui(actor: Node) -> void:
	if is_open():
		return
	var found: EnergyNetwork = network()
	if found == null or not found.has_terminal(terminal_id):
		AudioManager.play_sfx(&"ui_error")
		_refresh()
		return
	if not ResourceLoader.exists(UI_SCENE):
		push_warning("DistributionTerminal: UI ausente em %s" % UI_SCENE)
		return
	var packed: PackedScene = load(UI_SCENE)
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	if not (instance is CanvasLayer):
		instance.free()
		return
	_ui = instance
	_actor = actor
	var host: Node = get_tree().current_scene
	if host == null:
		host = get_tree().root
	host.add_child(_ui)
	_ui.connect(&"closed", _on_ui_closed)
	_lock_actor(true)
	_apply_column(COLUMN_ACTIVE)
	found.begin_session(terminal_id)
	_ui.call(&"open", terminal_id, found)


func _on_ui_closed() -> void:
	_ui = null
	_lock_actor(false)
	_apply_column(COLUMN_ON)
	var found: EnergyNetwork = network()
	if found != null:
		found.announce_change(terminal_id)


func _lock_actor(locked: bool) -> void:
	if _actor == null or not is_instance_valid(_actor):
		return
	if _actor.has_method(&"set_input_locked"):
		_actor.call(&"set_input_locked", locked)
	if _actor.has_method(&"set_invincible"):
		_actor.call(&"set_invincible", locked)
	if not locked:
		_actor = null
