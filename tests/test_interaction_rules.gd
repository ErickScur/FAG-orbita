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
