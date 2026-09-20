extends SandboxRoom

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const SPORE_SCENE: String = "res://scenes/enemies/spore_swarm.tscn"
const DOCK_SCENE: String = "res://scenes/world/backup_dock.tscn"
const CELL_SCENE: String = "res://scenes/world/collectible.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 384, 216)
const SPAWN: Vector2 = Vector2(40, 160)
const FLOOR: Rect2 = Rect2(0, 160, 384, 56)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(384, -64, 16, 280)
const DOCK_SPAWN: Vector2 = Vector2(40, 160)
const SWARM_SPAWN: Vector2 = Vector2(250, 144)
const CELL_NEAR_SPAWN: Vector2 = Vector2(150, 144)
const CELL_FAR_SPAWN: Vector2 = Vector2(340, 144)
const CELL_NEAR_ID: StringName = &"spore_sandbox_cell_a"
const CELL_FAR_ID: StringName = &"spore_sandbox_cell_b"
const TERMINAL_ID: StringName = &"greenhouse"
const SYSTEM_ID: StringName = &"heating"
const START_CHARGE: float = 40.0
const HEAT_OFF_FRAME: int = 740
const HEAT_ON_FRAME: int = 900

var _swarm: SporeSwarm = null
var _dock: BackupDock = null
var _cell_near: Collectible = null
var _cell_far: Collectible = null
var _status: Label = null
var _frame: int = 0


func _ready() -> void:
	add_to_group(&"level")
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	Settings.difficulty = &"normal"
	GameState.new_game()
	GameState.charge = START_CHARGE
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)
	_spawn_dock()
	_spawn_swarm()
	_spawn_cells()
	spawn_player(SPAWN)
	_mount_hud()
	_status = add_label(Control.PRESET_CENTER_TOP, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _process(_delta: float) -> void:
	_frame += 1
	_run_timeline()
	if _status == null:
		return
	_status.text = (
		"INTEGRIDADE %d/%d  CARGA %d\nAQUECIMENTO %s  RAIO %d\nCORROSAO %.1f"
		+ "\nCELULAS %s / %s"
	) % [
		GameState.integrity,
		GameState.integrity_max,
		roundi(GameState.charge),
		"LIGADO" if _swarm != null and _swarm.is_heated() else "DESLIGADO",
		roundi(_swarm.current_radius()) if _swarm != null else 0,
		GameState.statuses.remaining(StatusEffects.CORROSION),
		"NO CHAO" if is_instance_valid(_cell_near) else "COLETADA",
		"NO CHAO" if is_instance_valid(_cell_far) else "COLETADA",
	]


func spawn_position() -> Vector2:
	return SPAWN


func _run_timeline() -> void:
	if _frame == HEAT_OFF_FRAME:
		EventBus.energy_changed.emit(TERMINAL_ID, SYSTEM_ID, false)
	elif _frame == HEAT_ON_FRAME:
		EventBus.energy_changed.emit(TERMINAL_ID, SYSTEM_ID, true)


func _spawn_swarm() -> void:
	if not ResourceLoader.exists(SPORE_SCENE):
		push_warning("spore_sandbox: enxame ausente")
		return
	var instance: Node = load(SPORE_SCENE).instantiate()
	if not (instance is SporeSwarm):
		instance.free()
		return
	_swarm = instance
	_swarm.terminal_id = TERMINAL_ID
	_swarm.system_id = SYSTEM_ID
	_swarm.powered = true
	_swarm.position = SWARM_SPAWN
	add_child(_swarm)


func _spawn_dock() -> void:
	if not ResourceLoader.exists(DOCK_SCENE):
		push_warning("spore_sandbox: doca ausente")
		return
	var instance: Node = load(DOCK_SCENE).instantiate()
	if not (instance is BackupDock):
		instance.free()
		return
	_dock = instance
	_dock.dock_id = &"spore_sandbox_dock"
	_dock.position = DOCK_SPAWN
	add_child(_dock)


func _spawn_cells() -> void:
	_cell_near = _spawn_cell(CELL_NEAR_ID, CELL_NEAR_SPAWN)
	_cell_far = _spawn_cell(CELL_FAR_ID, CELL_FAR_SPAWN)


func _spawn_cell(item_id: StringName, at: Vector2) -> Collectible:
	if not ResourceLoader.exists(CELL_SCENE):
		push_warning("spore_sandbox: coletável ausente")
		return null
	var instance: Node = load(CELL_SCENE).instantiate()
	if not (instance is Collectible):
		instance.free()
		return null
	var cell: Collectible = instance
	cell.kind = PickupRules.KIND_CELL
	cell.item_id = item_id
	cell.position = at
	add_child(cell)
	return cell


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("spore_sandbox: HUD ausente")
		return
	add_child(load(HUD_SCENE).instantiate())
