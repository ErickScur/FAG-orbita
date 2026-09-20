extends Node

const SAVE_VERSION: int = 1
const LEVELS_PREFIX: String = "res://scenes/levels/"
const LEVEL_GROUP: StringName = &"level"

var reactor_percent: float = Balance.REACTOR_START
var integrity: int = Balance.INTEGRITY_MAX
var integrity_max: int = Balance.INTEGRITY_MAX
var charge: float = Balance.CHARGE_MAX
var charge_max: float = Balance.CHARGE_MAX
var logs_collected: Array[StringName] = []
var research_collected: Array[StringName] = []
var collected_ids: Array[StringName] = []
var abilities: Array[StringName] = []
var sectors_restored: Array[StringName] = []
var energy_states: Dictionary = {}
var checkpoint: Dictionary = {}
var deaths: int = 0
var play_time: float = 0.0
var flags: Dictionary = {}
var current_objective: String = ""

var _paused: bool = false
var _dialogue_active: bool = false
var _log_open: bool = false
var _died_emitted: bool = false
var _critical: bool = false
var _alarm_left: float = 0.0
var _game_over_sent: bool = false
var _last_display: int = -1
var _objectives: Dictionary = {}


func _ready() -> void:
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.dialogue_started.connect(_on_dialogue_started)
	EventBus.dialogue_finished.connect(_on_dialogue_finished)
	EventBus.log_opened.connect(_on_log_opened)
	EventBus.log_closed.connect(_on_log_closed)
	EventBus.sector_restored.connect(_on_sector_restored)
	EventBus.collectible_picked.connect(_on_collectible_picked)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_respawned.connect(_on_player_respawned)
	new_game()


func _process(delta: float) -> void:
	if not is_in_level():
		return
	play_time += delta
	_tick_reactor(delta)


func new_game() -> void:
	reactor_percent = Balance.REACTOR_START
	integrity = Balance.INTEGRITY_MAX
	integrity_max = Balance.INTEGRITY_MAX
	charge = Balance.CHARGE_MAX
	charge_max = Balance.CHARGE_MAX
	logs_collected = []
	research_collected = []
	collected_ids = []
	abilities = []
	sectors_restored = []
	energy_states = {}
	checkpoint = {}
	deaths = 0
	play_time = 0.0
	flags = {}
	current_objective = ""
	_died_emitted = false
	_reset_reactor_runtime()
	EventBus.integrity_changed.emit(integrity, integrity_max)
	EventBus.charge_changed.emit(charge, charge_max)
	EventBus.reactor_changed.emit(reactor_percent)
	EventBus.reactor_critical.emit(_critical)


func is_timer_frozen() -> bool:
	if _paused or _dialogue_active or _log_open or Settings.no_timer:
		return true
	return _dialogue_blocks_timer()


func is_reactor_online() -> bool:
	return bool(flags.get("reactor_online", false))


func set_reactor_online(online: bool) -> void:
	if is_reactor_online() == online:
		return
	flags["reactor_online"] = online
	_alarm_left = 0.0
	EventBus.reactor_changed.emit(reactor_percent)


func is_in_level() -> bool:
	var tree: SceneTree = get_tree()
	if tree == null:
		return false
	var scene: Node = tree.current_scene
	if scene == null:
		return false
	if scene.is_in_group(LEVEL_GROUP):
		return true
	return scene.scene_file_path.begins_with(LEVELS_PREFIX)


func is_reactor_running() -> bool:
	return is_reactor_online() and is_in_level() and not is_timer_frozen()


func is_dead() -> bool:
	return integrity <= 0


func apply_damage(amount: int) -> void:
	var scaled: int = Vitals.scale_damage(amount, Settings.damage_multiplier())
	if scaled <= 0 or integrity <= 0:
		return
	integrity = clampi(integrity - scaled, 0, integrity_max)
	EventBus.player_damaged.emit(scaled)
	EventBus.integrity_changed.emit(integrity, integrity_max)
	if integrity == 0 and not _died_emitted:
		_died_emitted = true
		deaths += 1
		EventBus.player_died.emit()


func revive() -> void:
	integrity = Vitals.respawn_integrity(integrity_max, Balance.RESPAWN_INTEGRITY_RATIO)
	charge = Vitals.respawn_charge(charge_max, Balance.RESPAWN_CHARGE_RATIO)
	_died_emitted = false
	EventBus.integrity_changed.emit(integrity, integrity_max)
	EventBus.charge_changed.emit(charge, charge_max)


func repair(amount: int) -> void:
	if amount <= 0 or integrity >= integrity_max:
		return
	integrity = clampi(integrity + amount, 0, integrity_max)
	if integrity > 0:
		_died_emitted = false
	EventBus.integrity_changed.emit(integrity, integrity_max)


func add_charge(value: float) -> void:
	if value <= 0.0:
		return
	charge = clampf(charge + value, 0.0, charge_max)
	EventBus.charge_changed.emit(charge, charge_max)


func spend_charge(value: float) -> bool:
	if value <= 0.0:
		return true
	if charge < value:
		return false
	charge = clampf(charge - value, 0.0, charge_max)
	EventBus.charge_changed.emit(charge, charge_max)
	return true


func change_reactor(amount: float) -> void:
	reactor_percent = ReactorClock.apply_delta(reactor_percent, amount, Balance.REACTOR_START)
	_after_reactor_change(true)


func reactor_multiplier() -> float:
	return Settings.reactor_decay_multiplier()


func set_objective(id: StringName) -> void:
	var text: String = Objectives.text_for(id, _objective_table())
	if text.is_empty():
		push_warning("GameState: objetivo desconhecido '%s'" % id)
		return
	if text == current_objective:
		return
	current_objective = text
	EventBus.objective_changed.emit(text)


func clear_objective() -> void:
	if current_objective.is_empty():
		return
	current_objective = ""
	EventBus.objective_changed.emit(current_objective)


func is_reactor_critical() -> bool:
	return _critical


func register_pickup(kind: StringName, item_id: StringName) -> bool:
	if collected_ids.has(item_id):
		return false
	collected_ids.append(item_id)
	if kind == &"log" and not logs_collected.has(item_id):
		logs_collected.append(item_id)
	elif kind == &"research" and not research_collected.has(item_id):
		research_collected.append(item_id)
	EventBus.collectible_picked.emit(kind, item_id)
	return true


func to_dict() -> Dictionary:
	var energy: Dictionary = {}
	for terminal_id: Variant in energy_states:
		var systems: Array = []
		for system_id: Variant in energy_states[terminal_id]:
			systems.append(String(system_id))
		energy[String(terminal_id)] = systems
	return {
		"version": SAVE_VERSION,
		"reactor_percent": reactor_percent,
		"integrity": integrity,
		"integrity_max": integrity_max,
		"charge": charge,
		"charge_max": charge_max,
		"logs_collected": _names_to_strings(logs_collected),
		"research_collected": _names_to_strings(research_collected),
		"collected_ids": _names_to_strings(collected_ids),
		"abilities": _names_to_strings(abilities),
		"sectors_restored": _names_to_strings(sectors_restored),
		"energy_states": energy,
		"checkpoint": checkpoint.duplicate(true),
		"deaths": deaths,
		"play_time": play_time,
		"flags": flags.duplicate(true),
		"current_objective": current_objective,
	}


func from_dict(data: Dictionary) -> void:
	reactor_percent = float(data.get("reactor_percent", Balance.REACTOR_START))
	integrity = int(data.get("integrity", Balance.INTEGRITY_MAX))
	integrity_max = int(data.get("integrity_max", Balance.INTEGRITY_MAX))
	charge = float(data.get("charge", Balance.CHARGE_MAX))
	charge_max = float(data.get("charge_max", Balance.CHARGE_MAX))
	logs_collected = _strings_to_names(data.get("logs_collected", []))
	research_collected = _strings_to_names(data.get("research_collected", []))
	collected_ids = _strings_to_names(data.get("collected_ids", []))
	abilities = _strings_to_names(data.get("abilities", []))
	sectors_restored = _strings_to_names(data.get("sectors_restored", []))
	energy_states = {}
	var energy: Dictionary = data.get("energy_states", {})
	for terminal_id: Variant in energy:
		energy_states[StringName(terminal_id)] = _strings_to_names(energy[terminal_id])
	checkpoint = Dictionary(data.get("checkpoint", {})).duplicate(true)
	deaths = int(data.get("deaths", 0))
	play_time = float(data.get("play_time", 0.0))
	flags = Dictionary(data.get("flags", {})).duplicate(true)
	current_objective = String(data.get("current_objective", ""))
	_died_emitted = integrity <= 0
	_reset_reactor_runtime()
	_game_over_sent = reactor_percent <= 0.0
	EventBus.integrity_changed.emit(integrity, integrity_max)
	EventBus.charge_changed.emit(charge, charge_max)
	EventBus.reactor_changed.emit(reactor_percent)
	EventBus.reactor_critical.emit(_critical)
	EventBus.objective_changed.emit(current_objective)


func _names_to_strings(values: Array) -> Array:
	var result: Array = []
	for value: Variant in values:
		result.append(String(value))
	return result


func _strings_to_names(values: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if values is Array:
		for value: Variant in values:
			result.append(StringName(value))
	return result


func _objective_table() -> Dictionary:
	if _objectives.is_empty():
		_objectives = Objectives.load_all()
	return _objectives


func _dialogue_blocks_timer() -> bool:
	if not is_instance_valid(DialogueManager):
		return false
	if DialogueManager.has_method("freezes_timer"):
		return bool(DialogueManager.call("freezes_timer"))
	if DialogueManager.has_method("is_active"):
		return bool(DialogueManager.call("is_active"))
	return false


func _reset_reactor_runtime() -> void:
	_critical = ReactorClock.is_critical(reactor_percent, Balance.REACTOR_CRITICAL)
	_alarm_left = 0.0
	_game_over_sent = false
	_last_display = ReactorClock.display_percent(reactor_percent)


func _tick_reactor(delta: float) -> void:
	if not is_reactor_running():
		return
	reactor_percent = ReactorClock.step(
		reactor_percent, delta, Balance.REACTOR_DECAY_INTERVAL, reactor_multiplier()
	)
	_update_alarm(delta)
	_after_reactor_change(false)


func _update_alarm(delta: float) -> void:
	if not _critical:
		_alarm_left = 0.0
		return
	_alarm_left -= delta
	if _alarm_left > 0.0:
		return
	_alarm_left = Balance.REACTOR_ALARM_INTERVAL
	AudioManager.play_sfx(&"reactor_alarm")


func _after_reactor_change(force: bool) -> void:
	var display: int = ReactorClock.display_percent(reactor_percent)
	if force or display != _last_display:
		_last_display = display
		EventBus.reactor_changed.emit(reactor_percent)
	var critical: bool = ReactorClock.is_critical(reactor_percent, Balance.REACTOR_CRITICAL)
	if critical != _critical:
		_critical = critical
		_alarm_left = 0.0
		EventBus.reactor_critical.emit(critical)
	if reactor_percent > 0.0 or _game_over_sent:
		return
	_game_over_sent = true
	EventBus.game_over.emit(&"reactor")


func _on_sector_restored(_sector_id: StringName) -> void:
	change_reactor(Balance.REACTOR_SECTOR_BONUS)


func _on_collectible_picked(kind: StringName, _item_id: StringName) -> void:
	if kind != &"log":
		return
	change_reactor(Balance.REACTOR_LOG_BONUS)


func _on_player_died() -> void:
	change_reactor(-Balance.REACTOR_DEATH_PENALTY)


func _on_player_respawned() -> void:
	revive()


func _on_game_paused(paused: bool) -> void:
	_paused = paused


func _on_dialogue_started() -> void:
	_dialogue_active = true


func _on_dialogue_finished() -> void:
	_dialogue_active = false


func _on_log_opened(_log_id: StringName) -> void:
	_log_open = true


func _on_log_closed(_log_id: StringName) -> void:
	_log_open = false
