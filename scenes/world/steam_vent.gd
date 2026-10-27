class_name SteamVent
extends Node2D

enum Phase { IDLE, WARN, JET }

const NOZZLE_PATH: String = "res://assets/sprites/world/steam_vent.png"
const POWERED_GROUP: StringName = &"powered"
const HAZARD_GROUP: StringName = &"hazard"
const WARN_TINT: Color = Color("ffb36b")
const WARN_BLINK_HZ: float = 8.0

@export var terminal_id: StringName = &""
@export var system_id: StringName = &""
@export var powered: bool = true
@export var phase: float = 0.0

var _elapsed: float = 0.0
var _phase: Phase = Phase.IDLE

@onready var _nozzle: Sprite2D = $Nozzle
@onready var _jet: DamageArea = $Jet
@onready var _plume: CPUParticles2D = $Plume
@onready var _hiss: CPUParticles2D = $Hiss


func _ready() -> void:
	add_to_group(POWERED_GROUP)
	add_to_group(HAZARD_GROUP)
	_jet.contact_damage = Balance.STEAM_DAMAGE
	_jet.knockback = true
	_plume.material = HeatZone.unshaded_material()
	_hiss.material = HeatZone.unshaded_material()
	_apply_nozzle()
	set_powered_silent(powered)


func _physics_process(delta: float) -> void:
	if not powered:
		return
	_elapsed += delta
	_apply_phase(phase_at(_elapsed + phase))


static func phase_at(time: float) -> Phase:
	var period: float = Balance.STEAM_ON_TIME + Balance.STEAM_OFF_TIME
	if period <= 0.0:
		return Phase.IDLE
	var t: float = fposmod(time, period)
	if t < Balance.STEAM_ON_TIME:
		return Phase.JET
	if t >= period - Balance.STEAM_WARN_TIME:
		return Phase.WARN
	return Phase.IDLE


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	phase = float(params.get("phase", phase))
	if params.has("powered"):
		powered = bool(params["powered"])
	if _jet == null:
		return
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	set_powered_silent(on)


func set_powered_silent(on: bool) -> void:
	powered = on
	_elapsed = 0.0
	if _jet == null:
		return
	if not on:
		_apply_phase(Phase.IDLE)
		return
	_apply_phase(phase_at(phase))


func current_phase() -> Phase:
	return _phase


func is_jetting() -> bool:
	return _phase == Phase.JET


func _apply_phase(next: Phase) -> void:
	var changed: bool = next != _phase
	_phase = next
	_jet.set_active(next == Phase.JET)
	if changed or next == Phase.IDLE:
		_plume.emitting = next == Phase.JET
		_hiss.emitting = next == Phase.WARN
	if next == Phase.WARN:
		var blink: bool = fmod(_elapsed * WARN_BLINK_HZ, 1.0) < 0.5
		_nozzle.modulate = WARN_TINT if blink else Color.WHITE
	else:
		_nozzle.modulate = Color.WHITE


func _apply_nozzle() -> void:
	var texture: Texture2D = AssetResolver.texture(NOZZLE_PATH)
	if texture == null:
		push_warning("SteamVent: bocal ausente em %s" % NOZZLE_PATH)
		return
	_nozzle.texture = texture
