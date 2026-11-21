extends TestCase

const TILE: int = 16
const ENERGY_PATH: String = "res://data/energy/memory_core.json"


func test_rising_front_swallows_rows_from_the_bottom() -> void:
	var front := EraseFront.create(EraseFront.AXIS_UP, Rect2i(2, 2, 4, 6), 8, 3, TILE)
	assert_eq(front.swallowed_cells().size(), 0, "começa sem engolir nada")
	var previous: float = front.position
	front.advance(float(TILE))
	var fresh: Array[Vector2i] = front.newly_swallowed(previous)
	assert_eq(fresh.size(), 4, "uma linha inteira da região")
	for cell: Vector2i in fresh:
		assert_eq(cell.y, 7, "a linha de baixo some primeiro")
	assert_true(front.is_cell_swallowed(Vector2i(3, 7)), "célula engolida")
	assert_false(front.is_cell_swallowed(Vector2i(3, 6)), "a de cima ainda não")
	assert_false(front.is_cell_swallowed(Vector2i(9, 7)), "fora da região nunca some")


func test_rising_front_stops_at_its_limit() -> void:
	var front := EraseFront.create(EraseFront.AXIS_UP, Rect2i(0, 0, 3, 10), 10, 4, TILE)
	front.advance(10000.0)
	assert_almost_eq(front.position, 4.0 * TILE, 0.01, "para no limite")
	assert_true(front.is_done(), "terminou")
	assert_eq(front.swallowed_cells().size(), 18, "linhas 4 a 9")


func test_rising_front_catches_up_with_a_runaway_player() -> void:
	var front := EraseFront.create(EraseFront.AXIS_UP, Rect2i(0, 0, 10, 60), 60, 5, TILE)
	var feet := Vector2(80.0, 200.0)
	front.follow(feet, Balance.MEMORY_ASCENT_LEAD)
	assert_almost_eq(front.position, 200.0 + Balance.MEMORY_ASCENT_LEAD, 0.01, "colada atrás")
	front.follow(Vector2(80.0, 400.0), Balance.MEMORY_ASCENT_LEAD)
	assert_almost_eq(
		front.position, 200.0 + Balance.MEMORY_ASCENT_LEAD, 0.01, "nunca desce de volta"
	)


func test_static_hits_only_below_the_front_with_grace() -> void:
	var front := EraseFront.create(EraseFront.AXIS_UP, Rect2i(0, 0, 10, 20), 20, 2, TILE)
	front.position = 160.0
	var grace: float = Balance.MEMORY_HIT_GRACE
	assert_false(front.covers(Vector2(40.0, 159.0), grace), "acima da estática")
	assert_false(front.covers(Vector2(40.0, 160.0 + grace - 1.0), grace), "dentro da folga")
	assert_true(front.covers(Vector2(40.0, 160.0 + grace + 1.0), grace), "afundou na estática")
	assert_false(front.covers(Vector2(400.0, 300.0), grace), "fora da região")


func test_sweeping_front_eats_columns_left_to_right() -> void:
	var front := EraseFront.create(EraseFront.AXIS_RIGHT, Rect2i(10, 0, 10, 3), 10, 18, TILE)
	var previous: float = front.position
	front.advance(float(TILE) * 2.0)
	var fresh: Array[Vector2i] = front.newly_swallowed(previous)
	assert_eq(fresh.size(), 6, "duas colunas de três")
	assert_true(front.is_cell_swallowed(Vector2i(11, 1)), "coluna 11 sumiu")
	assert_false(front.is_cell_swallowed(Vector2i(12, 1)), "coluna 12 ainda existe")
	assert_true(front.covers(Vector2(170.0, 20.0), 0.0), "quem ficou para trás é pego")
	assert_false(front.covers(Vector2(220.0, 20.0), 0.0), "quem está à frente escapa")
	front.advance(10000.0)
	assert_almost_eq(front.position, 18.0 * TILE, 0.01, "para no limite")


func test_trailing_front_follows_a_player_walking_left() -> void:
	var front := EraseFront.create(EraseFront.AXIS_LEFT, Rect2i(0, 0, 40, 2), 40, 2, TILE)
	front.follow(Vector2(320.0, 10.0), Balance.RECALL_TRAIL)
	assert_almost_eq(front.position, 320.0 + Balance.RECALL_TRAIL, 0.01, "rastro atrás")
	assert_false(front.covers(Vector2(320.0 + Balance.RECALL_BACKSTEP, 10.0), 0.0), "não pega")
	front.reset()
	assert_almost_eq(front.position, 40.0 * TILE, 0.01, "reset volta ao começo")


func test_firewall_takes_the_last_cable_of_the_session() -> void:
	var logic := FirewallLogic.create(&"luto", Balance.FIREWALL_SWAP_DELAY)
	logic.begin_session()
	logic.note_change(&"hall_door", true)
	logic.note_change(&"walkway", true)
	logic.note_change(&"party_lights", true)
	assert_eq(logic.end_session(), &"party_lights", "o último cabo ligado")
	assert_eq(logic.tick(Balance.FIREWALL_SWAP_DELAY * 0.5), &"", "ainda avisando")
	assert_eq(logic.tick(Balance.FIREWALL_SWAP_DELAY), &"party_lights", "troca depois do aviso")
	assert_eq(logic.pending(), &"", "nada pendente")


func test_firewall_ignores_switching_off_and_its_own_moves() -> void:
	var logic := FirewallLogic.create(&"luto", Balance.FIREWALL_SWAP_DELAY)
	logic.begin_session()
	logic.note_change(&"walkway", true)
	logic.note_change(&"party_lights", true)
	logic.note_change(&"party_lights", false)
	logic.note_change(&"luto", true)
	assert_eq(logic.end_session(), &"walkway", "religar e desligar não conta; o luto não conta")
	logic.begin_session()
	logic.note_change(&"hall_door", false)
	assert_eq(logic.end_session(), &"", "só desligar não provoca troca")
	logic.begin_session()
	logic.begin_acting()
	logic.note_change(&"walkway", true)
	logic.end_acting()
	assert_eq(logic.end_session(), &"", "a troca do próprio firewall não conta")
	logic.note_change(&"walkway", true)
	assert_eq(logic.end_session(), &"", "fora de sessão não conta")


func test_swap_plan_moves_the_unit_to_the_protocol() -> void:
	var grid: EnergyGrid = _grid()
	assert_not_null(grid, "terminal da Memória")
	if grid == null:
		return
	grid.set_state([&"hall_door", &"walkway", &"party_lights"])
	var plan: Array[StringName] = FirewallLogic.swap_plan(grid, &"party_lights", &"luto")
	assert_eq(plan, [&"party_lights", &"luto"] as Array[StringName], "desliga e liga o luto")
	assert_eq(grid.get_state().size(), 3, "o plano não mexe na grade")
	grid.set_state([&"hall_door", &"walkway", &"luto"])
	plan = FirewallLogic.swap_plan(grid, &"walkway", &"luto")
	assert_eq(plan, [&"walkway"] as Array[StringName], "luto já ligado: só derruba")
	assert_eq(FirewallLogic.swap_plan(grid, &"party_lights", &"luto").size(), 0, "desligado")
	assert_eq(FirewallLogic.swap_plan(grid, &"luto", &"luto").size(), 0, "nunca troca o luto")


func test_recall_opens_lines_as_the_player_walks() -> void:
	var recall := RecallLogic.create(1000.0, 200.0, 5)
	assert_almost_eq(recall.direction(), -1.0, 0.001, "anda para a esquerda")
	assert_false(recall.next_line_ready(1010.0, true), "antes do começo")
	assert_true(recall.next_line_ready(1000.0, true), "primeira linha no começo")
	assert_eq(recall.open_next(), 0, "linha 0")
	assert_false(recall.next_line_ready(700.0, false), "espera a linha terminar de digitar")
	assert_false(recall.next_line_ready(850.0, true), "ainda não chegou na marca da 2a")
	assert_true(recall.next_line_ready(800.0, true), "marca da 2a")
	for index: int in range(1, 5):
		assert_eq(recall.open_next(), index, "linha %d" % index)
	assert_true(recall.is_complete(), "log inteiro")
	assert_eq(recall.open_next(), -1, "nada depois do fim")


func test_recall_push_never_undoes_an_opened_line() -> void:
	var recall := RecallLogic.create(1000.0, 200.0, 5)
	recall.open_next()
	recall.open_next()
	var limit: float = recall.back_limit()
	assert_almost_eq(limit, 800.0 + Balance.RECALL_BACKSTEP, 0.01, "recua até perto da linha")
	var step: float = recall.push_step(780.0, 0.1)
	assert_true(step > 0.0, "empurra para trás (direita)")
	assert_true(recall.is_kicking(), "linha nova dá um tranco")
	assert_almost_eq(recall.push_step(limit, 0.1), 0.0, 0.001, "no limite não empurra mais")
	assert_almost_eq(
		recall.push_step(limit - 1.0, 1.0), 1.0, 0.001, "corta o passo no limite"
	)
	recall.tick(Balance.RECALL_FLASH_TIME)
	assert_false(recall.is_kicking(), "tranco acaba")
	assert_almost_eq(
		recall.push_step(700.0, 1.0), Balance.RECALL_PUSH_SPEED, 0.001, "empuxo constante"
	)
	assert_true(Balance.RECALL_PUSH_SPEED < Balance.WALK_SPEED, "andando sempre se avança")


func test_protocol_walks_the_three_phases_in_order() -> void:
	var protocol := MemoryProtocol.create(0, false)
	assert_eq(protocol.phase, MemoryProtocol.Phase.DORMANT, "começa dormente")
	assert_false(protocol.try_start(false), "fora do gatilho")
	assert_true(protocol.try_start(true), "entra no poço")
	assert_eq(protocol.phase, MemoryProtocol.Phase.ASCENT, "fase 1")
	assert_almost_eq(protocol.desaturation(), Balance.MEMORY_DESAT_ASCENT, 0.001, "cor cai")
	assert_eq(protocol.complete_current(), 1, "fase 1 feita")
	assert_true(protocol.try_start(true), "arena")
	assert_eq(protocol.phase, MemoryProtocol.Phase.FIREWALL, "fase 2")
	protocol.complete_current()
	assert_true(protocol.try_start(true), "corredor")
	assert_eq(protocol.phase, MemoryProtocol.Phase.RECALL, "fase 3")
	assert_almost_eq(protocol.desaturation(), Balance.MEMORY_DESAT_RECALL, 0.001, "quase cinza")
	protocol.complete_current()
	assert_true(protocol.awaits_node(), "falta o Nó")
	assert_false(protocol.try_start(true), "não há fase 4")
	protocol.finish()
	assert_true(protocol.is_done(), "religado")
	assert_almost_eq(protocol.desaturation(), 0.0, 0.001, "cor de volta")
	assert_eq(protocol.ambient_key(), "restored", "ambiente religado")


func test_hit_aborts_the_phase_without_losing_progress() -> void:
	var protocol := MemoryProtocol.create(1, false)
	var erased: Array = protocol.phases_already_erased()
	assert_eq(erased.size(), 1, "só o poço já apagado")
	assert_eq(int(erased[0]), int(MemoryProtocol.Phase.ASCENT), "o poço")
	assert_true(protocol.try_start(true), "arena")
	assert_eq(protocol.abort_current(), MemoryProtocol.Phase.FIREWALL, "abortou a fase 2")
	assert_eq(protocol.phase, MemoryProtocol.Phase.DORMANT, "espera o gatilho de novo")
	assert_eq(protocol.completed, 1, "a fase 1 continua feita")
	assert_true(protocol.try_start(true), "recomeça a fase 2")
	assert_eq(protocol.phase, MemoryProtocol.Phase.FIREWALL, "de novo a fase 2")


func test_saved_progress_and_restored_sector() -> void:
	assert_eq(MemoryProtocol.saved_progress({}), 0, "sem flag")
	assert_eq(MemoryProtocol.saved_progress({MemoryProtocol.FLAG_KEY: 2}), 2, "flag salva")
	assert_eq(MemoryProtocol.saved_progress({MemoryProtocol.FLAG_KEY: 9}), 3, "limitada")
	var restored := MemoryProtocol.create(1, true)
	assert_true(restored.is_done(), "setor religado não roda o protocolo")
	assert_eq(restored.phases_already_erased().size(), 0, "nada apagado na revisita")
	assert_false(restored.try_start(true), "nem recomeça")


func _grid() -> EnergyGrid:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_PATH))
	return EnergyGrid.from_dict(raw) if raw is Dictionary else null
