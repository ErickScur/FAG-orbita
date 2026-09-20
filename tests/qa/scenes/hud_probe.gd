extends Node2D

const HUD_SCENE: String = "res://scenes/ui/hud.tscn"
const BACKGROUND_COLOR: Color = Color("#10161c")
const FLOOR_COLOR: Color = Color("#2f4f5a")
const ROOM: Vector2 = Vector2(384, 216)
const FLOOR_TOP: float = 168.0
const DAMAGE_AMOUNT: int = 40
const CHARGE_SPENT: float = 65.0
const CORROSION_DURATION: float = 6.0
const CRITICAL_TARGET: float = 18.0
const PROMPT_TEXT: String = "[E] ACESSAR TERMINAL"

var _frame: int = 0


func _ready() -> void:
	add_to_group(&"level")
	add_to_group(&"gameplay")
	_build_background()
	Settings.difficulty = &"normal"
	Settings.no_timer = false
	GameState.new_game()
	GameState.set_objective(&"obj_core_hub")
	_spawn_hud()


func _process(_delta: float) -> void:
	_frame += 1
	match _frame:
		34:
			GameState.set_reactor_online(true)
		64:
			GameState.apply_damage(DAMAGE_AMOUNT)
		94:
			GameState.spend_charge(CHARGE_SPENT)
			EventBus.status_applied.emit(&"corrosion", CORROSION_DURATION)
		154:
			EventBus.interaction_available.emit(PROMPT_TEXT)
		194:
			GameState.register_pickup(&"log", &"log_core_01")
		234:
			GameState.set_objective(&"obj_greenhouse")
		274:
			GameState.change_reactor(CRITICAL_TARGET - GameState.reactor_percent)
		324:
			EventBus.dialogue_started.emit()
		364:
			EventBus.dialogue_finished.emit()
			GameState.change_reactor(Balance.REACTOR_START - GameState.reactor_percent)
		404:
			EventBus.log_opened.emit(&"log_core_01")
		444:
			EventBus.log_closed.emit(&"log_core_01")


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


func _spawn_hud() -> void:
	if not ResourceLoader.exists(HUD_SCENE):
		push_warning("hud_probe: cena do HUD ausente")
		return
	var packed: PackedScene = load(HUD_SCENE)
	var instance: Node = packed.instantiate()
	add_child(instance)
