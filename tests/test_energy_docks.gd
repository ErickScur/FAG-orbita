extends TestCase

const ENERGY_PATH: String = "res://data/energy/docks.json"
const ZONE_GALLERY: int = 0
const ZONE_HANGAR: int = 1
const ZONE_GANTRY: int = 2
const ZONE_EVA: int = 3
const ZONE_DUCT: int = 4
const ZONE_RING: int = 5
const ZONE_LANDING: int = 6
const ZONE_CONSOLE_C: int = 7
const ZONE_PASSAGE: int = 8
const ZONE_NODE: int = 9
const ZONE_NAMES: Array[String] = [
	"galeria", "hangar", "passadiço", "vestiário", "duto", "anel externo", "pouso",
	"bloco de C", "passagem", "Nó",
]
const CONSOLE_ZONES: Array[int] = [ZONE_HANGAR, ZONE_EVA, ZONE_CONSOLE_C]
const THRUSTER: String = "thruster"
const NO_THRUSTER: String = "legs"
const FINAL_STATE: Array[StringName] = [&"containment", &"outer_hatch", &"node_door"]

var _grid: EnergyGrid = null


func before_each() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	_grid = EnergyGrid.from_dict(raw) if raw is Dictionary else null


func test_terminal_is_six_systems_three_units_and_mute() -> void:
	assert_not_null(_grid, "terminal docks carregou")
	if _grid == null:
		return
	assert_true(_grid.validate().is_empty(), "terminal válido: %s" % ", ".join(_grid.validate()))
	assert_eq(_grid.budget, 3, "três unidades")
	assert_eq(_grid.system_ids().size(), 6, "seis sistemas")
	assert_eq(
		_names(_grid.initial_state()), _names([&"security", &"containment"]), "estado inicial"
	)
	assert_eq(_names(_grid.goal_systems()), _names([&"node_door"]), "a meta é a antessala")
	assert_false(_grid.goal_met(), "o puzzle não começa resolvido")
	assert_false(_grid.verbose, "fora do tutorial o terminal não explica")


func test_the_goal_is_a_chain_that_fills_the_budget() -> void:
	if _grid == null:
		return
	assert_eq(_names(_grid.requires_of(&"node_door")), _names([&"outer_hatch"]), "meta na eclusa")
	assert_eq(_names(_grid.requires_of(&"outer_hatch")), _names([&"containment"]), "eclusa no campo")
	assert_eq(_names(_grid.requires_of(&"cargo_lift")), _names([&"containment"]), "elevador no campo")
	_grid.set_state([])
	assert_eq(_grid.can_power(&"node_door"), EnergyGrid.Result.MISSING_DEPENDENCY, "sem eclusa")
	_grid.set_state(FINAL_STATE)
	assert_eq(_grid.free_units(), 0, "a cadeia da meta ocupa o orçamento inteiro")
	for other: StringName in [&"security", &"cargo_lift", &"eva_door"]:
		assert_eq(_grid.can_power(other), EnergyGrid.Result.NO_BUDGET, "%s não cabe" % other)
	assert_eq(_grid.power_off(&"containment").size(), 3, "cortar o campo derruba a cadeia")


func test_the_safe_route_on_paper_solves_the_puzzle() -> void:
	if _grid == null:
		return
	_grid.reset_to_initial()
	_grid.power_off(&"security")
	assert_eq(_grid.toggle(&"cargo_lift")["result"], EnergyGrid.Result.OK, "A: elevador")
	assert_eq(_grid.toggle(&"eva_door")["result"], EnergyGrid.Result.OK, "A: vestiário")
	assert_eq(_state(), _names([&"containment", &"cargo_lift", &"eva_door"]), "sobe pelo elevador")
	_grid.power_off(&"cargo_lift")
	assert_eq(_grid.toggle(&"outer_hatch")["result"], EnergyGrid.Result.OK, "B: eclusa")
	_grid.power_off(&"eva_door")
	assert_eq(_grid.toggle(&"node_door")["result"], EnergyGrid.Result.OK, "C: antessala")
	assert_eq(_state(), _names(FINAL_STATE), "estado final")
	assert_true(_grid.goal_met(), "meta cumprida")


func test_the_vacuum_route_on_paper_solves_the_puzzle() -> void:
	if _grid == null:
		return
	_grid.reset_to_initial()
	_grid.power_off(&"containment")
	assert_eq(_grid.toggle(&"eva_door")["result"], EnergyGrid.Result.OK, "A: vestiário")
	assert_eq(_state(), _names([&"security", &"eva_door"]), "flutua até o passadiço")
	assert_eq(_grid.toggle(&"containment")["result"], EnergyGrid.Result.OK, "B: campo")
	assert_eq(_grid.can_power(&"outer_hatch"), EnergyGrid.Result.NO_BUDGET, "B: falta unidade")
	_grid.power_off(&"security")
	assert_eq(_grid.toggle(&"outer_hatch")["result"], EnergyGrid.Result.OK, "B: eclusa")
	_grid.power_off(&"eva_door")
	assert_eq(_grid.toggle(&"node_door")["result"], EnergyGrid.Result.OK, "C: antessala")
	assert_true(_grid.goal_met(), "meta cumprida")


func test_the_naive_choices_at_a_do_not_reach_the_suit_room() -> void:
	if _grid == null:
		return
	for start: Array in [
		[&"security", &"containment", &"eva_door"],
		[&"containment", &"outer_hatch", &"node_door"],
	]:
		var reached: Dictionary = _explore(_key(ZONE_HANGAR, false, start), false)
		for key: Variant in reached:
			assert_ne(
				int(String(key).split("|")[0]), ZONE_EVA, "sem trocar em A chegou ao vestiário"
			)


func test_every_way_to_the_node_has_the_thruster_and_the_final_chain() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_GALLERY, false, _grid.initial_state()))
	var arrivals: int = 0
	for key: Variant in reachable:
		var parts: PackedStringArray = String(key).split("|")
		if int(parts[0]) != ZONE_NODE:
			continue
		arrivals += 1
		assert_eq(parts[1], THRUSTER, "chegou ao Nó sem o Propulsor")
		assert_eq(parts[2], "/".join(_names(FINAL_STATE)), "estado ao chegar: %s" % parts[2])
	assert_true(arrivals > 0, "o Nó é alcançável")


func test_no_energy_state_can_strand_the_player() -> void:
	if _grid == null:
		return
	var reachable: Dictionary = _explore(_key(ZONE_GALLERY, false, _grid.initial_state()))
	assert_true(reachable.size() > 10, "a busca visitou o mapa")
	for key: Variant in reachable:
		assert_true(_can_finish(String(key)), "o estado '%s' ainda fecha a fase" % _label(key))


func test_at_least_six_forced_toggles() -> void:
	if _grid == null:
		return
	var start: String = _key(ZONE_GALLERY, false, _grid.initial_state())
	var distance: Dictionary = {start: 0}
	var queue: PackedStringArray = [start]
	var best: int = -1
	while not queue.is_empty():
		var current: String = queue[0]
		queue.remove_at(0)
		if int(current.split("|")[0]) == ZONE_NODE:
			best = int(distance[current]) if best < 0 else mini(best, int(distance[current]))
			continue
		for next: String in _neighbours(current, true):
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
		ZONE_GALLERY:
			return [{"to": ZONE_HANGAR, "needs": []}]
		ZONE_HANGAR:
			return [
				{"to": ZONE_GALLERY, "needs": [], "vacuum": true},
				{"to": ZONE_GANTRY, "needs": [], "vacuum": true},
				{"to": ZONE_GANTRY, "needs": [&"cargo_lift"]},
			]
		ZONE_GANTRY:
			return [
				{"to": ZONE_HANGAR, "needs": []},
				{"to": ZONE_EVA, "needs": [&"eva_door"]},
			]
		ZONE_EVA:
			return [
				{"to": ZONE_GANTRY, "needs": [&"eva_door"]},
				{"to": ZONE_DUCT, "needs": [], "thruster": true},
			]
		ZONE_DUCT:
			return [
				{"to": ZONE_EVA, "needs": []},
				{"to": ZONE_HANGAR, "needs": []},
				{"to": ZONE_RING, "needs": [&"outer_hatch"]},
			]
		ZONE_RING:
			return [
				{"to": ZONE_DUCT, "needs": [&"outer_hatch"]},
				{"to": ZONE_LANDING, "needs": []},
			]
		ZONE_LANDING:
			return [{"to": ZONE_CONSOLE_C, "needs": [], "thruster": true}]
		ZONE_CONSOLE_C:
			return [
				{"to": ZONE_LANDING, "needs": []},
				{"to": ZONE_PASSAGE, "needs": [&"node_door"]},
			]
		ZONE_PASSAGE:
			return [
				{"to": ZONE_CONSOLE_C, "needs": [&"node_door"], "thruster": true},
				{"to": ZONE_NODE, "needs": []},
			]
	return []


func _neighbours(key: String, consoles: bool = true) -> PackedStringArray:
	var parts: PackedStringArray = key.split("|")
	var zone: int = int(parts[0])
	var thruster: bool = parts[1] == THRUSTER
	var state: Array[StringName] = []
	for name: String in parts[2].split("/", false):
		state.append(StringName(name))
	var result := PackedStringArray()
	for value: Variant in _zone_moves(zone):
		var move: Dictionary = value
		var allowed: bool = true
		for needed: Variant in move["needs"] as Array:
			allowed = allowed and state.has(StringName(needed))
		if bool(move.get("vacuum", false)):
			allowed = allowed and not state.has(&"containment")
		if bool(move.get("thruster", false)):
			allowed = allowed and thruster
		if allowed:
			var to: int = int(move["to"])
			result.append(_key(to, thruster or to == ZONE_EVA, state))
	if not consoles or not CONSOLE_ZONES.has(zone):
		return result
	for system_id: StringName in _grid.system_ids():
		_grid.set_state(state)
		if int(_grid.toggle(system_id)["result"]) == EnergyGrid.Result.OK:
			result.append(_key(zone, thruster, _grid.get_state()))
	_grid.set_state(state)
	return result


func _explore(start: String, consoles: bool = true) -> Dictionary:
	var seen: Dictionary = {start: true}
	var pending: PackedStringArray = [start]
	while not pending.is_empty():
		var current: String = pending[pending.size() - 1]
		pending.remove_at(pending.size() - 1)
		for next: String in _neighbours(current, consoles):
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


func _key(zone: int, thruster: bool, state: Array) -> String:
	var names: PackedStringArray = _names(state)
	names.sort()
	return "%d|%s|%s" % [zone, THRUSTER if thruster else NO_THRUSTER, "/".join(names)]


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
