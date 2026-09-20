extends SandboxRoom

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const COLLECTIBLE_SCENE: String = "res://scenes/world/collectible.tscn"
const DOCK_SCENE: String = "res://scenes/world/backup_dock.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 384, 216)
const FLOOR: Rect2 = Rect2(0, 168, 384, 48)
const ITEM_Y: float = 152.0
const DOCK_IDLE_X: float = 48.0
const DOCK_CHARGING_X: float = 336.0
const SPAWN: Vector2 = Vector2(336, 156)
const START_CHARGE: float = 30.0
const START_INTEGRITY: int = 60
const DARK_TINT: Color = Color(0.32, 0.36, 0.42)
const FRAME_FIRST_PICKUP: int = 45
const FRAME_SECOND_PICKUP: int = 105
const FRAME_DARK: int = 165
const FRAME_LIGHT: int = 255
const ITEMS: Array[Dictionary] = [
	{"kind": &"cell", "id": &"lineup_cell", "x": 112.0},
	{"kind": &"repair_kit", "id": &"lineup_kit", "x": 152.0},
	{"kind": &"log", "id": &"log_core_01", "x": 192.0},
	{"kind": &"research", "id": &"lineup_research", "x": 232.0},
	{"kind": &"capacitor", "id": &"lineup_capacitor", "x": 272.0},
]

var _frame: int = 0
var _items: Array[Collectible] = []
var _modulate: CanvasModulate = null


func _ready() -> void:
	add_to_group(&"level")
	add_to_group(&"gameplay")
	build_room(ROOM)
	add_solid(FLOOR)
	_prepare_state()
	_spawn_docks()
	_spawn_items()
	spawn_player(SPAWN)
	_spawn_modulate()
	_mount_hud()


func _process(_delta: float) -> void:
	_frame += 1
	match _frame:
		FRAME_FIRST_PICKUP:
			_collect(0)
		FRAME_SECOND_PICKUP:
			_collect(3)
		FRAME_DARK:
			_modulate.color = DARK_TINT
		FRAME_LIGHT:
			_modulate.color = Color.WHITE


func _prepare_state() -> void:
	Settings.difficulty = &"normal"
	Settings.no_timer = true
	GameState.new_game()
	GameState.charge = START_CHARGE
	GameState.integrity = START_INTEGRITY
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	EventBus.integrity_changed.emit(GameState.integrity, GameState.integrity_max)


func _spawn_items() -> void:
	if not ResourceLoader.exists(COLLECTIBLE_SCENE):
		push_warning("pickup_lineup: coletável ausente")
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
		_items.append(item)


func _spawn_docks() -> void:
	if not ResourceLoader.exists(DOCK_SCENE):
		push_warning("pickup_lineup: doca ausente")
		return
	var scene: PackedScene = load(DOCK_SCENE)
	_add_dock(scene, DOCK_IDLE_X, &"lineup_dock_idle")
	_add_dock(scene, DOCK_CHARGING_X, &"lineup_dock_charging")


func _add_dock(scene: PackedScene, x: float, dock_id: StringName) -> void:
	var instance: Node = scene.instantiate()
	if not (instance is BackupDock):
		instance.free()
		return
	var dock: BackupDock = instance
	dock.dock_id = dock_id
	dock.position = Vector2(x, FLOOR.position.y)
	add_child(dock)


func _spawn_modulate() -> void:
	_modulate = CanvasModulate.new()
	_modulate.color = Color.WHITE
	add_child(_modulate)


func _collect(index: int) -> void:
	if index < 0 or index >= _items.size():
		return
	var item: Collectible = _items[index]
	if not is_instance_valid(item):
		return
	item.collect()


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("pickup_lineup: HUD ausente")
		return
	add_child(load(HUD_SCENE).instantiate())
