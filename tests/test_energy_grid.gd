extends TestCase


func test_initial_state_from_json() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(grid.id, &"sample", "id do terminal")
	assert_eq(grid.budget, 2, "orçamento")
	assert_eq(_list(grid.powered()), _text(["heating", "corridor_light"]), "iniciais")
	assert_eq(grid.used(), 2, "unidades em uso")
	assert_eq(grid.free_units(), 0, "unidades livres")


func test_system_lookup_returns_data() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(grid.system_name(&"heating"), "AQUECIMENTO", "nome")
	assert_eq(grid.cost_of(&"heating"), 1, "custo")
	assert_eq(grid.system_ids().size(), 5, "cinco sistemas")
	assert_true(grid.has_system(&"node_door"), "sistema conhecido")
	assert_false(grid.has_system(&"nada"), "sistema desconhecido")
	assert_true(grid.system(&"nada").is_empty(), "consulta inexistente devolve vazio")


func test_power_on_without_budget() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(grid.can_power(&"node_door"), EnergyGrid.Result.NO_BUDGET, "sem orçamento")
	var changed: Array[StringName] = grid.power_on(&"node_door")
	assert_true(changed.is_empty(), "nada mudou")
	assert_false(grid.is_powered(&"node_door"), "continua desligado")
	assert_eq(grid.used(), 2, "uso inalterado")


func test_power_on_after_power_off() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(grid.power_off(&"corridor_light").size(), 1, "desligou um")
	assert_eq(grid.free_units(), 1, "liberou uma unidade")
	assert_eq(grid.can_power(&"node_door"), EnergyGrid.Result.OK, "agora cabe")
	assert_eq(_list(grid.power_on(&"node_door")), _text(["node_door"]), "ligou")
	assert_eq(grid.used(), 2, "voltou a 2/2")


func test_requires_blocks() -> void:
	var grid: EnergyGrid = _sample()
	grid.power_off(&"heating")
	assert_eq(
		grid.can_power(&"lift_platform"), EnergyGrid.Result.MISSING_DEPENDENCY, "sem aquecimento"
	)
	assert_eq(grid.missing_requirement(&"lift_platform"), &"heating", "dependência faltante")
	assert_true(grid.power_on(&"lift_platform").is_empty(), "não liga")


func test_cascade_off() -> void:
	var grid: EnergyGrid = _sample()
	grid.power_off(&"corridor_light")
	grid.power_on(&"lift_platform")
	assert_true(grid.is_powered(&"lift_platform"), "elevador ligado")
	var fallen: Array[StringName] = grid.power_off(&"heating")
	assert_eq(_list(fallen), _text(["heating", "lift_platform"]), "cascata na ordem")
	assert_eq(grid.used(), 0, "setor sem consumo")


func test_cascade_is_transitive() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "chain",
			"title": "CADEIA",
			"budget": 3,
			"goal_text": "Ligar o sistema D",
			"goal_done_text": "Sistema D ligado",
			"goal_systems": ["d"],
			"initial": ["a", "b", "c"],
			"systems": [
				_system("a", 1, []),
				_system("b", 1, ["a"]),
				_system("c", 1, ["b"]),
				_system("d", 1, []),
			],
		}
	)
	assert_true(grid.validate().is_empty(), "cadeia válida: %s" % ", ".join(grid.validate()))
	assert_eq(_list(grid.power_off(&"a")), _text(["a", "b", "c"]), "queda em cadeia completa")


func test_toggle_returns_reason() -> void:
	var grid: EnergyGrid = _sample()
	var outcome: Dictionary = grid.toggle(&"node_door")
	assert_eq(outcome["result"], EnergyGrid.Result.NO_BUDGET, "motivo devolvido")
	assert_true((outcome["on"] as Array).is_empty(), "nada ligou")
	assert_true((outcome["off"] as Array).is_empty(), "nada desligou")


func test_toggle_on_and_off() -> void:
	var grid: EnergyGrid = _sample()
	var off: Dictionary = grid.toggle(&"heating")
	assert_eq(off["result"], EnergyGrid.Result.OK, "desligou")
	assert_eq(_list(off["off"]), _text(["heating"]), "lista do desligado")
	var on: Dictionary = grid.toggle(&"heating")
	assert_eq(on["result"], EnergyGrid.Result.OK, "religou")
	assert_eq(_list(on["on"]), _text(["heating"]), "lista do ligado")


func test_toggle_unknown_system() -> void:
	var grid: EnergyGrid = _sample()
	var outcome: Dictionary = grid.toggle(&"fantasma")
	assert_eq(outcome["result"], EnergyGrid.Result.UNKNOWN_SYSTEM, "sistema inexistente")


func test_locked_system_never_toggles() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "locked",
			"title": "SELADO",
			"budget": 1,
			"goal_text": "Ligar o circuito aberto",
			"goal_done_text": "Circuito aberto ligado",
			"goal_systems": ["open_one"],
			"initial": [],
			"systems": [
				_system("open_one", 1, []),
				{
					"id": "sealed_one",
					"name": "SELADO",
					"tag": "PERIGO",
					"description": "Circuito lacrado pelo protocolo.",
					"effect_off": "O circuito lacrado não responde.",
					"cost": 1,
					"requires": [],
					"locked": true,
					"effects": [],
				},
			],
		}
	)
	assert_true(grid.validate().is_empty(), "dados válidos")
	assert_eq(grid.can_power(&"sealed_one"), EnergyGrid.Result.LOCKED, "selado")
	assert_eq(grid.toggle(&"sealed_one")["result"], EnergyGrid.Result.LOCKED, "toggle recusado")


func test_dependents_of() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(_list(grid.dependents_of(&"heating")), _text(["lift_platform"]), "dependentes")
	assert_true(grid.dependents_of(&"node_door").is_empty(), "sem dependentes")


func test_state_roundtrip() -> void:
	var grid: EnergyGrid = _sample()
	grid.power_off(&"corridor_light")
	grid.power_on(&"lift_platform")
	var snapshot: Array[StringName] = grid.get_state()
	var other: EnergyGrid = _sample()
	other.set_state(snapshot)
	assert_eq(_list(other.get_state()), _list(snapshot), "estado reproduzido")
	assert_eq(other.used(), grid.used(), "mesmo consumo")
	assert_eq(_list(other.powered()), _list(grid.powered()), "mesmos ligados")


func test_set_state_respects_dependency_order() -> void:
	var grid: EnergyGrid = _sample()
	grid.set_state([&"lift_platform", &"heating"])
	assert_true(grid.is_powered(&"heating"), "aquecimento restaurado")
	assert_true(grid.is_powered(&"lift_platform"), "elevador restaurado mesmo fora de ordem")


func test_set_state_discards_impossible_entries() -> void:
	var grid: EnergyGrid = _sample()
	grid.set_state([&"heating", &"corridor_light", &"node_door", &"fantasma"])
	assert_eq(grid.used(), 2, "nunca passa do orçamento")
	assert_false(grid.is_powered(&"fantasma"), "id desconhecido ignorado")


func test_set_state_drops_orphan_dependency() -> void:
	var grid: EnergyGrid = _sample()
	grid.set_state([&"lift_platform"])
	assert_false(grid.is_powered(&"lift_platform"), "sem aquecimento não restaura")


func test_reset_to_initial() -> void:
	var grid: EnergyGrid = _sample()
	grid.power_off(&"heating")
	grid.reset_to_initial()
	assert_eq(_list(grid.powered()), _list(grid.initial_state()), "voltou ao estado inicial")


func test_validate_accepts_sample() -> void:
	var grid: EnergyGrid = _sample()
	assert_true(grid.validate().is_empty(), "amostra válida: %s" % ", ".join(grid.validate()))


func test_validate_detects_no_scarcity() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "farto",
			"title": "SEM ESCASSEZ",
			"budget": 3,
			"initial": [],
			"systems": [_system("a", 1, []), _system("b", 1, []), _system("c", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "sem escassez"), "orçamento que liga tudo é inválido")


func test_validate_detects_unknown_requirement() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "orfao",
			"title": "ÓRFÃO",
			"budget": 1,
			"initial": [],
			"systems": [_system("a", 1, ["fantasma"]), _system("b", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "inexistente"), "dependência fantasma acusada")


func test_validate_detects_cycle() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "ciclo",
			"title": "CICLO",
			"budget": 1,
			"initial": [],
			"systems": [_system("a", 1, ["b"]), _system("b", 1, ["a"])],
		}
	)
	assert_true(_has(grid.validate(), "ciclo"), "ciclo acusado")


func test_validate_detects_self_requirement() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "eu",
			"title": "EU MESMO",
			"budget": 1,
			"initial": [],
			"systems": [_system("a", 1, ["a"]), _system("b", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "depende de si mesmo"), "autodependência acusada")


func test_validate_detects_invalid_initial() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "cheio",
			"title": "CHEIO",
			"budget": 1,
			"initial": ["a", "b"],
			"systems": [_system("a", 1, []), _system("b", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "estado inicial usa"), "inicial acima do orçamento")


func test_validate_detects_initial_without_requirement() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "solto",
			"title": "SOLTO",
			"budget": 2,
			"initial": ["b"],
			"systems": [_system("a", 1, []), _system("b", 1, ["a"]), _system("c", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "sem 'a'"), "inicial sem dependência acusado")


func test_validate_detects_duplicate_id() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "repetido",
			"title": "REPETIDO",
			"budget": 1,
			"initial": [],
			"systems": [_system("a", 1, []), _system("a", 1, []), _system("b", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "id repetido"), "id duplicado acusado")


func test_validate_detects_bad_cost_and_budget() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "ruim",
			"title": "RUIM",
			"budget": 0,
			"initial": [],
			"systems": [_system("a", 0, []), _system("b", 1, [])],
		}
	)
	var errors: PackedStringArray = grid.validate()
	assert_true(_has(errors, "orçamento 0"), "orçamento inválido")
	assert_true(_has(errors, "custo de 'a'"), "custo inválido")


func test_validate_detects_bad_effect() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "efeito",
			"title": "EFEITO",
			"budget": 1,
			"initial": [],
			"systems": [
				{
					"id": "a",
					"name": "A",
					"description": "Sistema A.",
					"cost": 1,
					"requires": [],
					"effects": [{"target": "porta", "action": "ligar"}],
				},
				_system("b", 1, []),
			],
		}
	)
	var errors: PackedStringArray = grid.validate()
	assert_true(_has(errors, "precisa começar com"), "alvo sem prefixo acusado")
	assert_true(_has(errors, "precisa ser 'power'"), "ação inválida acusada")


func test_validate_detects_missing_text() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "mudo",
			"title": "",
			"budget": 1,
			"initial": [],
			"systems": [
				{"id": "a", "name": "", "description": "", "cost": 1},
				_system("b", 1, []),
			],
		}
	)
	var errors: PackedStringArray = grid.validate()
	assert_true(_has(errors, "sem 'title'"), "título obrigatório")
	assert_true(_has(errors, "sem 'name'"), "nome obrigatório")
	assert_true(_has(errors, "sem 'description'"), "descrição obrigatória")


func test_effects_are_preserved() -> void:
	var grid: EnergyGrid = _sample()
	var effects: Array = grid.effects_of(&"node_door")
	assert_eq(effects.size(), 1, "um efeito")
	assert_eq(String((effects[0] as Dictionary)["target"]), "id:gh_node_door", "alvo")
	assert_eq((effects[0] as Dictionary)["action"], EnergyGrid.ACTION_POWER, "ação")


func test_goal_line_changes_when_met() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(_list(grid.goal_systems()), _text(["node_door"]), "sistema da meta")
	assert_false(grid.goal_met(), "meta pendente no início")
	assert_eq(grid.goal_line(), grid.goal_text, "texto pendente")
	grid.power_off(&"corridor_light")
	grid.power_on(&"node_door")
	assert_true(grid.goal_met(), "meta cumprida com a porta ligada")
	assert_eq(grid.goal_line(), grid.goal_done_text, "texto cumprido")


func test_tag_and_effect_off_are_data() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(grid.tag_of(&"node_door"), "META", "etiqueta do sistema da meta")
	assert_eq(grid.tag_of(&"heating"), "ROTA", "etiqueta comum")
	assert_eq(grid.effect_off_of(&"node_door"), "A comporta do Nó fecha.", "o que se perde")
	assert_eq(grid.tag_of(&"fantasma"), "", "sistema inexistente não tem etiqueta")


func test_validate_demands_goal() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "sem_meta",
			"title": "SEM META",
			"budget": 1,
			"initial": [],
			"systems": [_system("a", 1, []), _system("b", 1, [])],
		}
	)
	var errors: PackedStringArray = grid.validate()
	assert_true(_has(errors, "sem 'goal_text'"), "meta obrigatória")
	assert_true(_has(errors, "sem 'goal_done_text'"), "texto de meta cumprida obrigatório")
	assert_true(_has(errors, "sem 'goal_systems'"), "sistema da meta obrigatório")


func test_validate_detects_unknown_goal_system() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "meta_fantasma",
			"title": "META FANTASMA",
			"budget": 1,
			"goal_text": "Abrir algo",
			"goal_done_text": "Algo aberto",
			"goal_systems": ["fantasma"],
			"initial": [],
			"systems": [_system("a", 1, []), _system("b", 1, [])],
		}
	)
	assert_true(_has(grid.validate(), "meta 'fantasma' inexistente"), "meta inexistente acusada")


func test_validate_demands_tag_and_effect_off() -> void:
	var grid: EnergyGrid = EnergyGrid.from_dict(
		{
			"id": "sem_etiqueta",
			"title": "SEM ETIQUETA",
			"budget": 1,
			"goal_text": "Abrir a porta",
			"goal_done_text": "Porta aberta",
			"goal_systems": ["a"],
			"initial": [],
			"systems": [
				{"id": "a", "name": "A", "description": "Sistema A.", "cost": 1},
				_system("b", 1, []),
			],
		}
	)
	var errors: PackedStringArray = grid.validate()
	assert_true(_has(errors, "sistema 'a' sem 'tag'"), "etiqueta obrigatória")
	assert_true(_has(errors, "sistema 'a' sem 'effect_off'"), "consequência obrigatória")


func test_shutdown_candidates_lists_what_frees_the_budget() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(
		_list(grid.shutdown_candidates(&"node_door")),
		_text(["heating", "corridor_light"]),
		"qualquer um dos dois libera a porta"
	)


func test_shutdown_candidates_skips_own_dependency() -> void:
	var grid: EnergyGrid = _sample()
	assert_eq(
		_list(grid.shutdown_candidates(&"lift_platform")),
		_text(["corridor_light"]),
		"desligar o aquecimento não serve: o elevador depende dele"
	)


func test_shutdown_candidates_preserve_state() -> void:
	var grid: EnergyGrid = _sample()
	var before: PackedStringArray = _list(grid.powered())
	grid.shutdown_candidates(&"node_door")
	assert_eq(_list(grid.powered()), before, "a consulta não altera o estado")


func test_shutdown_candidates_only_when_budget_is_the_problem() -> void:
	var grid: EnergyGrid = _sample()
	grid.power_off(&"heating")
	assert_true(
		grid.shutdown_candidates(&"lift_platform").is_empty(),
		"faltando dependência, desligar não resolve"
	)
	assert_true(
		grid.shutdown_candidates(&"grow_light").is_empty(), "com orçamento livre não há troca"
	)
	assert_true(grid.shutdown_candidates(&"heating").is_empty(), "sistema desligado sem custo")


func _sample() -> EnergyGrid:
	return EnergyGrid.from_dict(
		{
			"id": "sample",
			"title": "AMOSTRA",
			"budget": 2,
			"goal_text": "Abrir a porta do Nó do Setor",
			"goal_done_text": "Porta do Nó do Setor aberta",
			"goal_systems": ["node_door"],
			"initial": ["heating", "corridor_light"],
			"systems": [
				_system("heating", 1, []),
				_system("corridor_light", 1, []),
				_system("grow_light", 1, []),
				_system("lift_platform", 1, ["heating"]),
				{
					"id": "node_door",
					"name": "PORTA",
					"tag": "META",
					"description": "Comporta da câmara do Nó.",
					"effect_off": "A comporta do Nó fecha.",
					"cost": 1,
					"requires": [],
					"effects": [{"target": "id:gh_node_door", "action": "power"}],
				},
			],
		}
	)


func _system(system_id: String, cost: int, requires: Array) -> Dictionary:
	return {
		"id": system_id,
		"name": _label(system_id),
		"tag": "ROTA",
		"description": "Sistema %s do setor." % system_id,
		"effect_off": "O sistema %s para." % system_id,
		"cost": cost,
		"requires": requires,
		"locked": false,
		"effects": [{"target": "group:%s" % system_id, "action": "power"}],
	}


func _label(system_id: String) -> String:
	match system_id:
		"heating":
			return "AQUECIMENTO"
		"corridor_light":
			return "ILUMINAÇÃO DO CORREDOR"
		"grow_light":
			return "LUZ DE CRESCIMENTO"
		"lift_platform":
			return "PLATAFORMA DE CARGA"
	return system_id.to_upper()


func _list(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	return result


func _text(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	return result


func _has(errors: PackedStringArray, fragment: String) -> bool:
	for message: String in errors:
		if message.contains(fragment):
			return true
	return false
