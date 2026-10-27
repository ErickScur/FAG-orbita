extends SandboxRoom

const ROOM: Rect2i = Rect2i(0, 0, 1408, 216)
const SPAWN: Vector2 = Vector2(48, 176)
const AMBIENT: Color = Color("0d1219")
const V9_SCENE: String = "res://scenes/enemies/v9.tscn"
const ZONE_SCENE: String = "res://scenes/world/heat_zone.tscn"
const ISLAND_SCENE: String = "res://scenes/world/cold_island.tscn"
const ICE_SCENE: String = "res://scenes/world/thin_ice.tscn"
const WALL_SCENE: String = "res://scenes/world/ice_wall.tscn"
const HEATER_GROUP: StringName = &"sandbox_heater"
const FLOOR_WEST: Rect2 = Rect2(0, 176, 1008, 40)
const FLOOR_EAST: Rect2 = Rect2(1056, 176, 352, 40)
const PIT_BOTTOM: Rect2 = Rect2(1008, 208, 48, 8)
const CEILING: Rect2 = Rect2(0, 0, 1408, 32)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(1408, -64, 16, 280)
const V9_POSITION: Vector2 = Vector2(320, 120)
const V9_PATH: Array = [[0, 0], [2, 0]]
const COLD_POSITION: Vector2 = Vector2(648, 40)
const COLD_RECT: Array = [20, 9]
const WARM_POSITION: Vector2 = Vector2(808, 136)
const WARM_RECT: Array = [3, 3]
const ICE_CELLS: Array[Vector2] = [Vector2(1016, 184), Vector2(1032, 184), Vector2(1048, 184)]
const HEATER_POSITION: Vector2 = Vector2(1144, 120)
const HEATER_RECT: Array = [3, 4]
const HEATED_WALL_X: float = 1160.0
const CORE_WALL_X: float = 1304.0
const WALL_ROWS: Array[float] = [168.0, 152.0, 136.0]

var _status: Label = null
var _v9: V9 = null
var _heater: ColdIsland = null
var _ice: Array[ThinIce] = []
var _walls: Array[IceWall] = []
var _remembered_x: float = 0.0
var _remembered_charge: float = 0.0


func _ready() -> void:
	build_room(ROOM)
	var ambient := CanvasModulate.new()
	ambient.color = AMBIENT
	add_child(ambient)
	for rect: Rect2 in [FLOOR_WEST, FLOOR_EAST, PIT_BOTTOM, CEILING, WALL_LEFT, WALL_RIGHT]:
		add_solid(rect, true)
	_v9 = _place(V9_SCENE, V9_POSITION, {"path": V9_PATH})
	_place(ZONE_SCENE, COLD_POSITION, {"rect": COLD_RECT, "kind": "cold"})
	_place(ISLAND_SCENE, WARM_POSITION, {"rect": WARM_RECT, "kind": "warm"})
	_heater = _place(ISLAND_SCENE, HEATER_POSITION, {"rect": HEATER_RECT, "kind": "warm"})
	_heater.add_to_group(HEATER_GROUP)
	_heater.set_powered_silent(false)
	for cell: Vector2 in ICE_CELLS:
		_ice.append(_place(ICE_SCENE, cell, {}))
	for row: float in WALL_ROWS:
		_walls.append(_place(WALL_SCENE, Vector2(HEATED_WALL_X, row), {"heater": HEATER_GROUP}))
	for row: float in WALL_ROWS:
		_walls.append(_place(WALL_SCENE, Vector2(CORE_WALL_X, row), {}))
	spawn_player(SPAWN)
	_status = add_label(Control.PRESET_TOP_LEFT, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	Settings.difficulty = &"normal"
	GameState.new_game()


func _process(_delta: float) -> void:
	if _status == null:
		return
	var ids: PackedStringArray = []
	for status_id: StringName in GameState.statuses.active_ids():
		ids.append(String(status_id))
	_status.text = "INTEGRIDADE %d  CARGA %d  V-9 %s\nSTATUS %s" % [
		GameState.integrity, roundi(GameState.charge), _v9.state_name(), " ".join(ids)
	]


func expect_v9(wanted: String) -> void:
	_report(_v9.state_name() == wanted, "V-9 %s (atual %s)" % [wanted, _v9.state_name()])


func expect_integrity(wanted: float) -> void:
	var ok: bool = GameState.integrity == int(wanted)
	_report(ok, "integridade %d (atual %d)" % [int(wanted), GameState.integrity])


func expect_status(status_id: String, present: bool) -> void:
	var has: bool = GameState.has_status(StringName(status_id))
	_report(has == present, "status %s %s" % [status_id, "presente" if present else "ausente"])


func remember() -> void:
	_remembered_x = player.global_position.x
	_remembered_charge = GameState.charge
	print("[QA] sandbox lembrou x=%.1f carga=%.1f" % [_remembered_x, _remembered_charge])


func expect_still(tolerance: float) -> void:
	var moved: float = absf(player.global_position.x - _remembered_x)
	_report(moved <= tolerance, "sem empurrão (andou %.1f px)" % moved)


func expect_charge_drop(minimum: float, maximum: float) -> void:
	var drop: float = _remembered_charge - GameState.charge
	_report(drop >= minimum and drop <= maximum, "Carga caiu %.1f (de %.1f a %.1f)" % [
		drop, minimum, maximum
	])


func expect_ice(index: float, solid: bool) -> void:
	var ice: ThinIce = _ice[int(index)]
	_report(ice.is_solid() == solid, "gelo fino %d %s" % [int(index), _solid_word(solid)])


func expect_wall(index: float, solid: bool) -> void:
	var wall: IceWall = _walls[int(index)]
	_report(wall.is_solid() == solid, "parede de gelo %d %s" % [int(index), _solid_word(solid)])


func set_heater(on: bool) -> void:
	_heater.set_powered(on)


func _report(ok: bool, text: String) -> void:
	print("[QA] sandbox %s %s" % ["OK" if ok else "ERRO", text])


func _solid_word(solid: bool) -> String:
	return "sólida" if solid else "aberta"


func _place(scene_path: String, at: Vector2, params: Dictionary) -> Node2D:
	var node: Node2D = load(scene_path).instantiate()
	node.position = at
	if node.has_method(&"configure"):
		node.call(&"configure", params)
	add_child(node)
	return node
