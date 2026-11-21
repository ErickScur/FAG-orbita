extends TestCase

const ORIGIN: Vector2 = Vector2(100.0, 100.0)


func test_pick_nearest() -> void:
	var positions := PackedVector2Array([
		Vector2(140.0, 100.0), Vector2(110.0, 100.0), Vector2(180.0, 100.0)
	])
	var enabled := PackedInt32Array([1, 1, 1])
	var priorities := PackedInt32Array([0, 0, 0])
	assert_eq(InteractionRules.pick_index(positions, enabled, priorities, ORIGIN), 1, "mais perto")


func test_pick_ignores_disabled() -> void:
	var positions := PackedVector2Array([Vector2(105.0, 100.0), Vector2(130.0, 100.0)])
	var enabled := PackedInt32Array([0, 1])
	var priorities := PackedInt32Array([0, 0])
	assert_eq(InteractionRules.pick_index(positions, enabled, priorities, ORIGIN), 1, "ignora off")


func test_priority_beats_distance() -> void:
	var positions := PackedVector2Array([Vector2(105.0, 100.0), Vector2(160.0, 100.0)])
	var enabled := PackedInt32Array([1, 1])
	var priorities := PackedInt32Array([0, 1])
	assert_eq(InteractionRules.pick_index(positions, enabled, priorities, ORIGIN), 1, "prioridade")


func test_priority_keeps_nearest_on_tie() -> void:
	var positions := PackedVector2Array([
		Vector2(160.0, 100.0), Vector2(120.0, 100.0), Vector2(105.0, 100.0)
	])
	var enabled := PackedInt32Array([1, 1, 1])
	var priorities := PackedInt32Array([2, 2, 0])
	assert_eq(InteractionRules.pick_index(positions, enabled, priorities, ORIGIN), 1, "empate")


func test_pick_none() -> void:
	var empty := PackedVector2Array()
	assert_eq(
		InteractionRules.pick_index(empty, PackedInt32Array(), PackedInt32Array(), ORIGIN),
		-1,
		"lista vazia"
	)
	var positions := PackedVector2Array([Vector2(105.0, 100.0)])
	assert_eq(
		InteractionRules.pick_index(
			positions, PackedInt32Array([0]), PackedInt32Array([0]), ORIGIN
		),
		-1,
		"tudo desabilitado"
	)


func test_pick_without_priorities() -> void:
	var positions := PackedVector2Array([Vector2(160.0, 100.0), Vector2(120.0, 100.0)])
	var enabled := PackedInt32Array([1, 1])
	assert_eq(
		InteractionRules.pick_index(positions, enabled, PackedInt32Array(), ORIGIN),
		1,
		"prioridade ausente vale zero"
	)


func test_prompt_format() -> void:
	assert_eq(
		InteractionRules.prompt("[E]", "ACESSAR TERMINAL"), "[E] ACESSAR TERMINAL", "formato"
	)
	assert_eq(InteractionRules.prompt("[E]", ""), "", "sem texto")
	assert_eq(InteractionRules.prompt("", "EXAMINAR"), "EXAMINAR", "sem glifo")


func test_glyph_by_device() -> void:
	assert_eq(InteractionRules.glyph(false), "[E]", "teclado")
	assert_eq(InteractionRules.glyph(true), "[X]", "controle")


func test_inert_prompt_shows_the_state_without_the_key() -> void:
	assert_eq(
		InteractionRules.prompt("[E]", "PORTA SELADA", false), "PORTA SELADA", "sem [E]"
	)
	assert_eq(InteractionRules.prompt("[E]", "ACESSO ROOT", true), "[E] ACESSO ROOT", "com [E]")


func test_inert_interactable_never_beats_one_that_acts() -> void:
	assert_eq(
		InteractionRules.effective_priority(InteractionRules.PRIORITY_GATE, false),
		InteractionRules.PRIORITY_INERT,
		"porta sem Root vira só informação"
	)
	var positions := PackedVector2Array([Vector2(101.0, 100.0), Vector2(150.0, 100.0)])
	var enabled := PackedInt32Array([1, 1])
	var priorities := PackedInt32Array([
		InteractionRules.effective_priority(0, false),
		InteractionRules.effective_priority(0, true),
	])
	assert_eq(InteractionRules.pick_index(positions, enabled, priorities, ORIGIN), 1, "age vence")


func test_inert_interactable_does_not_emit() -> void:
	var item := Interactable.new()
	var calls: Array[int] = [0]
	item.interacted.connect(func(_actor: Node) -> void: calls[0] += 1)
	item.set_actionable(false)
	item.interact(null)
	assert_eq(calls[0], 0, "inerte não reage")
	assert_eq(item.prompt_with("[E]"), "INTERAGIR", "mostra só o estado")
	item.set_actionable(true)
	item.interact(null)
	assert_eq(calls[0], 1, "ativo reage")
	assert_eq(item.prompt_with("[E]"), "[E] INTERAGIR", "com a tecla")
	item.free()


func test_interaction_texts_live_in_data() -> void:
	for id: StringName in [
		&"door_root", &"door_sealed", &"door_root_missing", &"coupler_charge",
		&"coupler_sealed", &"root_coupler_unfed", &"root_coupler_ready",
		&"root_coupler_no_root", &"root_coupler_charging", &"root_coupler_done",
		&"terminal_console", &"terminal_node", &"terminal_node_done", &"terminal_no_power",
	]:
		assert_false(InteractionRules.text(id).is_empty(), "texto %s" % id)
	assert_eq(InteractionRules.text(&"door_sealed"), "PORTA SELADA", "pt-BR do JSON")


func test_prompt_sits_above_the_head_and_inside_the_screen() -> void:
	var screen := Vector2(384.0, 216.0)
	var size := Vector2(120.0, 18.0)
	var middle: Vector2 = InteractionRules.prompt_position(Vector2(192.0, 140.0), size, screen)
	assert_eq(middle, Vector2(132.0, 82.0), "centrado 40 px acima do pé")
	assert_true(middle.y + size.y <= 140.0 - 32.0, "não cobre o MU-7 (32 px)")
	var corner: Vector2 = InteractionRules.prompt_position(Vector2(380.0, 200.0), size, screen)
	assert_eq(corner.x, screen.x - InteractionRules.PROMPT_MARGIN - size.x, "preso à direita")
	var left: Vector2 = InteractionRules.prompt_position(Vector2(2.0, 200.0), size, screen)
	assert_eq(left.x, InteractionRules.PROMPT_MARGIN, "preso à esquerda")
	var top: Vector2 = InteractionRules.prompt_position(Vector2(192.0, 70.0), size, screen)
	assert_eq(top.y, 70.0 + InteractionRules.PROMPT_FOOT_GAP, "sem espaço em cima: vai para baixo")
	for anchor: Vector2 in [
		Vector2(0.0, 0.0), Vector2(384.0, 216.0), Vector2(-50.0, 300.0), Vector2(192.0, 60.0)
	]:
		var spot: Vector2 = InteractionRules.prompt_position(anchor, size, screen)
		assert_true(spot.x >= 0.0 and spot.x + size.x <= screen.x, "dentro na horizontal")
		assert_true(
			spot.y >= InteractionRules.PROMPT_TOP_LIMIT and spot.y + size.y <= screen.y,
			"abaixo da faixa da HUD e dentro da tela"
		)


func test_accept_glyph_follows_the_device() -> void:
	assert_eq(InteractionRules.accept_glyph(false), "[ENTER]", "teclado")
	assert_eq(InteractionRules.accept_glyph(true), "[A]", "controle")
	var pad := InputEventJoypadButton.new()
	InteractionRules.note_device(pad)
	assert_true(InteractionRules.using_joypad(), "último aperto foi no controle")
	var key := InputEventKey.new()
	InteractionRules.note_device(key)
	assert_false(InteractionRules.using_joypad(), "voltou ao teclado")
