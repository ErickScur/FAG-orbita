class_name ArgosEncounter
extends Node2D

signal encounter_started()
signal phase_changed(phase: int)
signal encounter_failed()
signal encounter_reset()
signal defeated()

const ENCOUNTER_GROUP: StringName = &"argos_encounter"
const PLAYER_GROUP: StringName = &"player"
const COUPLER_GROUP: StringName = &"root_coupler"
const PLATFORM_GROUP: StringName = &"thermal_platform"
const NETWORK_GROUP: StringName = &"energy_network"
const META_KEY: String = "argos"
const DEFEATED_FLAG: String = "argos_defeated"
const SECTOR_ID: StringName = &"reactor"
const START_DIALOGUE: StringName = &"rc_argos"
const CORE_SHEET: String = "res://assets/sprites/bosses/argos_core_sheet.png"
const LIGHT_TEXTURE: String = "res://assets/fx/light_radial.png"
const CORE_FRAME: Vector2i = Vector2i(64, 64)
const SHEET_COLUMNS: int = 4
const SHEET_ROWS: int = 2
const PULSE_FRAMES: int = 4
const PULSE_FPS: float = 5.0
const CRACK_FRAMES: Array[int] = [0, 4, 5]
const DYING_FRAME: int = 6
const DEAD_FRAME: int = 7
const RING_RADII: Array[float] = [38.0, 45.0, 52.0]
const RING_SPEEDS: Array[float] = [0.7, -0.5, 0.35]
const RING_ARCS: int = 3
const RING_ARC_SPAN: float = 1.6
const RING_POINTS: int = 10
const RING_WIDTH: float = 2.0
const RING_COLOR: Color = Color("ff9a4a")
const RING_FALL: float = 24.0
const SEGMENT_RADIUS: float = 60.0
const SEGMENT_SPREAD_DEGREES: float = 200.0
const GAUGE_SPACING: float = 12.0
const DANGER_EDGE: Color = Color("ff2414")
const DANGER_EDGE_STRENGTH: float = 0.8
const DANGER_EDGE_REST: float = 0.35
const DANGER_EDGE_DECAY: float = 0.5
const CORE_LIGHT_RADIUS: float = 150.0
const CORE_LIGHT_ENERGY: float = 1.3
const CORE_LIGHT_COLOR: Color = Color("ff7a2a")
const CORE_PULSE_DEPTH: float = 0.25
const DANGER_TINT: Color = Color("4a0c06")
const DANGER_PULSE_HZ: float = 1.5
const EMBER_COLOR: Color = Color(1.0, 0.6, 0.25, 0.9)
const EMBER_AMOUNT: int = 24
const EMBER_SPREAD: float = 40.0
const SEGMENT_SHAKE: float = 1.0
const DEAD_TINT: Color = Color("2a2626")

var _logic: ArgosLogic = ArgosLogic.new()
var _configured: bool = false
var _terminal_id: StringName = &""
var _arena: Rect2 = Rect2()
var _core_position: Vector2 = Vector2.ZERO
var _heat_group: StringName = &""
var _tower_group: StringName = &""
var _floor_group: StringName = &""
var _alarm_group: StringName = &""
var _core: Sprite2D = null
var _core_light: PointLight2D = null
var _rings: Array[Node2D] = []
var _ring_lamps: ArgosTimerLamps = null
var _gauges: Array[ArgosTimerLamps] = []
var _gauge_points: Array[Vector2] = []
var _vignette: Vignette = null
var _danger_left: float = 0.0
var _embers: CPUParticles2D = null
var _ambient: CanvasModulate = null
var _ambient_base: Color = Color.BLACK
var _pulse_time: float = 0.0
var _alarm_left: float = 0.0
var _shown_segments: int = -1
var _pending_fail: bool = false
var _victory: bool = false
var _tween: Tween = null


func _ready() -> void:
	add_to_group(ENCOUNTER_GROUP)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	_configure.call_deferred()


func _physics_process(delta: float) -> void:
	if not _configured or _victory:
		return
	var timed_out: bool = _logic.tick(delta)
	if _logic.state == ArgosLogic.State.IDLE and _player_in_arena():
		_start()
	if timed_out:
		_pending_fail = true
	if _pending_fail:
		_try_fail()
	_update_alarm(delta)
	_update_visuals(delta)


func heat_clock() -> float:
	return _logic.heat_clock


func time_left() -> float:
	return _logic.time_left


func phase() -> int:
	return _logic.phase()


func overloaded_count() -> int:
	return _logic.overloaded_count()


func lit_segments() -> int:
	return _logic.lit_segments()


func is_active() -> bool:
	return _logic.is_active()


func is_defeated() -> bool:
	return _logic.is_defeated()


func is_configured() -> bool:
	return _configured


func state_name() -> String:
	return String(ArgosLogic.State.keys()[_logic.state]).to_lower()


func arena_rect() -> Rect2:
	return _arena


func core_position() -> Vector2:
	return _core_position


func timer_lamps() -> Array[ArgosTimerLamps]:
	var found: Array[ArgosTimerLamps] = []
	if _ring_lamps != null:
		found.append(_ring_lamps)
	found.append_array(_gauges)
	return found


func gauge_count() -> int:
	return _gauges.size()


func gauge_lit(index: int) -> int:
	if index < 0 or index >= _gauges.size():
		return -1
	return _gauges[index].lit_count()


func ring_lit() -> int:
	return _ring_lamps.lit_count() if _ring_lamps != null else -1


func is_urgent() -> bool:
	return _ring_lamps != null and _ring_lamps.is_urgent()


func danger_edge() -> float:
	return _danger_left


func couplers() -> Array[RootCoupler]:
	var found: Array[RootCoupler] = []
	for node: Node in _level_nodes(COUPLER_GROUP):
		if node is RootCoupler:
			found.append(node)
	return found


func coupler_fed(coupler_id: StringName) -> bool:
	var coupler: RootCoupler = _coupler(coupler_id)
	return coupler != null and coupler.powered


func coupler_overloaded(coupler_id: StringName) -> bool:
	var coupler: RootCoupler = _coupler(coupler_id)
	return coupler != null and coupler.is_overloaded()


func overload_coupler(coupler_id: StringName) -> bool:
	for coupler: RootCoupler in couplers():
		if coupler.coupler_id == coupler_id:
			coupler.force_overload()
			return coupler.is_overloaded()
	return false


func reset_encounter() -> void:
	if _victory:
		return
	_logic.reset()
	_pending_fail = false
	for coupler: RootCoupler in couplers():
		coupler.reset_overload()
	_reset_energy()
	_apply_phase()
	for index: int in range(_rings.size()):
		_rings[index].modulate.a = 1.0
		_rings[index].position = Vector2.ZERO
	if _ambient != null:
		_ambient.color = _ambient_base
	_shown_segments = -1
	_danger_left = 0.0
	_set_urgent(false)
	_restore_vignette()
	encounter_reset.emit()


func _coupler(coupler_id: StringName) -> RootCoupler:
	for coupler: RootCoupler in couplers():
		if coupler.coupler_id == coupler_id:
			return coupler
	return null


func _configure() -> void:
	var level: Node = get_parent()
	var data: Variant = null
	if level.has_method(&"meta_value"):
		data = level.call(&"meta_value", META_KEY)
	if not (data is Dictionary):
		push_warning("ArgosEncounter: fase sem bloco '%s'" % META_KEY)
		return
	var meta: Dictionary = data
	_terminal_id = StringName(String(meta.get("terminal", "")))
	_core_position = _vector(meta.get("core", []))
	_arena = _cells_rect(meta.get("arena", []))
	_heat_group = StringName(String(meta.get("heat_group", "")))
	_tower_group = StringName(String(meta.get("tower_group", "")))
	_floor_group = StringName(String(meta.get("floor_group", "")))
	_alarm_group = StringName(String(meta.get("alarm_group", "")))
	_ambient = level.get_node_or_null(^"CanvasModulate") as CanvasModulate
	if _ambient != null:
		_ambient_base = _ambient.color
	for child: Node in level.get_children():
		if child is Vignette:
			_vignette = child
	_gauge_points.clear()
	for value: Variant in meta.get("gauges", []) as Array:
		_gauge_points.append(_vector(value))
	_build_core()
	for coupler: RootCoupler in couplers():
		coupler.overloaded.connect(_on_coupler_overloaded)
	_configured = true
	AudioManager.stop_music()
	if bool(GameState.flags.get(DEFEATED_FLAG, false)):
		_logic.defeat()
		_victory = true
		_apply_dead_state()
		EventBus.argos_defeated.emit.call_deferred()
		return
	_apply_phase()


func _start() -> void:
	if not _logic.start():
		return
	_alarm_left = 0.0
	_shown_segments = -1
	AudioManager.play_sfx(&"reactor_alarm")
	DialogueManager.play(START_DIALOGUE)
	encounter_started.emit()


func _try_fail() -> void:
	var player: Node2D = _player()
	if player != null and player.has_method(&"is_input_locked"):
		if bool(player.call(&"is_input_locked")):
			return
	_pending_fail = false
	if GameState.is_dead():
		return
	_logic.fail()
	_flash_core()
	_shake(Balance.SHAKE_DAMAGE)
	AudioManager.play_sfx(&"damage")
	encounter_failed.emit()
	GameState.apply_damage(GameState.integrity_max * 2)


func _on_player_died() -> void:
	if not _configured or _victory:
		return
	_logic.fail()
	_pending_fail = false
	for coupler: RootCoupler in couplers():
		coupler.cancel_overload()


func _on_player_respawned() -> void:
	if not _configured:
		return
	reset_encounter()


func _on_coupler_overloaded(coupler_id: StringName) -> void:
	if not _logic.overload(coupler_id):
		return
	var broken: int = _logic.overloaded_count() - 1
	_shake(Balance.SHAKE_SECTOR)
	AudioManager.play_sfx(&"sr3_shutdown")
	_break_ring(broken)
	_flash_core()
	if _logic.is_defeated():
		_begin_victory()
		return
	_apply_phase()
	phase_changed.emit(_logic.phase())


func _apply_phase() -> void:
	var scale: float = _logic.speed_scale()
	for node: Node in _level_nodes(_tower_group):
		if node is Cx2Armored:
			(node as Cx2Armored).set_sweep_scale(scale)


func _begin_victory() -> void:
	_victory = true
	_logic.defeat()
	var player: Node2D = _player()
	if player != null:
		if player.has_method(&"set_input_locked"):
			player.call(&"set_input_locked", true)
		if player.has_method(&"set_invincible"):
			player.call(&"set_invincible", true)
	AudioManager.stop_all()
	AudioManager.play_sfx(&"power_off")
	_power_down_arena()
	_focus_core()
	_count_down_segments()
	_kill_tween()
	_set_urgent(false)
	_restore_vignette()
	_tween = create_tween()
	var step: float = Balance.ARGOS_SHUTDOWN_TIME / 3.0
	_tween.tween_callback(_set_core_frame.bind(CRACK_FRAMES[CRACK_FRAMES.size() - 1]))
	_tween.tween_interval(step)
	_tween.tween_callback(_set_core_frame.bind(DYING_FRAME))
	_tween.parallel().tween_property(_core_light, "energy", CORE_LIGHT_ENERGY * 0.3, step)
	_tween.tween_interval(step)
	_tween.tween_callback(_set_core_frame.bind(DEAD_FRAME))
	_tween.parallel().tween_property(_core_light, "energy", 0.0, step)
	if _ambient != null:
		_tween.parallel().tween_property(_ambient, "color", DEAD_TINT, step)
	_tween.tween_callback(_silence)
	_tween.tween_interval(Balance.ARGOS_SILENCE_TIME)
	_tween.tween_callback(_finish_victory)
	defeated.emit()


func _focus_core() -> void:
	var current: Camera2D = get_viewport().get_camera_2d()
	var camera := Camera2D.new()
	camera.name = "VictoryCamera"
	add_child(camera)
	var level: Node = get_parent()
	if level != null and level.has_method(&"camera_rect"):
		var bounds: Rect2i = level.call(&"camera_rect")
		camera.limit_left = bounds.position.x
		camera.limit_top = bounds.position.y
		camera.limit_right = bounds.position.x + bounds.size.x
		camera.limit_bottom = bounds.position.y + bounds.size.y
	camera.global_position = (
		current.get_screen_center_position() if current != null else _core_position
	)
	camera.make_current()
	var pan: Tween = camera.create_tween()
	pan.tween_property(camera, "global_position", _core_position, Balance.CUTSCENE_RETURN_TIME)


func _count_down_segments() -> void:
	var count: int = maxi(1, Balance.ARGOS_SEGMENTS)
	var countdown: Tween = create_tween()
	var step: float = Balance.ARGOS_SHUTDOWN_TIME / float(count)
	for lit: int in range(count - 1, -1, -1):
		countdown.tween_interval(step)
		countdown.tween_callback(_set_lamps.bind(lit, true))


func _silence() -> void:
	AudioManager.stop_all()
	if _embers != null:
		_embers.emitting = false
	_set_lamps(0, false)


func _finish_victory() -> void:
	GameState.flags[DEFEATED_FLAG] = true
	if not GameState.sectors_restored.has(SECTOR_ID):
		GameState.sectors_restored.append(SECTOR_ID)
	SaveManager.save_game()
	EventBus.argos_defeated.emit()


func _apply_dead_state() -> void:
	_power_down_arena()
	_set_core_frame(DEAD_FRAME)
	if _core_light != null:
		_core_light.energy = 0.0
	if _embers != null:
		_embers.emitting = false
	for ring: Node2D in _rings:
		ring.modulate.a = 0.0
	_set_lamps(0, false)
	if _ambient != null:
		_ambient.color = DEAD_TINT


func _power_down_arena() -> void:
	for group: StringName in [_tower_group, _floor_group, _alarm_group]:
		for node: Node in _level_nodes(group):
			if node.has_method(&"set_powered"):
				node.call(&"set_powered", false)
	for node: Node in _level_nodes(_heat_group):
		if node is HeatZone:
			_cool_zone(node as HeatZone)
	for node: Node in _level_nodes(PLATFORM_GROUP):
		if node is ThermalPlatform:
			(node as ThermalPlatform).freeze()
	for index: int in range(_rings.size()):
		_break_ring(index)


func _cool_zone(zone: HeatZone) -> void:
	zone.set_deferred(&"monitorable", false)
	var glow: PointLight2D = zone.get_node_or_null(^"Glow") as PointLight2D
	if glow != null:
		glow.enabled = false
	var shimmer: CPUParticles2D = zone.get_node_or_null(^"Shimmer") as CPUParticles2D
	if shimmer != null:
		shimmer.emitting = false


func _reset_energy() -> void:
	var found: Node = get_tree().get_first_node_in_group(NETWORK_GROUP)
	var network: EnergyNetwork = found as EnergyNetwork
	if network == null:
		return
	var grid: EnergyGrid = network.grid(_terminal_id)
	if grid == null:
		return
	if grid.is_overloaded():
		network.end_overload(_terminal_id)
	grid.reset_to_initial()
	GameState.energy_states[_terminal_id] = grid.get_state()
	network.apply_all(_terminal_id, true)


func _update_alarm(delta: float) -> void:
	if not _logic.is_active():
		return
	_alarm_left -= delta
	if _alarm_left > 0.0:
		return
	_alarm_left = ArgosLogic.alarm_interval(_logic.time_left)
	AudioManager.play_sfx(&"reactor_alarm")
	if ArgosLogic.is_urgent(_logic.time_left):
		_danger_left = DANGER_EDGE_DECAY


func _update_visuals(delta: float) -> void:
	if _core == null:
		return
	_pulse_time += delta * _logic.speed_scale()
	var phase_index: int = _logic.overloaded_count()
	if phase_index == 0:
		_set_core_frame(int(_pulse_time * PULSE_FPS) % PULSE_FRAMES)
	else:
		_set_core_frame(CRACK_FRAMES[mini(phase_index, CRACK_FRAMES.size() - 1)])
	_core_light.energy = LightMath.pulse(
		CORE_LIGHT_ENERGY, _pulse_time, PULSE_FPS * 0.25, CORE_PULSE_DEPTH
	)
	for index: int in range(_rings.size()):
		_rings[index].rotation += RING_SPEEDS[index] * delta * _logic.speed_scale()
	var lit: int = _logic.lit_segments()
	if lit != _shown_segments:
		if _shown_segments > lit and _logic.is_active():
			AudioManager.play_sfx(&"power_off")
			_shake(SEGMENT_SHAKE)
		_shown_segments = lit
		_set_lamps(lit, _logic.is_active())
	_set_urgent(_logic.is_active() and ArgosLogic.is_urgent(_logic.time_left))
	_update_danger_edge(delta)
	_update_ambient()


func _set_lamps(lit: int, animated: bool) -> void:
	for lamps: ArgosTimerLamps in timer_lamps():
		lamps.set_lit(lit, animated)


func _set_urgent(urgent: bool) -> void:
	for lamps: ArgosTimerLamps in timer_lamps():
		lamps.set_urgent(urgent)


func _update_danger_edge(delta: float) -> void:
	if _vignette == null:
		return
	if not _logic.is_active() or not ArgosLogic.is_urgent(_logic.time_left):
		if _danger_left > 0.0:
			_danger_left = 0.0
			_restore_vignette()
		return
	_danger_left = maxf(0.0, _danger_left - delta)
	var beat: float = _danger_left / DANGER_EDGE_DECAY
	var strength: float = lerpf(DANGER_EDGE_REST, DANGER_EDGE_STRENGTH, beat)
	_vignette.apply(DANGER_EDGE, strength)


func _restore_vignette() -> void:
	if _vignette != null:
		_vignette.apply(Balance.VIGNETTE_COLOR, Balance.VIGNETTE_STRENGTH)


func _update_ambient() -> void:
	if _ambient == null:
		return
	if not _logic.is_active() or _logic.time_left > Balance.ARGOS_ALARM_FAST_TIME:
		_ambient.color = _ambient_base
		return
	var urgency: float = 1.0 - _logic.time_left / Balance.ARGOS_ALARM_FAST_TIME
	var wave: float = 0.5 + 0.5 * sin(_pulse_time * TAU * DANGER_PULSE_HZ)
	_ambient.color = _ambient_base.lerp(DANGER_TINT, clampf(urgency * wave, 0.0, 1.0))


func _build_core() -> void:
	position = Vector2.ZERO
	var holder := Node2D.new()
	holder.name = "Core"
	holder.position = _core_position
	add_child(holder)
	_core_light = PointLight2D.new()
	_core_light.name = "CoreLight"
	_core_light.texture = AssetResolver.texture(LIGHT_TEXTURE)
	_core_light.color = CORE_LIGHT_COLOR
	_core_light.energy = CORE_LIGHT_ENERGY
	_core_light.blend_mode = Light2D.BLEND_MODE_ADD
	_core_light.shadow_enabled = false
	_core_light.texture_scale = LightMath.scale_for_radius(
		CORE_LIGHT_RADIUS, LightMath.TEXTURE_SIZE
	)
	holder.add_child(_core_light)
	for index: int in range(RING_RADII.size()):
		var ring: Node2D = _make_ring(RING_RADII[index], index)
		holder.add_child(ring)
		_rings.append(ring)
	_core = Sprite2D.new()
	_core.name = "CoreSprite"
	_core.texture = AssetResolver.texture(CORE_SHEET)
	_core.hframes = SHEET_COLUMNS
	_core.vframes = SHEET_ROWS
	holder.add_child(_core)
	var count: int = maxi(1, Balance.ARGOS_SEGMENTS)
	_ring_lamps = ArgosTimerLamps.new()
	_ring_lamps.name = "TimerRing"
	holder.add_child(_ring_lamps)
	_ring_lamps.configure(
		ArgosTimerLamps.horseshoe(count, SEGMENT_RADIUS, deg_to_rad(SEGMENT_SPREAD_DEGREES)), false
	)
	for index: int in range(_gauge_points.size()):
		var gauge := ArgosTimerLamps.new()
		gauge.name = "TimerGauge%d" % (index + 1)
		gauge.position = _gauge_points[index]
		add_child(gauge)
		gauge.configure(ArgosTimerLamps.row(count, GAUGE_SPACING), true)
		_gauges.append(gauge)
	_embers = CPUParticles2D.new()
	_embers.name = "Embers"
	_embers.amount = EMBER_AMOUNT
	_embers.lifetime = 2.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_embers.emission_sphere_radius = EMBER_SPREAD
	_embers.direction = Vector2.UP
	_embers.spread = 30.0
	_embers.gravity = Vector2(0.0, -20.0)
	_embers.initial_velocity_min = 4.0
	_embers.initial_velocity_max = 14.0
	_embers.color = EMBER_COLOR
	_embers.material = HeatZone.unshaded_material()
	holder.add_child(_embers)


func _make_ring(radius: float, index: int) -> Node2D:
	var ring := Node2D.new()
	ring.name = "Ring%d" % (index + 1)
	ring.rotation = float(index) * 0.7
	var gap: float = TAU / float(RING_ARCS)
	for arc: int in range(RING_ARCS):
		var line := Line2D.new()
		line.width = RING_WIDTH
		line.default_color = RING_COLOR
		line.antialiased = false
		line.material = HeatZone.unshaded_material()
		var start: float = gap * float(arc)
		var points := PackedVector2Array()
		for step: int in range(RING_POINTS + 1):
			var angle: float = start + RING_ARC_SPAN * float(step) / float(RING_POINTS)
			points.append(Vector2.RIGHT.rotated(angle) * radius)
		line.points = points
		ring.add_child(line)
	return ring


func _break_ring(index: int) -> void:
	if index < 0 or index >= _rings.size():
		return
	var ring: Node2D = _rings[index]
	if ring.modulate.a <= 0.0:
		return
	var fall: Tween = ring.create_tween()
	fall.tween_property(ring, "position", Vector2(0.0, RING_FALL), Balance.SECTOR_SETTLE_TIME)
	fall.parallel().tween_property(ring, "modulate:a", 0.0, Balance.SECTOR_SETTLE_TIME)


func _set_core_frame(frame: int) -> void:
	if _core == null:
		return
	_core.frame = clampi(frame, 0, SHEET_COLUMNS * SHEET_ROWS - 1)


func _flash_core() -> void:
	if _core == null:
		return
	_core.modulate = Balance.SECTOR_FLASH_COLOR * 1.6
	var flash: Tween = _core.create_tween()
	flash.tween_property(_core, "modulate", Color.WHITE, Balance.SECTOR_SETTLE_TIME)


func _shake(amplitude: float) -> void:
	var player: Node2D = _player()
	if player != null and player.has_method(&"shake"):
		player.call(&"shake", amplitude)


func _player() -> Node2D:
	if not is_inside_tree():
		return null
	return get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D


func _player_in_arena() -> bool:
	var player: Node2D = _player()
	if player == null or GameState.is_dead():
		return false
	return _arena.has_point(player.global_position)


func _level_nodes(group: StringName) -> Array[Node]:
	var found: Array[Node] = []
	if group == &"" or not is_inside_tree():
		return found
	var level: Node = get_parent()
	for node: Node in get_tree().get_nodes_in_group(group):
		if level != null and level.is_ancestor_of(node):
			found.append(node)
	return found


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null


static func _vector(value: Variant) -> Vector2:
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float((value as Array)[0]), float((value as Array)[1]))
	return Vector2.ZERO


static func _cells_rect(value: Variant) -> Rect2:
	if not (value is Array) or (value as Array).size() < 4:
		return Rect2()
	var cells: Array = value
	var tile: float = float(Balance.TILE_SIZE)
	return Rect2(
		float(cells[0]) * tile, float(cells[1]) * tile,
		float(cells[2]) * tile, float(cells[3]) * tile
	)
