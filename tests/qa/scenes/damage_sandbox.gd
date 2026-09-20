extends SandboxRoom

const ROOM: Rect2i = Rect2i(0, 0, 768, 216)
const SPAWN: Vector2 = Vector2(64, 160)
const DOCK_SCENE: String = "res://scenes/world/backup_dock.tscn"
const DOCK_POSITION: Vector2 = Vector2(64, 160)
const CONTACT_RECT: Rect2 = Rect2(200, 144, 8, 16)
const DPS_RECT: Rect2 = Rect2(288, 128, 64, 32)
const FLOOR_LEFT: Rect2 = Rect2(0, 160, 440, 56)
const FLOOR_RIGHT: Rect2 = Rect2(504, 160, 264, 56)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(768, -64, 16, 280)
const DEATH_ZONE: Rect2 = Rect2(440, 200, 64, 16)

@export var start_charge: float = 40.0

var _dock: BackupDock = null
var _status: Label = null


func _ready() -> void:
	build_room(ROOM)
	add_solid(FLOOR_LEFT)
	add_solid(FLOOR_RIGHT)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	add_hazard(CONTACT_RECT, Balance.SR3_CONTACT_DAMAGE, 0.0, true)
	add_hazard(DPS_RECT, 0, Balance.SPORE_DPS, false)
	_add_death_zone()
	_spawn_dock()
	spawn_player(SPAWN)
	_status = add_label(Control.PRESET_TOP_LEFT, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	Settings.difficulty = &"normal"
	GameState.new_game()
	GameState.charge = start_charge
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)


func _process(_delta: float) -> void:
	if _status == null:
		return
	_status.text = "INTEGRIDADE %d/%d\nCARGA %d/%d\nMORTES %d  DOCA %s\nDIFICULDADE %s  X %d" % [
		GameState.integrity,
		GameState.integrity_max,
		roundi(GameState.charge),
		roundi(GameState.charge_max),
		GameState.deaths,
		"SIM" if _dock != null and _dock.is_charging() else "NAO",
		String(Settings.difficulty).to_upper(),
		roundi(player.global_position.x) if player != null else 0,
	]


func _add_death_zone() -> void:
	var area: DamageArea = add_hazard(DEATH_ZONE, Balance.INTEGRITY_MAX * 2, 0.0, false)
	area.knockback = false


func _spawn_dock() -> void:
	if not ResourceLoader.exists(DOCK_SCENE):
		push_warning("damage_sandbox: doca ausente")
		return
	var scene: PackedScene = load(DOCK_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is BackupDock):
		instance.free()
		return
	_dock = instance
	_dock.dock_id = &"sandbox_dock"
	_dock.position = DOCK_POSITION
	add_child(_dock)
