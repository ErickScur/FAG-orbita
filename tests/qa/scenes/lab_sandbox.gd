extends SandboxRoom

const ROOM: Rect2i = Rect2i(0, 0, 768, 216)
const SPAWN: Vector2 = Vector2(64, 160)
const AMBIENT: Color = Color("0d1219")
const CX2_SCENE: String = "res://scenes/enemies/cx2.tscn"
const HEAT_SCENE: String = "res://scenes/world/heat_zone.tscn"
const COLD_SCENE: String = "res://scenes/world/cold_island.tscn"
const STEAM_SCENE: String = "res://scenes/world/steam_vent.tscn"
const FLOOR: Rect2 = Rect2(0, 160, 768, 56)
const CEILING: Rect2 = Rect2(0, 0, 768, 32)
const COVER: Rect2 = Rect2(224, 128, 16, 32)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(768, -64, 16, 280)
const TOWER_POSITION: Vector2 = Vector2(296, 40)
const HEAT_POSITION: Vector2 = Vector2(408, 104)
const HEAT_RECT: Array = [10, 4]
const COLD_POSITION: Vector2 = Vector2(472, 136)
const COLD_RECT: Array = [3, 2]
const VENT_POSITION: Vector2 = Vector2(632, 160)

var _status: Label = null


func _ready() -> void:
	build_room(ROOM)
	var ambient := CanvasModulate.new()
	ambient.color = AMBIENT
	add_child(ambient)
	for rect: Rect2 in [FLOOR, CEILING, COVER, WALL_LEFT, WALL_RIGHT]:
		add_solid(rect, true)
	_place(CX2_SCENE, TOWER_POSITION, {"mount": "ceiling"})
	_place(HEAT_SCENE, HEAT_POSITION, {"rect": HEAT_RECT, "kind": "warm"})
	_place(COLD_SCENE, COLD_POSITION, {"rect": COLD_RECT})
	_place(STEAM_SCENE, VENT_POSITION, {})
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
	_status.text = "INTEGRIDADE %d  CARGA %d\nSTATUS %s" % [
		GameState.integrity, roundi(GameState.charge), " ".join(ids)
	]


func _place(scene_path: String, at: Vector2, params: Dictionary) -> void:
	var node: Node2D = load(scene_path).instantiate()
	node.position = at
	if node.has_method(&"configure"):
		node.call(&"configure", params)
	add_child(node)
