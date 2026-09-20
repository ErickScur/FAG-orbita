extends SandboxRoom

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const WALL_SCENE: String = "res://scenes/world/magnetic_wall.tscn"
const ROOM: Rect2i = Rect2i(0, 0, 384, 216)
const SPAWN: Vector2 = Vector2(80, 176)
const FLOOR: Rect2 = Rect2(0, 176, 384, 40)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(384, -64, 16, 280)
const LEDGE: Rect2 = Rect2(152, 72, 64, 8)
const WALL_COLUMN_X: float = 248.0
const WALL_BOTTOM_Y: float = 168.0
const WALL_TILES: int = 8
const UNLOCK_FRAME: int = 150

var _player: Mu7 = null
var _status: Label = null
var _frame: int = 0


func _ready() -> void:
	add_to_group(&"level")
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	add_solid(LEDGE)
	Settings.difficulty = &"normal"
	GameState.new_game()
	_build_magnetic_wall()
	_player = spawn_player(SPAWN)
	_mount_hud()
	_status = add_label(Control.PRESET_CENTER_TOP, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _process(_delta: float) -> void:
	_frame += 1
	if _frame == UNLOCK_FRAME:
		GameState.unlock_ability(ClimbLogic.ABILITY_ID)
	if _status == null:
		return
	_status.text = "GARRAS %s\nESTADO %s\nALTURA %d" % [
		"LIBERADAS" if GameState.has_ability(ClimbLogic.ABILITY_ID) else "BLOQUEADAS",
		"ESCALANDO" if _is_climbing() else "NORMAL",
		roundi(FLOOR.position.y - _player_feet()),
	]


func spawn_position() -> Vector2:
	return SPAWN


func _is_climbing() -> bool:
	return _player != null and _player.is_climbing()


func _player_feet() -> float:
	if _player == null:
		return FLOOR.position.y
	return _player.global_position.y


func _build_magnetic_wall() -> void:
	if not ResourceLoader.exists(WALL_SCENE):
		push_warning("claw_sandbox: parede magnética ausente")
		return
	var scene: PackedScene = load(WALL_SCENE)
	for index: int in range(WALL_TILES):
		var instance: Node = scene.instantiate()
		if not (instance is Node2D):
			instance.free()
			continue
		var tile: Node2D = instance
		tile.position = Vector2(
			WALL_COLUMN_X, WALL_BOTTOM_Y - float(index * Balance.TILE_SIZE)
		)
		add_child(tile)


func _mount_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("claw_sandbox: HUD ausente")
		return
	add_child(load(HUD_SCENE).instantiate())
