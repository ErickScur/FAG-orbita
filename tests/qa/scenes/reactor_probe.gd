extends Node2D

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const BACKGROUND_COLOR: Color = Color("#10161c")
const FLOOR_COLOR: Color = Color("#2f4f5a")
const ROOM: Vector2 = Vector2(384, 216)
const FLOOR_TOP: float = 168.0

@export var start_percent: float = 25.3
@export var time_scale: float = 90.0


func _ready() -> void:
	add_to_group(&"level")
	add_to_group(&"gameplay")
	_build_background()
	Settings.difficulty = &"normal"
	Settings.no_timer = false
	GameState.new_game()
	GameState.set_objective(&"obj_restore_gh")
	GameState.set_reactor_online(true)
	GameState.change_reactor(start_percent - GameState.reactor_percent)
	Engine.time_scale = maxf(1.0, time_scale)
	_spawn_hud()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _build_background() -> void:
	var background := ColorRect.new()
	background.size = ROOM
	background.color = BACKGROUND_COLOR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.z_index = -10
	add_child(background)
	var floor_rect := ColorRect.new()
	floor_rect.position = Vector2(0.0, FLOOR_TOP)
	floor_rect.size = Vector2(ROOM.x, ROOM.y - FLOOR_TOP)
	floor_rect.color = FLOOR_COLOR
	floor_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	floor_rect.z_index = -9
	add_child(floor_rect)


func _spawn_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("reactor_probe: cena do HUD ausente")
		return
	var packed: PackedScene = load(HUD_SCENE)
	var instance: Node = packed.instantiate()
	add_child(instance)
