extends TestCase

const ENERGY_DIR: String = "res://data/energy/"
const DIALOGUE_DIR: String = "res://data/dialogue/"
const GOAL_TAG: String = "META"
const CORE_HUB: StringName = &"core_hub"
const GREENHOUSE: StringName = &"greenhouse"


func test_all_energy_json_load_and_validate() -> void:
	var files: PackedStringArray = _files()
	assert_false(files.is_empty(), "pelo menos um terminal em %s" % ENERGY_DIR)
	for file_name: String in files:
		var grid: EnergyGrid = _load(file_name.get_basename())
		assert_not_null(grid, "terminal '%s' carregou" % file_name)
		if grid == null:
			continue
		assert_eq(String(grid.id), file_name.get_basename(), "id igual ao nome do arquivo")
		var errors: PackedStringArray = grid.validate()
		assert_true(errors.is_empty(), "'%s': %s" % [file_name, ", ".join(errors)])


func test_every_terminal_is_scarce() -> void:
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		var total: int = 0
		for system_id: StringName in grid.system_ids():
			total += grid.cost_of(system_id)
		assert_true(
			total > grid.budget,
			"'%s': custos %d devem superar o orçamento %d" % [file_name, total, grid.budget]
		)


func test_effect_targets_have_prefix() -> void:
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		for system_id: StringName in grid.system_ids():
			for value: Variant in grid.effects_of(system_id):
				var effect: Dictionary = value
				var target: String = String(effect["target"])
				assert_true(
					target.begins_with(EnergyGrid.TARGET_GROUP)
					or target.begins_with(EnergyGrid.TARGET_ID),
					"'%s': alvo '%s' sem prefixo" % [file_name, target]
				)
				var action: StringName = effect["action"]
				assert_true(
					action == EnergyGrid.ACTION_POWER or action == EnergyGrid.ACTION_INVERT,
					"'%s': ação '%s' inválida" % [file_name, action]
				)


func test_every_terminal_states_its_goal() -> void:
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		assert_false(grid.goal_text.strip_edges().is_empty(), "'%s' sem meta" % file_name)
		assert_false(
			grid.goal_done_text.strip_edges().is_empty(), "'%s' sem meta cumprida" % file_name
		)
		assert_false(grid.goal_systems().is_empty(), "'%s' sem sistema de meta" % file_name)
		assert_false(grid.goal_met(), "'%s' não começa com a meta cumprida" % file_name)


func test_every_system_has_a_tag_and_a_loss() -> void:
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		for system_id: StringName in grid.system_ids():
			assert_false(
				grid.tag_of(system_id).strip_edges().is_empty(),
				"'%s': sistema '%s' sem etiqueta" % [file_name, system_id]
			)
			assert_false(
				grid.effect_off_of(system_id).strip_edges().is_empty(),
				"'%s': sistema '%s' sem consequência ao desligar" % [file_name, system_id]
			)


func test_goal_systems_carry_the_goal_tag() -> void:
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		for system_id: StringName in grid.goal_systems():
			assert_eq(
				grid.tag_of(system_id),
				GOAL_TAG,
				"'%s': sistema da meta '%s' precisa da etiqueta META" % [file_name, system_id]
			)


func test_every_bark_exists_in_dialogue() -> void:
	var content: Dictionary = DialogueData.load_dir(DIALOGUE_DIR)
	var sequences: Dictionary = content["sequences"]
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		if grid.intro_bark != &"":
			assert_true(
				sequences.has(grid.intro_bark),
				"'%s': fala de abertura '%s' não existe" % [file_name, grid.intro_bark]
			)
		for system_id: StringName in grid.system_ids():
			for powered: bool in [true, false]:
				var bark: StringName = grid.bark_of(system_id, powered)
				if bark == &"":
					continue
				assert_true(
					sequences.has(bark), "'%s': fala '%s' não existe" % [file_name, bark]
				)
				var mode: StringName = DialogueData.sequence_mode(sequences, bark)
				assert_eq(
					String(mode),
					String(DialogueData.MODE_AMBIENT),
					"fala '%s' precisa ser ambiente (não congela o timer)" % bark
				)
				assert_false(
					bool((sequences[bark] as Dictionary).get("once", true)),
					"fala '%s' precisa poder repetir" % bark
				)


func test_core_hub_trade_is_explicit() -> void:
	var grid: EnergyGrid = _load(String(CORE_HUB))
	if grid == null:
		return
	assert_eq(
		_names(grid.shutdown_candidates(&"door_habitat")),
		_names([&"lights_core"]),
		"para abrir a porta só dá para desligar a iluminação"
	)


func test_greenhouse_trade_lists_every_option() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	assert_eq(
		_names(grid.shutdown_candidates(&"node_door")),
		_names([&"heating", &"corridor_light"]),
		"a porta do Nó cabe no lugar de qualquer um dos dois"
	)
	assert_eq(
		_names(grid.shutdown_candidates(&"lift_platform")),
		_names([&"corridor_light"]),
		"o elevador depende do aquecimento, então só a iluminação pode cair"
	)


func test_goal_systems_always_narrate_the_switch() -> void:
	for file_name: String in _files():
		var grid: EnergyGrid = _load(file_name.get_basename())
		if grid == null:
			continue
		for system_id: StringName in grid.goal_systems():
			for powered: bool in [true, false]:
				assert_ne(
					grid.bark_of(system_id, powered),
					&"",
					"'%s': meta '%s' sem fala" % [file_name, system_id]
				)


func test_core_hub_is_three_one() -> void:
	var grid: EnergyGrid = _load(String(CORE_HUB))
	assert_not_null(grid, "tutorial existe")
	if grid == null:
		return
	assert_eq(grid.budget, 1, "uma unidade de energia")
	assert_eq(grid.system_ids().size(), 3, "três sistemas")
	assert_true(grid.is_powered(&"lights_core"), "começa com a luz acesa")
	assert_false(grid.is_powered(&"lift_core"), "elevador começa parado")
	assert_false(grid.is_powered(&"door_habitat"), "porta começa fechada")
	assert_eq(grid.can_power(&"door_habitat"), EnergyGrid.Result.NO_BUDGET, "porta sem orçamento")
	assert_eq(grid.can_power(&"lift_core"), EnergyGrid.Result.NO_BUDGET, "elevador sem orçamento")


func test_core_hub_lift_is_an_optional_detour() -> void:
	var grid: EnergyGrid = _load(String(CORE_HUB))
	if grid == null:
		return
	_step(grid, &"lights_core", "apaga a luz para liberar a unidade")
	_step(grid, &"lift_core", "liga o elevador de serviço")
	assert_false(grid.goal_met(), "o elevador sozinho não abre a porta")
	assert_eq(
		grid.can_power(&"door_habitat"),
		EnergyGrid.Result.NO_BUDGET,
		"com o elevador ligado a porta não cabe"
	)
	_step(grid, &"lift_core", "desliga o elevador ao voltar ao terminal")
	_step(grid, &"door_habitat", "abre a porta")
	assert_true(grid.goal_met(), "meta cumprida depois do desvio")


func test_core_hub_has_no_softlock() -> void:
	var grid: EnergyGrid = _load(String(CORE_HUB))
	if grid == null:
		return
	var ids: Array[StringName] = grid.system_ids()
	var total: int = ids.size()
	for mask: int in range(1 << total):
		var wanted: Array[StringName] = []
		for index: int in range(total):
			if mask & (1 << index) != 0:
				wanted.append(ids[index])
		grid.set_state(wanted)
		assert_true(
			_can_reach(grid, &"door_habitat"),
			"estado %s ainda permite abrir a porta" % ", ".join(_names(grid.powered()))
		)


func test_core_hub_lesson_light_or_door() -> void:
	var grid: EnergyGrid = _load(String(CORE_HUB))
	if grid == null:
		return
	var refused: Dictionary = grid.toggle(&"door_habitat")
	assert_eq(refused["result"], EnergyGrid.Result.NO_BUDGET, "recusa antes de desligar a luz")
	assert_eq(grid.toggle(&"lights_core")["result"], EnergyGrid.Result.OK, "apaga a luz")
	assert_eq(grid.toggle(&"door_habitat")["result"], EnergyGrid.Result.OK, "abre a porta")
	assert_true(grid.is_powered(&"door_habitat"), "porta aberta")
	assert_false(grid.is_powered(&"lights_core"), "luz apagada")
	assert_eq(grid.used(), 1, "1/1 em uso")


func test_core_hub_never_powers_everything() -> void:
	_assert_never_all_on(String(CORE_HUB))


func test_greenhouse_is_five_two() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	assert_not_null(grid, "estufa existe")
	if grid == null:
		return
	assert_eq(grid.budget, 2, "duas unidades de energia")
	assert_eq(grid.system_ids().size(), 5, "cinco sistemas")
	assert_eq(grid.used(), 2, "começa com aquecimento e corredor")
	assert_true(grid.is_powered(&"heating"), "aquecimento inicial")
	assert_true(grid.is_powered(&"corridor_light"), "corredor inicial")


func test_greenhouse_route_plant() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	_step(grid, &"heating", "desliga o aquecimento e encolhe os esporos")
	_step(grid, &"grow_light", "liga a luz de crescimento")
	assert_true(grid.is_powered(&"grow_light"), "planta virou plataforma")
	assert_true(grid.is_powered(&"corridor_light"), "corredor ainda aceso")
	_step(grid, &"corridor_light", "apaga o corredor no console B")
	_step(grid, &"node_door", "abre a porta do Nó")
	assert_true(grid.is_powered(&"node_door"), "porta do Nó aberta")
	assert_eq(grid.used(), 2, "2/2 em uso")


func test_greenhouse_route_lift() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	_step(grid, &"corridor_light", "apaga o corredor")
	_step(grid, &"lift_platform", "liga a plataforma de carga")
	assert_true(grid.is_powered(&"heating"), "aquecimento mantido pela dependência")
	_step(grid, &"lift_platform", "desliga a plataforma lá em cima")
	_step(grid, &"node_door", "abre a porta do Nó")
	assert_true(grid.is_powered(&"node_door"), "porta do Nó aberta")
	assert_true(grid.is_powered(&"heating"), "aquecimento segue ligado")


func test_greenhouse_lift_falls_with_heating() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	grid.power_off(&"corridor_light")
	grid.power_on(&"lift_platform")
	var fallen: Array[StringName] = grid.power_off(&"heating")
	assert_eq(fallen.size(), 2, "aquecimento derruba o elevador")
	assert_false(grid.is_powered(&"lift_platform"), "elevador caiu em cascata")


func test_greenhouse_lift_requires_heating() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	grid.power_off(&"heating")
	grid.power_off(&"corridor_light")
	assert_eq(
		grid.can_power(&"lift_platform"),
		EnergyGrid.Result.MISSING_DEPENDENCY,
		"elevador exige aquecimento"
	)


func test_greenhouse_never_powers_everything() -> void:
	_assert_never_all_on(String(GREENHOUSE))


func test_greenhouse_has_no_softlock() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	var ids: Array[StringName] = grid.system_ids()
	var total: int = ids.size()
	for mask: int in range(1 << total):
		var wanted: Array[StringName] = []
		for index: int in range(total):
			if mask & (1 << index) != 0:
				wanted.append(ids[index])
		grid.set_state(wanted)
		assert_true(
			_can_reach(grid, &"node_door"),
			"estado %s ainda permite abrir a porta do Nó" % ", ".join(_names(grid.powered()))
		)


func test_greenhouse_state_survives_roundtrip() -> void:
	var grid: EnergyGrid = _load(String(GREENHOUSE))
	if grid == null:
		return
	grid.power_off(&"corridor_light")
	grid.power_on(&"lift_platform")
	var saved: PackedStringArray = _names(grid.get_state())
	var reloaded: EnergyGrid = _load(String(GREENHOUSE))
	reloaded.set_state(grid.get_state())
	assert_eq(_names(reloaded.get_state()), saved, "estado reproduzido após recarregar")


func _step(grid: EnergyGrid, system_id: StringName, what: String) -> void:
	var outcome: Dictionary = grid.toggle(system_id)
	assert_eq(outcome["result"], EnergyGrid.Result.OK, what)


func _assert_never_all_on(terminal_id: String) -> void:
	var grid: EnergyGrid = _load(terminal_id)
	if grid == null:
		return
	var ids: Array[StringName] = grid.system_ids()
	var total: int = ids.size()
	for mask: int in range(1 << total):
		var wanted: Array[StringName] = []
		var cost: int = 0
		for index: int in range(total):
			if mask & (1 << index) == 0:
				continue
			wanted.append(ids[index])
			cost += grid.cost_of(ids[index])
		grid.set_state(wanted)
		assert_true(
			grid.used() <= grid.budget,
			"'%s': estado acima do orçamento" % terminal_id
		)
		if cost > grid.budget:
			assert_true(
				grid.powered().size() < wanted.size(),
				"'%s': combinação %s não pode caber" % [terminal_id, ", ".join(_names(wanted))]
			)
	grid.set_state(ids)
	assert_true(
		grid.powered().size() < total, "'%s': nunca existe estado com tudo ligado" % terminal_id
	)


func _can_reach(grid: EnergyGrid, system_id: StringName) -> bool:
	if grid.is_powered(system_id):
		return true
	if grid.can_power(system_id) == EnergyGrid.Result.OK:
		return true
	for candidate: StringName in grid.powered():
		var probe: EnergyGrid = _load(String(grid.id))
		if probe == null:
			return false
		probe.set_state(grid.powered())
		probe.power_off(candidate)
		if probe.can_power(system_id) == EnergyGrid.Result.OK:
			return true
	return false


func _names(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	return result


func _files() -> PackedStringArray:
	var files: PackedStringArray = []
	var dir := DirAccess.open(ENERGY_DIR)
	if dir == null:
		return files
	for file_name: String in dir.get_files():
		if file_name.ends_with(".json"):
			files.append(file_name)
	files.sort()
	return files


func _load(terminal_id: String) -> EnergyGrid:
	var path: String = ENERGY_DIR + terminal_id + ".json"
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		return null
	return EnergyGrid.from_dict(parsed)
