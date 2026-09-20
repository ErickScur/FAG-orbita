extends Node2D

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const CARD_SCENE: String = "res://scenes/ui/tutorial_card.tscn"
const BACKGROUND_COLOR: Color = Color("#10161c")
const FLOOR_COLOR: Color = Color("#2f4f5a")
const ROOM: Vector2 = Vector2(384, 216)
const FLOOR_TOP: float = 168.0
const DAMAGE_AMOUNT: int = 25
const CHARGE_SPENT: float = 32.0
const CRITICAL_TARGET: float = 14.0
const LOG_ID: StringName = &"log_core_01"

var _frame: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"level")
	add_to_group(&"gameplay")
	_build_background()
	Settings.difficulty = &"normal"
	Settings.no_timer = false
	GameState.new_game()
	GameState.set_objective(&"obj_greenhouse")
	_spawn(HUD_SCENE)
	_spawn(CARD_SCENE)


func _process(_delta: float) -> void:
	_frame += 1
	match _frame:
		20:
			GameState.set_reactor_online(true)
			GameState.unlock_ability(&"magnetic_claws")
		26:
			GameState.apply_damage(DAMAGE_AMOUNT)
			GameState.spend_charge(CHARGE_SPENT)
			GameState.register_pickup(&"log", LOG_ID)
			GameState.register_pickup(&"research", &"data_core_01")
		180:
			GameState.change_reactor(CRITICAL_TARGET - GameState.reactor_percent)
		250:
			GameState.change_reactor(Balance.REACTOR_START - GameState.reactor_percent)
			EventBus.tutorial_requested.emit(&"tut_chassis")
		360:
			DialogueManager.open_log(LOG_ID)


func _exit_tree() -> void:
	EventBus.dialogue_finished.emit()


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


func _spawn(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("chassis_probe: cena ausente %s" % path)
		return
	add_child(load(path).instantiate())
