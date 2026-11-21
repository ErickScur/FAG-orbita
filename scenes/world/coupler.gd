class_name Coupler
extends Node2D

enum State { OFF, CHARGING, POWERED, SEALED }

const SHEET: String = "res://assets/sprites/world/coupler_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const POWERED_GROUP: StringName = &"powered"
const COUPLER_GROUP: StringName = &"coupler"
const INTERACT_ACTION: StringName = &"interact"
const FRAME_SIZE: Vector2i = Vector2i(32, 32)
const GLOW_COLOR: Color = Color("5fe8ff")
const SEALED_COLOR: Color = Color("ff8a3a")
const GLOW_RADIUS: float = 28.0
const GLOW_ENERGY: Dictionary = {
	State.OFF: 0.0,
	State.CHARGING: 0.45,
	State.POWERED: 1.0,
	State.SEALED: 0.0,
}
const SOCKET_LAYER: int = 8
const SOCKET_SIZE: Vector2 = Vector2(24.0, 28.0)
const PROMPT_CHARGE: String = "SEGURAR PARA ACOPLAR"
const PROMPT_SEALED: String = "ACOPLADOR TRANCADO"
const BLINK_HZ: float = 2.0
const ARMED_GLOW: float = 0.35
const CHARGE_GLOW_MIN: float = 0.3
const SEALED_GLOW: float = 0.5
const PIP_COUNT: int = 3
const PIP_SIZE: float = 4.0
const PIP_GAP: float = 3.0
const PIP_HEIGHT: float = 38.0
const PIP_OFF: Color = Color(0.16, 0.2, 0.24, 1.0)
const PIP_ON: Color = Color("e8ffff")
const PIP_EDGE: Color = Color("0e1218")
const HOLD_REACH_X: float = 18.0
const HOLD_REACH_Y: float = 10.0
const SPRITE_Z: int = -2

@export var coupler_id: StringName = &""
@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = false

var state: State = State.OFF

var _sprite: Sprite2D = null
var _glow: PointLight2D = null
var _socket: Interactable = null
var _pips: Node2D = null
var _actor: Node2D = null
var _armed: bool = false
var _charge: float = 0.0
var _blink: float = 0.0


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(COUPLER_GROUP)
	_sprite = Sprite2D.new()
	_sprite.name = "Sprite"
	_sprite.texture = AssetResolver.texture(SHEET)
	_sprite.hframes = 4
	_sprite.z_index = SPRITE_Z
	_sprite.offset = Vector2(0.0, -float(FRAME_SIZE.y) * 0.5)
	add_child(_sprite)
	_glow = PointLight2D.new()
	_glow.name = "Glow"
	_glow.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_glow.color = GLOW_COLOR
	_glow.blend_mode = Light2D.BLEND_MODE_ADD
	_glow.shadow_enabled = false
	_glow.position = Vector2(0.0, -float(FRAME_SIZE.y) * 0.5)
	_glow.texture_scale = LightMath.scale_for_radius(GLOW_RADIUS, LightMath.TEXTURE_SIZE)
	add_child(_glow)
	_build_socket()
	_build_pips()
	set_powered_silent(powered)


func _process(delta: float) -> void:
	if not _armed or state == State.POWERED:
		return
	_blink += delta
	_refresh_look()


func configure(params: Dictionary) -> void:
	coupler_id = StringName(String(params.get("coupler_id", params.get("id", coupler_id))))
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("powered"):
		powered = bool(params["powered"])
	if _sprite == null:
		return
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on and state != State.SEALED:
		return
	powered = on
	AudioManager.play_sfx(&"power_on" if on else &"power_off")
	set_state(State.POWERED if on else State.OFF)


func set_powered_silent(on: bool) -> void:
	powered = on
	set_state(State.POWERED if on else State.OFF)


func set_state(next: State) -> void:
	state = next
	if next == State.POWERED or next == State.SEALED:
		_charge = 1.0 if next == State.POWERED else 0.0
	_refresh_socket()
	_refresh_look()


func set_armed(on: bool) -> void:
	_armed = on
	_blink = 0.0
	if not on:
		_actor = null
	_refresh_socket()
	_refresh_look()


func is_armed() -> bool:
	return _armed


func set_charge(ratio: float) -> void:
	var next: float = clampf(ratio, 0.0, 1.0)
	if is_equal_approx(next, _charge):
		return
	_charge = next
	_refresh_look()


func charge() -> float:
	return _charge


func is_powered() -> bool:
	return state == State.POWERED


func is_sealed() -> bool:
	return state == State.SEALED


func socket() -> Interactable:
	return _socket


func is_held() -> bool:
	if not _armed or _actor == null or not is_instance_valid(_actor):
		return false
	if not Input.is_action_pressed(INTERACT_ACTION):
		return false
	var offset: Vector2 = _actor.global_position - global_position
	if absf(offset.x) > HOLD_REACH_X or absf(offset.y) > HOLD_REACH_Y:
		return false
	if _actor is CharacterBody2D and not (_actor as CharacterBody2D).is_on_floor():
		return false
	if _actor.has_method(&"interaction_target"):
		return _actor.call(&"interaction_target") == _socket
	return true


func _build_socket() -> void:
	_socket = Interactable.new()
	_socket.name = "Socket"
	_socket.collision_layer = SOCKET_LAYER
	_socket.prompt_text = PROMPT_CHARGE
	_socket.enabled = false
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = SOCKET_SIZE
	shape.shape = box
	shape.position = Vector2(0.0, -SOCKET_SIZE.y * 0.5)
	_socket.add_child(shape)
	add_child(_socket)
	_socket.interacted.connect(_on_socket_interacted)


func _build_pips() -> void:
	_pips = Node2D.new()
	_pips.name = "Pips"
	_pips.z_index = 1
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_pips.material = material
	_pips.draw.connect(_draw_pips)
	add_child(_pips)


func _refresh_socket() -> void:
	if _socket == null:
		return
	_socket.set_enabled(_armed and state != State.POWERED)
	_socket.set_prompt(PROMPT_SEALED if state == State.SEALED else PROMPT_CHARGE)


func _refresh_look() -> void:
	if _sprite == null:
		return
	var frame: int = int(state)
	var energy: float = float(GLOW_ENERGY.get(state, 0.0))
	var color: Color = GLOW_COLOR
	if state == State.OFF and _charge > 0.0:
		frame = int(State.CHARGING)
		energy = lerpf(CHARGE_GLOW_MIN, 1.0, _charge)
	elif state == State.OFF and _armed:
		var lit: bool = fmod(_blink * BLINK_HZ, 1.0) < 0.5
		frame = int(State.CHARGING) if lit else int(State.OFF)
		energy = ARMED_GLOW if lit else 0.0
	elif state == State.SEALED and _armed:
		color = SEALED_COLOR
		energy = SEALED_GLOW
	_sprite.frame = frame
	_glow.color = color
	_glow.energy = energy
	_glow.enabled = energy > 0.0
	_pips.visible = _armed or state == State.POWERED
	_pips.queue_redraw()


func _draw_pips() -> void:
	var lit: int = int(floor(_charge * float(PIP_COUNT) + 0.001))
	if state == State.POWERED:
		lit = PIP_COUNT
	var width: float = PIP_COUNT * PIP_SIZE + (PIP_COUNT - 1) * PIP_GAP
	var left: float = -width * 0.5
	for index: int in range(PIP_COUNT):
		var x: float = left + index * (PIP_SIZE + PIP_GAP)
		var box := Rect2(x, -PIP_HEIGHT, PIP_SIZE, PIP_SIZE)
		_pips.draw_rect(box.grow(1.0), PIP_EDGE)
		_pips.draw_rect(box, PIP_ON if index < lit else PIP_OFF)


func _on_socket_interacted(actor: Node) -> void:
	if not _armed or state == State.POWERED:
		return
	_actor = actor as Node2D
