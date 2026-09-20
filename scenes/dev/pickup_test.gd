extends SandboxRoom

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const COLLECTIBLE_SCENE: String = "res://scenes/world/collectible.tscn"
const LOG_OBJECT_SCENE: String = "res://scenes/world/log_object.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 768, 216)
const SPAWN: Vector2 = Vector2(40, 160)
const FLOOR: Rect2 = Rect2(0, 160, 768, 56)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(768, -64, 16, 280)
const ITEM_Y: float = 144.0
const START_CHARGE: float = 30.0
const START_INTEGRITY: int = 60
const STARTED_FLAG: String = "pickup_test_started"
const START_REACTOR: float = 80.0
const LOG_FRAGMENT: StringName = &"log_core_01"
const LOG_TERMINAL: StringName = &"log_gh_01"
const LOG_TERMINAL_X: float = 744.0
const ITEMS: Array[Dictionary] = [
	{"kind": &"cell", "id": &"pickup_test_cell", "x": 120.0},
	{"kind": &"repair_kit", "id": &"pickup_test_kit", "x": 240.0},
	{"kind": &"research", "id": &"pickup_test_research", "x": 360.0},
	{"kind": &"log", "id": LOG_FRAGMENT, "x": 480.0},
	{"kind": &"capacitor", "id": &"pickup_test_capacitor", "x": 620.0},
]

var _status: Label = null


func _ready() -> void:
	add_to_group(&"level")
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	_prepare_state()
	_spawn_items()
	_spawn_log_terminal()
	spawn_player(SPAWN)
	_mount_hud()
	_status = add_label(Control.PRESET_CENTER_LEFT, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _process(_delta: float) -> void:
	if _status == null:
		return
	_status.text = "CARGA %d/%d  INTEGRIDADE %d/%d\nLOGS %d  DADOS %d  ITENS %d" % [
		roundi(GameState.charge),
		roundi(GameState.charge_max),
		GameState.integrity,
		GameState.integrity_max,
		GameState.logs_collected.size(),
		GameState.research_collected.size(),
		GameState.collected_ids.size(),
	]


func _prepare_state() -> void:
	Settings.difficulty = &"normal"
	if bool(GameState.flags.get(STARTED_FLAG, false)):
		return
	GameState.new_game()
	GameState.charge = START_CHARGE
	GameState.integrity = START_INTEGRITY
	GameState.flags[STARTED_FLAG] = true
	GameState.set_reactor_online(true)
	GameState.change_reactor(START_REACTOR - GameState.reactor_percent)
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	EventBus.integrity_changed.emit(GameState.integrity, GameState.integrity_max)


func _spawn_items() -> void:
	if not ResourceLoader.exists(COLLECTIBLE_SCENE):
		push_warning("pickup_test: coletável ausente")
		return
	var scene: PackedScene = load(COLLECTIBLE_SCENE)
	for entry: Dictionary in ITEMS:
		var instance: Node = scene.instantiate()
		if not (instance is Collectible):
			instance.free()
			continue
		var item: Collectible = instance
		item.kind = StringName(entry["kind"])
		item.item_id = StringName(entry["id"])
		item.position = Vector2(float(entry["x"]), ITEM_Y)
		add_child(item)


func _spawn_log_terminal() -> void:
	if not ResourceLoader.exists(LOG_OBJECT_SCENE):
		push_warning("pickup_test: terminal de registros ausente")
		return
	var instance: Node = load(LOG_OBJECT_SCENE).instantiate()
	if not (instance is LogObject):
		instance.free()
		return
	var terminal: LogObject = instance
	terminal.log_id = LOG_TERMINAL
	terminal.prompt_text = "LER REGISTRO"
	terminal.prop_column = 3
	terminal.position = Vector2(LOG_TERMINAL_X, FLOOR.position.y)
	terminal.interacted.connect(_on_log_terminal_used)
	add_child(terminal)


func _on_log_terminal_used(_actor: Node) -> void:
	DialogueManager.open_log(LOG_TERMINAL)


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("pickup_test: HUD ausente")
		return
	add_child(load(HUD_SCENE).instantiate())
