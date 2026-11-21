class_name RootCoupler
extends Coupler

signal overloaded(coupler_id: StringName)
signal overload_cancelled(coupler_id: StringName)

const ROOT_SHEET: String = "res://assets/sprites/world/root_coupler_sheet.png"
const ROOT_GROUP: StringName = &"root_coupler"
const PANEL_SIZE: Vector2 = Vector2(28.0, 30.0)
const PANEL_LAYER: int = 8
const FRAME_UNFED: int = 0
const FRAME_FED: int = 1
const FRAME_CHARGING: int = 2
const FRAME_BURNT: int = 3
const FED_COLOR: Color = Color("5fe8ff")
const ROOT_COLOR: Color = Color("c08cff")
const FED_ENERGY: float = 0.9
const CHARGING_ENERGY: float = 1.4
const BURNT_ENERGY: float = 0.5
const PROMPT_UNFED: StringName = &"root_coupler_unfed"
const PROMPT_READY: StringName = &"root_coupler_ready"
const PROMPT_NO_ROOT: StringName = &"root_coupler_no_root"
const PROMPT_CHARGING: StringName = &"root_coupler_charging"
const PROMPT_DONE: StringName = &"root_coupler_done"

var _panel: Interactable = null
var _charger: Node2D = null
var _charge_left: float = 0.0
var _burnt: bool = false


func _ready() -> void:
	super()
	add_to_group(ROOT_GROUP)
	_sprite.texture = AssetResolver.texture(ROOT_SHEET)
	_pips.visible = false
	_socket.set_enabled(false)
	_build_panel()
	set_state(state)


func _process(delta: float) -> void:
	if state != State.CHARGING:
		return
	if not powered or not _actor_in_range():
		cancel_overload()
		return
	_charge_left = maxf(0.0, _charge_left - delta)
	if _charge_left > 0.0:
		return
	_finish_overload()


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	if _burnt:
		return
	if state == State.CHARGING and not on:
		cancel_overload()
		return
	set_state(State.POWERED if on else State.OFF)


func set_powered_silent(on: bool) -> void:
	powered = on
	if _burnt:
		set_state(State.SEALED)
		return
	set_state(State.POWERED if on else State.OFF)


func set_state(next: State) -> void:
	state = next
	if _sprite == null:
		return
	_sprite.frame = _frame_for(next)
	_glow.color = FED_COLOR if next == State.POWERED else ROOT_COLOR
	var energy: float = _energy_for(next)
	_glow.energy = energy
	_glow.enabled = energy > 0.0
	_refresh_panel()


func is_overloaded() -> bool:
	return _burnt


func is_charging() -> bool:
	return state == State.CHARGING


func charge_left() -> float:
	return _charge_left


func can_overload() -> bool:
	return not _burnt and powered and state == State.POWERED and _has_root()


func begin_overload(actor: Node) -> bool:
	if not can_overload():
		AudioManager.play_sfx(&"ui_error")
		return false
	_charger = actor as Node2D
	_charge_left = Balance.ARGOS_COUPLER_CHARGE_TIME
	AudioManager.play_sfx(&"electric_buzz")
	set_state(State.CHARGING)
	return true


func cancel_overload() -> void:
	if state != State.CHARGING:
		return
	_charger = null
	_charge_left = 0.0
	AudioManager.play_sfx(&"ui_error")
	set_state(State.POWERED if powered else State.OFF)
	overload_cancelled.emit(coupler_id)


func force_overload() -> void:
	if _burnt:
		return
	_finish_overload()


func reset_overload() -> void:
	_burnt = false
	_charger = null
	_charge_left = 0.0
	set_state(State.POWERED if powered else State.OFF)


func panel() -> Interactable:
	return _panel


func _finish_overload() -> void:
	_burnt = true
	_charger = null
	_charge_left = 0.0
	AudioManager.play_sfx(&"terminal_breaker")
	Fx.burst(self, Fx.POWER_PULSE, global_position + Vector2(0.0, -16.0), ROOT_COLOR)
	set_state(State.SEALED)
	overloaded.emit(coupler_id)


func _actor_in_range() -> bool:
	if _charger == null or not is_instance_valid(_charger):
		return false
	return _charger.global_position.distance_to(global_position) <= Balance.ARGOS_COUPLER_RANGE


func _has_root() -> bool:
	return GameState.has_ability(UpgradeRules.ROOT_ABILITY)


func _frame_for(next: State) -> int:
	match next:
		State.POWERED:
			return FRAME_FED
		State.CHARGING:
			return FRAME_CHARGING
		State.SEALED:
			return FRAME_BURNT
	return FRAME_UNFED


func _energy_for(next: State) -> float:
	match next:
		State.POWERED:
			return FED_ENERGY
		State.CHARGING:
			return CHARGING_ENERGY
		State.SEALED:
			return BURNT_ENERGY
	return 0.0


func _build_panel() -> void:
	_panel = Interactable.new()
	_panel.name = "Panel"
	_panel.collision_layer = PANEL_LAYER
	_panel.position = Vector2(0.0, -PANEL_SIZE.y * 0.5)
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = PANEL_SIZE
	shape.shape = rectangle
	_panel.add_child(shape)
	_panel.interacted.connect(_on_panel_interacted)
	add_child(_panel)


func _refresh_panel() -> void:
	if _panel == null:
		return
	_panel.set_enabled(not _burnt and state != State.CHARGING)
	var prompt_id: StringName = PROMPT_READY
	if _burnt:
		prompt_id = PROMPT_DONE
	elif state == State.CHARGING:
		prompt_id = PROMPT_CHARGING
	elif not powered:
		prompt_id = PROMPT_UNFED
	elif not _has_root():
		prompt_id = PROMPT_NO_ROOT
	_panel.set_actionable(prompt_id == PROMPT_READY)
	_panel.set_prompt(InteractionRules.text(prompt_id))


func _on_panel_interacted(actor: Node) -> void:
	begin_overload(actor)
