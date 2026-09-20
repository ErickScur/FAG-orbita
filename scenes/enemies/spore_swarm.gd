class_name SporeSwarm
extends DamageArea

const PARTICLE_PATH: String = "res://assets/sprites/fx/spore.png"
const PARTICLE_FRAME: Vector2i = Vector2i(8, 8)
const SFX_PATH: String = "res://assets/audio/sfx/spores.wav"
const PARTICLE_AMOUNT: int = 24
const PARTICLE_LIFETIME: float = 2.0
const PARTICLE_GRAVITY: Vector2 = Vector2(0.0, -4.0)
const PARTICLE_VELOCITY: float = 6.0
const PARTICLE_SCALE: float = 1.0
const HAZARD_LAYER: int = 16
const PLAYER_MASK: int = 2
const PLAYER_GROUP: StringName = &"player"
const POWERED_GROUP: StringName = &"powered"

@export var terminal_id: StringName = &"greenhouse"
@export var system_id: StringName = &"heating"
@export var powered: bool = true

var _tween: Tween = null

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _particles: CPUParticles2D = $Particles
@onready var _loop: AudioStreamPlayer2D = $Loop


func _ready() -> void:
	super()
	add_to_group(POWERED_GROUP)
	collision_layer = HAZARD_LAYER
	collision_mask = PLAYER_MASK
	monitoring = true
	monitorable = true
	damage_per_second = Balance.SPORE_DPS
	knockback = false
	status_id = StatusEffects.CORROSION
	status_duration = Balance.CORROSION_TIME
	_setup_particles()
	_setup_loop()
	set_powered_silent(powered)
	EventBus.energy_changed.connect(_on_energy_changed)


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for body: Node2D in get_overlapping_bodies():
		if not body.is_in_group(PLAYER_GROUP):
			continue
		if _is_dashing(body):
			continue
		GameState.apply_status(StatusEffects.CORROSION)


func configure(params: Dictionary) -> void:
	terminal_id = StringName(String(params.get("terminal_id", terminal_id)))
	system_id = StringName(String(params.get("system_id", system_id)))
	if params.has("powered"):
		powered = bool(params["powered"])
	if _shape == null:
		return
	set_powered_silent(powered)


func set_powered(on: bool) -> void:
	if powered == on:
		return
	powered = on
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(
		_set_radius, current_radius(), target_radius(), Balance.SPORE_EXPAND_TIME
	)


func set_powered_silent(on: bool) -> void:
	powered = on
	_kill_tween()
	_set_radius(target_radius())


func target_radius() -> float:
	return Balance.SPORE_RADIUS_HEATED if powered else Balance.SPORE_RADIUS


func current_radius() -> float:
	var circle: Shape2D = _shape.shape
	if circle is CircleShape2D:
		return (circle as CircleShape2D).radius
	return Balance.SPORE_RADIUS


func is_heated() -> bool:
	return powered


func _set_radius(value: float) -> void:
	var circle: Shape2D = _shape.shape
	if circle is CircleShape2D:
		(circle as CircleShape2D).radius = value
	_particles.emission_sphere_radius = value


func _is_dashing(body: Node2D) -> bool:
	if not body.has_method(&"is_dashing"):
		return false
	return bool(body.call(&"is_dashing"))


func _setup_particles() -> void:
	_particles.texture = AssetResolver.atlas(PARTICLE_PATH, PARTICLE_FRAME, 0, 0)
	if _particles.texture == null:
		push_warning("SporeSwarm: partícula ausente em %s" % PARTICLE_PATH)
	_particles.amount = PARTICLE_AMOUNT
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_particles.lifetime = PARTICLE_LIFETIME
	_particles.gravity = PARTICLE_GRAVITY
	_particles.initial_velocity_min = 0.0
	_particles.initial_velocity_max = PARTICLE_VELOCITY
	_particles.scale_amount_min = PARTICLE_SCALE
	_particles.scale_amount_max = PARTICLE_SCALE
	_particles.emitting = true


func _setup_loop() -> void:
	var stream: AudioStream = AssetResolver.audio(SFX_PATH)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = (stream as AudioStreamWAV).duplicate()
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream = wav
	_loop.stream = stream
	_loop.play()


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


func _on_energy_changed(
	changed_terminal: StringName, changed_system: StringName, on: bool
) -> void:
	if changed_terminal != terminal_id or changed_system != system_id:
		return
	set_powered(on)
