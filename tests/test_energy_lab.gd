extends TestCase

const ENERGY_PATH: String = "res://data/energy/lab.json"
const ZONE_LOW: int = 0
const ZONE_UP: int = 1
const ZONE_WING: int = 2
const ZONE_FURNACE: int = 3
const ZONE_NODE: int = 4
const ZONE_NAMES: Array[String] = ["banda de baixo", "patamar", "ala", "fornalha", "Nó"]
const CONSOLE_ZONES: Array[int] = [ZONE_LOW, ZONE_UP]

var _grid: EnergyGrid = null


func before_each() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	_grid = EnergyGrid.from_dict(raw) if raw is Dictionary else null


func test_terminal_is_six_systems_two_units_and_mute() -> void:
	assert_not_null(_grid, "terminal lab carregou")
	if _grid == null:
		return
	assert_true(_grid.validate().is_empty(), "terminal válido: %s" % ", ".join(_grid.validate()))
	assert_eq(_grid.budget, 2, "duas unidades")
	assert_eq(_grid.system_ids().size(), 6, "seis sistemas")
	assert_eq(_names(_grid.initial_state()), _names([&"towers", &"cooling"]), "estado inicial")
	assert_eq(_names(_grid.goal_systems()), _names([&"node_door"]), "a meta é a porta do Nó")
	assert_false(_grid.goal_met(), "o puzzle não começa resolvido")
	assert_false(_grid.verbose, "fora do tutorial o terminal não explica")


func test_the_sample_lift_needs_the_cooling_line() -> void:
	if _grid == null:
		return
	assert_eq(_names(_grid.requires_of(&"sample_lift")), _names([&"cooling"]), "dependência")
	_grid.set_state([])
	assert_eq(
		_grid.can_power(&"sample_lift"), EnergyGrid.Result.MISSING_DEPENDENCY, "sem refrigeração"
	)
	_grid.power_on(&"cooling")
	assert_eq(_grid.can_power(&"sample_lift"), EnergyGrid.Result.OK, "com refrigeração")
	_grid.power_on(&"sample_lift")
	assert_eq(_grid.power_off(&"cooling").size(), 2, "cortar a refrigeração para o elevador")


func test_the_paper_sequence_solves_the_puzzle() -> void:
	if _grid == null:
		return
	_grid.reset_to_initial()
	_grid.power_off(&"towers")
	assert_eq(_grid.toggle(&"sample_lift")["result"], EnergyGrid.Result.OK, "B: liga o elevador")
	assert_eq(_state(), _names([&"cooling", &"sample_lift"]), "sobe pelo poço")
	_grid.power_off(&"sample_lift")
	assert_eq(_grid.toggle(&"wing_door")["result"], EnergyGrid.Result.OK, "C: abre a ala")
	assert_eq(_state(), _names([&"cooling", &"wing_door"]), "ala aberta com refrigeração")
	assert_false(_grid.goal_met(), "a porta do Nó continua fechada")
	_grid.power_off(&"cooling")
	assert_eq(_grid.toggle(&"node_door")["result"], EnergyGrid.Result.OK, "C: abre o Nó")
	assert_eq(_state(), _names([&"node_door", &"wing_door"]), "rota final")
	assert_true(_grid.goal_met(), "meta cumprida")


func test_cooling_and_both_doors_never_fit() -> void:
	if _grid == null:
		return
	_grid.set_state([&"cooling", &"wing_door"])
	assert_eq(_grid.can_power(&"node_door"), EnergyGrid.Result.NO_BUDGET, "três não cabem em dois")
	_grid.set_state([&"cooling", &"node_door"])
	assert_eq(_grid.can_power(&"wing_door"), EnergyGrid.Result.NO_BUDGET, "nem na outra ordem")
	_grid.set_state([&"cooling", &"wing_door", &"node_door"])
	assert_true(_grid.used() <= _grid.budget, "o terminal recusa o estado impossível")


func test_the_naive_meta_first_choice_cannot_climb() -> void:
	if _grid == null:
		return
	_grid.set_state([&"cooling", &"node_door"])
	assert_eq(
		_grid.can_power(&"sample_lift"), EnergyGrid.Result.NO_BUDGET, "com a meta ligada não sobe"
	)
	for start: Array in [[&"towers", &"node_door"], [&"node_door", &"relief"]]:
		_grid.set_state(start)
		assert_ne(
			_grid.can_power(&"sample_lift"), EnergyGrid.Result.OK, "elevador com %s" % str(start)
		)


func test_every_way_to_the_node_runs_without_cooling() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_LOW, _grid.initial_state()))
	var arrivals: int = 0
	for key: Variant in reachable:
		var parts: PackedStringArray = String(key).split("|")
		if int(parts[0]) != ZONE_NODE:
			continue
		arrivals += 1
		var systems: PackedStringArray = parts[1].split("/", false)
		assert_false(systems.has("cooling"), "chegou ao Nó com refrigeração: %s" % parts[1])
		assert_true(systems.has("wing_door") and systems.has("node_door"), "as duas portas")
	assert_true(arrivals > 0, "o Nó é alcançável")


func test_no_energy_state_can_strand_the_player() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_LOW, _grid.initial_state()))
	assert_true(reachable.size() > 4, "a busca visitou o mapa")
	for key: Variant in reachable:
		assert_true(_can_finish(String(key)), "o estado '%s' ainda fecha a fase" % _label(key))


func test_at_least_two_forced_trades() -> void:
	if _grid == null:
		return
	var start: String = _key(ZONE_LOW, _grid.initial_state())
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
			var cost: int = 0 if next.split("|")[1] == current.split("|")[1] else 1
			var total: int = int(distance[current]) + cost
			if distance.has(next) and int(distance[next]) <= total:
				continue
			distance[next] = total
			if cost == 0:
				queue.insert(0, next)
			else:
				queue.append(next)
	assert_true(best >= 4, "o caminho mais curto pede %d trocas no terminal" % best)


func _zone_moves(zone: int) -> Array:
	match zone:
		ZONE_LOW:
			return [{"to": ZONE_UP, "needs": [&"sample_lift"]}]
		ZONE_UP:
			return [{"to": ZONE_LOW, "needs": []}, {"to": ZONE_WING, "needs": [&"wing_door"]}]
		ZONE_WING:
			return [{"to": ZONE_UP, "needs": [&"wing_door"]}, {"to": ZONE_FURNACE, "needs": []}]
		ZONE_FURNACE:
			return [{"to": ZONE_WING, "needs": []}, {"to": ZONE_NODE, "needs": [&"node_door"]}]
		ZONE_NODE:
			return [{"to": ZONE_FURNACE, "needs": [&"node_door"]}]
	return []


func _neighbours(key: String) -> PackedStringArray:
	var parts: PackedStringArray = key.split("|")
	var zone: int = int(parts[0])
	var state: Array[StringName] = []
	for name: String in parts[1].split("/", false):
		state.append(StringName(name))
	var result := PackedStringArray()
	for value: Variant in _zone_moves(zone):
		var move: Dictionary = value
		var allowed: bool = true
		for needed: Variant in move["needs"] as Array:
			allowed = allowed and state.has(StringName(needed))
		if allowed:
			result.append(_key(int(move["to"]), state))
	if not CONSOLE_ZONES.has(zone):
		return result
	for system_id: StringName in _grid.system_ids():
		_grid.set_state(state)
		if int(_grid.toggle(system_id)["result"]) == EnergyGrid.Result.OK:
			result.append(_key(zone, _grid.get_state()))
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


func _key(zone: int, state: Array) -> String:
	var names: PackedStringArray = _names(state)
	names.sort()
	return "%d|%s" % [zone, "/".join(names)]


func _label(key: Variant) -> String:
	var parts: PackedStringArray = String(key).split("|")
	return "%s com [%s]" % [ZONE_NAMES[int(parts[0])], parts[1].replace("/", ", ")]


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
