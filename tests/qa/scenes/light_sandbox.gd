extends SandboxRoom

const ROOM: Rect2i = Rect2i(0, 0, 768, 216)
const SPAWN: Vector2 = Vector2(96, 160)
const LAMP_SCENE: String = "res://scenes/world/powered_lamp.tscn"
const FLOOR: Rect2 = Rect2(0, 160, 768, 56)
const CEILING: Rect2 = Rect2(0, 0, 768, 32)
const WALL_LEFT: Rect2 = Rect2(-16, -64, 16, 280)
const WALL_RIGHT: Rect2 = Rect2(768, -64, 16, 280)
const PILLARS: Array[Rect2] = [
	Rect2(256, 96, 16, 64),
	Rect2(352, 96, 16, 64),
	Rect2(512, 96, 16, 64),
]
const LAMP_POSITIONS: Array[Vector2] = [Vector2(176, 136), Vector2(448, 136)]
const TERMINAL_ID: StringName = &"sandbox_terminal"
const SYSTEM_ID: StringName = &"lights_sandbox"
const LIT_SOLID_COLOR: Color = Color("#9fb6c0")

@export var start_charge: float = 8.0

var _lamps: Array[PoweredLamp] = []
var _powered: bool = true
var _status: Label = null


func _ready() -> void:
	solid_color = LIT_SOLID_COLOR
	build_room(ROOM)
	add_solid(FLOOR)
	add_solid(CEILING)
	add_solid(WALL_LEFT)
	add_solid(WALL_RIGHT)
	for rect: Rect2 in PILLARS:
		add_solid(rect, true)
	add_child(AmbientDarkness.new())
	for at: Vector2 in LAMP_POSITIONS:
		_spawn_lamp(at)
	spawn_player(SPAWN)
	_status = add_label(Control.PRESET_TOP_LEFT, "")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	GameState.new_game()
	GameState.charge = start_charge
	EventBus.charge_changed.emit(GameState.charge, GameState.charge_max)


func _process(_delta: float) -> void:
	if _status == null:
		return
	_status.text = "CARGA %d  LANTERNA %s  LÂMPADAS %s" % [
		roundi(GameState.charge),
		"ON" if player != null and player.is_flashlight_on() else "OFF",
		"ON" if _powered else "OFF",
	]


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"interact"):
		return
	_powered = not _powered
	EventBus.energy_changed.emit(TERMINAL_ID, SYSTEM_ID, _powered)


func _spawn_lamp(at: Vector2) -> void:
	if not ResourceLoader.exists(LAMP_SCENE):
		push_warning("light_sandbox: lâmpada ausente")
		return
	var scene: PackedScene = load(LAMP_SCENE)
	var instance: Node = scene.instantiate()
	if not (instance is PoweredLamp):
		instance.free()
		return
	var lamp: PoweredLamp = instance
	lamp.position = at
	lamp.terminal_id = TERMINAL_ID
	lamp.system_id = SYSTEM_ID
	lamp.powered = true
	add_child(lamp)
	_lamps.append(lamp)
