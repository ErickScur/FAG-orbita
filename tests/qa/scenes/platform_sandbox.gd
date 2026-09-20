extends SandboxRoom

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const PLATFORM_SCENE: String = "res://scenes/world/moving_platform.tscn"
const PLANT_SCENE: String = "res://scenes/world/grow_plant.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 384, 216)
const SPAWN: Vector2 = Vector2(60, 176)
const FLOOR: Rect2 = Rect2(0, 176, 384, 40)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(384, -64, 16, 280)
const STEP: Rect2 = Rect2(232, 146, 40, 30)
const PLATFORM_SPAWN: Vector2 = Vector2(120, 168)
const PLATFORM_PATH: Array = [[0, 0], [0, -6]]
const PLANT_SPAWN: Vector2 = Vector2(296, 176)
const TERMINAL_ID: StringName = &"qa"
const LIFT_ID: StringName = &"lift"
const GROW_ID: StringName = &"grow_light"
const PLANT_ID: StringName = &"qa_plant"
const LIFT_ON_FRAME: int = 160
const LIFT_OFF_FRAME: int = 380
const GROW_ON_FRAME: int = 410
const GROW_OFF_FRAME: int = 560

var _platform: MovingPlatform = null
var _plant: GrowPlant = null
var _player: Mu7 = null
var _status: Label = null
var _frame: int = 0


func _ready() -> void:
	add_to_group(&"level")
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	add_solid(STEP)
	Settings.difficulty = &"normal"
	GameState.new_game()
	_spawn_platform()
	_spawn_plant()
	_player = spawn_player(SPAWN)
	_mount_hud()
	_status = add_label(Control.PRESET_CENTER_TOP, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _process(_delta: float) -> void:
	_frame += 1
	_run_timeline()
	if _status == null:
		return
	_status.text = (
		"ELEVADOR %s  ALTURA %d\nLUZ DE CRESCIMENTO %s\nPLANTA %d%%  TOPO %s\nMU7 %d %d"
	) % [
		"LIGADO" if _lift_powered() else "DESLIGADO",
		roundi(FLOOR.position.y - _platform_y()),
		"LIGADA" if _grow_powered() else "DESLIGADA",
		roundi(_plant_progress() * 100.0),
		"SOLIDO" if _plant_grown() else "BROTO",
		roundi(_player_position().x),
		roundi(_player_position().y),
	]


func spawn_position() -> Vector2:
	return SPAWN


func _run_timeline() -> void:
	if _frame == LIFT_ON_FRAME:
		EventBus.energy_changed.emit(TERMINAL_ID, LIFT_ID, true)
	elif _frame == LIFT_OFF_FRAME:
		EventBus.energy_changed.emit(TERMINAL_ID, LIFT_ID, false)
	elif _frame == GROW_ON_FRAME:
		EventBus.energy_changed.emit(TERMINAL_ID, GROW_ID, true)
	elif _frame == GROW_OFF_FRAME:
		EventBus.energy_changed.emit(TERMINAL_ID, GROW_ID, false)


func _lift_powered() -> bool:
	return _platform != null and _platform.powered


func _grow_powered() -> bool:
	return _plant != null and _plant.powered


func _platform_y() -> float:
	if _platform == null:
		return FLOOR.position.y
	return _platform.position.y


func _player_position() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	return _player.global_position


func _plant_progress() -> float:
	if _plant == null:
		return 0.0
	return _plant.progress()


func _plant_grown() -> bool:
	return _plant != null and _plant.is_grown()


func _spawn_platform() -> void:
	if not ResourceLoader.exists(PLATFORM_SCENE):
		push_warning("platform_sandbox: plataforma ausente")
		return
	var instance: Node = load(PLATFORM_SCENE).instantiate()
	if not (instance is MovingPlatform):
		instance.free()
		return
	_platform = instance
	_platform.position = PLATFORM_SPAWN
	_platform.terminal_id = TERMINAL_ID
	_platform.system_id = LIFT_ID
	_platform.path_tiles = MovingPlatform.points_from(PLATFORM_PATH)
	_platform.powered = false
	add_child(_platform)


func _spawn_plant() -> void:
	if not ResourceLoader.exists(PLANT_SCENE):
		push_warning("platform_sandbox: planta ausente")
		return
	var instance: Node = load(PLANT_SCENE).instantiate()
	if not (instance is GrowPlant):
		instance.free()
		return
	_plant = instance
	_plant.position = PLANT_SPAWN
	_plant.terminal_id = TERMINAL_ID
	_plant.system_id = GROW_ID
	_plant.plant_id = PLANT_ID
	_plant.powered = false
	add_child(_plant)


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("platform_sandbox: HUD ausente")
		return
	add_child(load(HUD_SCENE).instantiate())
