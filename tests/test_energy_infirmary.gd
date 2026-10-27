extends TestCase

const ENERGY_PATH: String = "res://data/energy/infirmary.json"
const ZONE_WARD: int = 0
const ZONE_UP: int = 1
const ZONE_QUARANTINE: int = 2
const ZONE_PROTOCOL: int = 3
const ZONE_CRYO: int = 4
const ZONE_NODE: int = 5
const ZONE_NAMES: Array[String] = [
	"Ala", "patamar", "quarentena", "protocolo", "câmara criogênica", "Nó"
]
const CONSOLE_ZONES: Array[int] = [ZONE_WARD, ZONE_UP]
const CORE: String = "core"
const NO_CORE: String = "cold"

var _grid: EnergyGrid = null


func before_each() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	_grid = EnergyGrid.from_dict(raw) if raw is Dictionary else null


func test_terminal_is_six_systems_two_units_and_mute() -> void:
	assert_not_null(_grid, "terminal infirmary carregou")
	if _grid == null:
		return
	assert_true(_grid.validate().is_empty(), "terminal válido: %s" % ", ".join(_grid.validate()))
	assert_eq(_grid.budget, 2, "duas unidades")
	assert_eq(_grid.system_ids().size(), 6, "seis sistemas")
	assert_eq(
		_names(_grid.initial_state()), _names([&"sentinels", &"heating"]), "estado inicial"
	)
	assert_eq(_names(_grid.goal_systems()), _names([&"node_door"]), "a meta é a porta do Nó")
	assert_false(_grid.goal_met(), "o puzzle não começa resolvido")
	assert_false(_grid.verbose, "fora do tutorial o terminal não explica")


func test_the_stretcher_lift_needs_the_heating_line() -> void:
	if _grid == null:
		return
	assert_eq(_names(_grid.requires_of(&"stretcher_lift")), _names([&"heating"]), "dependência")
	_grid.set_state([])
	assert_eq(
		_grid.can_power(&"stretcher_lift"), EnergyGrid.Result.MISSING_DEPENDENCY, "sem calor"
	)
	_grid.power_on(&"heating")
	assert_eq(_grid.can_power(&"stretcher_lift"), EnergyGrid.Result.OK, "com aquecimento")
	_grid.power_on(&"stretcher_lift")
	assert_eq(_grid.power_off(&"heating").size(), 2, "cortar o calor para o elevador")


func test_the_paper_sequence_solves_the_puzzle() -> void:
	if _grid == null:
		return
	_grid.reset_to_initial()
	_grid.power_off(&"sentinels")
	assert_eq(_grid.toggle(&"stretcher_lift")["result"], EnergyGrid.Result.OK, "B: elevador")
	assert_eq(_state(), _names([&"heating", &"stretcher_lift"]), "sobe pelo poço")
	_grid.power_off(&"stretcher_lift")
	assert_eq(_grid.toggle(&"quarantine_door")["result"], EnergyGrid.Result.OK, "C: quarentena")
	assert_eq(_state(), _names([&"heating", &"quarantine_door"]), "quarentena com calor")
	assert_false(_grid.goal_met(), "a porta do Nó continua fechada")
	_grid.power_off(&"heating")
	assert_eq(_grid.toggle(&"node_door")["result"], EnergyGrid.Result.OK, "C: abre o Nó")
	assert_eq(_state(), _names([&"node_door", &"quarantine_door"]), "rota final")
	assert_true(_grid.goal_met(), "meta cumprida")


func test_heating_and_both_doors_never_fit() -> void:
	if _grid == null:
		return
	_grid.set_state([&"heating", &"quarantine_door"])
	assert_eq(
		_grid.can_power(&"node_door"), EnergyGrid.Result.NO_BUDGET, "três não cabem em dois"
	)
	_grid.set_state([&"heating", &"node_door"])
	assert_eq(_grid.can_power(&"quarantine_door"), EnergyGrid.Result.NO_BUDGET, "nem ao contrário")
	_grid.set_state([&"heating", &"quarantine_door", &"node_door"])
	assert_true(_grid.used() <= _grid.budget, "o terminal recusa o estado impossível")


func test_the_pharmacy_costs_both_units() -> void:
	if _grid == null:
		return
	_grid.set_state([&"heating", &"stretcher_lift"])
	assert_eq(_grid.can_power(&"pharmacy_door"), EnergyGrid.Result.NO_BUDGET, "troca o elevador")
	_grid.set_state([&"heating"])
	assert_eq(_grid.can_power(&"pharmacy_door"), EnergyGrid.Result.OK, "calor e farmácia cabem")


func test_the_naive_meta_first_choice_cannot_climb() -> void:
	if _grid == null:
		return
	_grid.set_state([&"heating", &"node_door"])
	assert_eq(
		_grid.can_power(&"stretcher_lift"), EnergyGrid.Result.NO_BUDGET, "com a meta não sobe"
	)
	for start: Array in [[&"sentinels", &"node_door"], [&"node_door", &"pharmacy_door"]]:
		_grid.set_state(start)
		assert_ne(
			_grid.can_power(&"stretcher_lift"), EnergyGrid.Result.OK, "elevador com %s" % str(start)
		)


func test_cutting_the_heating_before_the_core_keeps_the_protocol_frozen() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_WARD, false, _grid.initial_state()))
	for key: Variant in reachable:
		var parts: PackedStringArray = String(key).split("|")
		if int(parts[0]) != ZONE_PROTOCOL or parts[1] == CORE:
			continue
		assert_true(parts[2].split("/", false).has("heating"), "chegou ao protocolo sem calor")


func test_every_way_to_the_node_runs_without_heating() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_WARD, false, _grid.initial_state()))
	var arrivals: int = 0
	for key: Variant in reachable:
		var parts: PackedStringArray = String(key).split("|")
		if int(parts[0]) != ZONE_NODE:
			continue
		arrivals += 1
		var systems: PackedStringArray = parts[2].split("/", false)
		assert_eq(parts[1], CORE, "chegou ao Nó sem o Núcleo Aquecido")
		assert_false(systems.has("heating"), "chegou ao Nó com aquecimento: %s" % parts[2])
		assert_true(systems.has("quarantine_door") and systems.has("node_door"), "as duas portas")
	assert_true(arrivals > 0, "o Nó é alcançável")


func test_no_energy_state_can_strand_the_player() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_WARD, false, _grid.initial_state()))
	assert_true(reachable.size() > 6, "a busca visitou o mapa")
	for key: Variant in reachable:
		assert_true(_can_finish(String(key)), "o estado '%s' ainda fecha a fase" % _label(key))


func test_at_least_six_forced_toggles() -> void:
	if _grid == null:
		return
	var start: String = _key(ZONE_WARD, false, _grid.initial_state())
	var distance: Dictionary = {start: 0}
	var queue: PackedStringArray = [start]
	var best: int = -1
	while not queue.is_empty():
		var current: String = queue[0]
		queue.remove_at(0)
		if int(current.split("|")[0]) == ZONE_NODE:
			best = int(distance[current]) if best < 0 else mini(best, int(distance[current]))
			continue
		for next: String in _neighbours(current):
			var cost: int = 0 if next.split("|")[2] == current.split("|")[2] else 1
			var total: int = int(distance[current]) + cost
			if distance.has(next) and int(distance[next]) <= total:
				continue
			distance[next] = total
			if cost == 0:
				queue.insert(0, next)
			else:
				queue.append(next)
	assert_true(best >= 6, "o caminho mais curto pede %d trocas no terminal" % best)


func _zone_moves(zone: int) -> Array:
	match zone:
		ZONE_WARD:
			return [{"to": ZONE_UP, "needs": [&"stretcher_lift"]}]
		ZONE_UP:
			return [
				{"to": ZONE_WARD, "needs": [&"stretcher_lift"]},
				{"to": ZONE_QUARANTINE, "needs": [&"quarantine_door"]},
			]
		ZONE_QUARANTINE:
			return [
				{"to": ZONE_UP, "needs": [&"quarantine_door"]},
				{"to": ZONE_PROTOCOL, "needs": [], "warm": true},
			]
		ZONE_PROTOCOL:
			return [
				{"to": ZONE_QUARANTINE, "needs": [], "warm": true},
				{"to": ZONE_CRYO, "needs": [], "core": true},
			]
		ZONE_CRYO:
			return [
				{"to": ZONE_PROTOCOL, "needs": []},
				{"to": ZONE_NODE, "needs": [&"node_door"]},
			]
		ZONE_NODE:
			return [{"to": ZONE_CRYO, "needs": [&"node_door"]}]
	return []


func _neighbours(key: String) -> PackedStringArray:
	var parts: PackedStringArray = key.split("|")
	var zone: int = int(parts[0])
	var core: bool = parts[1] == CORE
	var state: Array[StringName] = []
	for name: String in parts[2].split("/", false):
		state.append(StringName(name))
	var result := PackedStringArray()
	for value: Variant in _zone_moves(zone):
		var move: Dictionary = value
		var allowed: bool = true
		for needed: Variant in move["needs"] as Array:
			allowed = allowed and state.has(StringName(needed))
		if bool(move.get("warm", false)):
			allowed = allowed and (core or state.has(&"heating"))
		if bool(move.get("core", false)):
			allowed = allowed and core
		if allowed:
			var to: int = int(move["to"])
			result.append(_key(to, core or to == ZONE_PROTOCOL, state))
	if not CONSOLE_ZONES.has(zone):
		return result
	for system_id: StringName in _grid.system_ids():
		_grid.set_state(state)
		if int(_grid.toggle(system_id)["result"]) == EnergyGrid.Result.OK:
			result.append(_key(zone, core, _grid.get_state()))
	_grid.set_state(state)
	return result


func _explore(start: String) -> Dictionary:
	var seen: Dictionary = {start: true}
	var pending: PackedStringArray = [start]
	while not pending.is_empty():
		var current: String = pending[pending.size() - 1]
		pending.remove_at(pending.size() - 1)
		for next: String in _neighbours(current):
			if seen.has(next):
				continue
			seen[next] = true
			pending.append(next)
	return seen


func _can_finish(start: String) -> bool:
	for key: Variant in _explore(start):
		if int(String(key).split("|")[0]) == ZONE_NODE:
			return true
	return false


func _key(zone: int, core: bool, state: Array) -> String:
	var names: PackedStringArray = _names(state)
	names.sort()
	return "%d|%s|%s" % [zone, CORE if core else NO_CORE, "/".join(names)]


func _label(key: Variant) -> String:
	var parts: PackedStringArray = String(key).split("|")
	return "%s (%s) com [%s]" % [
		ZONE_NAMES[int(parts[0])], parts[1], parts[2].replace("/", ", ")
	]


func _state() -> PackedStringArray:
	var names: PackedStringArray = _names(_grid.get_state())
	names.sort()
	return names


func _names(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	result.sort()
	return result
