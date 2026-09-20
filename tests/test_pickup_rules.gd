extends TestCase

const FULL_CHARGE: float = 100.0
const LOW_CHARGE: float = 60.0
const FULL_INTEGRITY: int = 100
const LOW_INTEGRITY: int = 60
const HUD_TEXTS: String = "res://data/hud_texts.json"
const LEAKY_WORDS: PackedStringArray = ["opcional", "opcionais"]


func test_cell_blocked_when_charge_is_full() -> void:
	assert_false(
		PickupRules.can_collect(
			&"cell", FULL_CHARGE, FULL_CHARGE, FULL_INTEGRITY, FULL_INTEGRITY
		),
		"célula com carga cheia"
	)
	assert_true(
		PickupRules.can_collect(&"cell", LOW_CHARGE, FULL_CHARGE, FULL_INTEGRITY, FULL_INTEGRITY),
		"célula com carga baixa"
	)


func test_repair_kit_blocked_when_integrity_is_full() -> void:
	assert_false(
		PickupRules.can_collect(
			&"repair_kit", LOW_CHARGE, FULL_CHARGE, FULL_INTEGRITY, FULL_INTEGRITY
		),
		"kit com integridade cheia"
	)
	assert_true(
		PickupRules.can_collect(
			&"repair_kit", FULL_CHARGE, FULL_CHARGE, LOW_INTEGRITY, FULL_INTEGRITY
		),
		"kit com integridade baixa"
	)


func test_log_research_and_capacitor_are_always_collectable() -> void:
	for kind: StringName in [&"log", &"research", &"capacitor"]:
		assert_true(
			PickupRules.can_collect(
				kind, FULL_CHARGE, FULL_CHARGE, FULL_INTEGRITY, FULL_INTEGRITY
			),
			"tipo sempre coletável: %s" % kind
		)


func test_unknown_kind_is_never_collectable() -> void:
	assert_false(PickupRules.is_known(&"shield_plate"), "tipo desconhecido")
	assert_false(
		PickupRules.can_collect(&"shield_plate", 0.0, FULL_CHARGE, 0, FULL_INTEGRITY),
		"coleta de tipo desconhecido"
	)


func test_every_kind_has_its_own_sheet_row() -> void:
	var rows: Dictionary = {}
	assert_eq(PickupRules.KINDS.size(), 5, "cinco tipos")
	for kind: StringName in PickupRules.KINDS:
		var row: int = PickupRules.sheet_row(kind)
		assert_false(rows.has(row), "linha repetida para %s" % kind)
		assert_true(row >= 0 and row < 5, "linha dentro da folha para %s" % kind)
		rows[row] = kind


func test_sfx_by_kind() -> void:
	assert_eq(PickupRules.sfx_for(&"log"), &"log_pickup", "som do log")
	assert_eq(PickupRules.sfx_for(&"cell"), &"pickup", "som da célula")
	assert_eq(PickupRules.sfx_for(&"capacitor"), &"pickup", "som do capacitor")


func test_amount_for_mirrors_balance() -> void:
	assert_eq(PickupRules.amount_for(&"cell"), int(Balance.ENERGY_CELL_CHARGE), "célula")
	assert_eq(PickupRules.amount_for(&"repair_kit"), Balance.REPAIR_KIT_INTEGRITY, "kit")
	assert_eq(PickupRules.amount_for(&"capacitor"), int(Balance.CAPACITOR_BONUS), "capacitor")
	assert_eq(PickupRules.amount_for(&"log"), 0, "log não tem quantia")


func test_counts_toward_score() -> void:
	assert_true(PickupRules.counts_toward_score(&"log"), "log conta")
	assert_true(PickupRules.counts_toward_score(&"research"), "dado conta")
	assert_false(PickupRules.counts_toward_score(&"cell"), "célula não conta")


func test_default_item_id_is_stable() -> void:
	var first: StringName = PickupRules.default_item_id("greenhouse", &"research", Vector2i(28, 11))
	var again: StringName = PickupRules.default_item_id("greenhouse", &"research", Vector2i(28, 11))
	assert_eq(first, &"greenhouse_research_28_11", "formato do id")
	assert_eq(first, again, "mesmo id para a mesma célula")


func test_default_item_id_changes_with_cell_and_level() -> void:
	var base: StringName = PickupRules.default_item_id("greenhouse", &"cell", Vector2i(4, 5))
	assert_ne(
		base, PickupRules.default_item_id("greenhouse", &"cell", Vector2i(5, 5)), "outra coluna"
	)
	assert_ne(base, PickupRules.default_item_id("core_hub", &"cell", Vector2i(4, 5)), "outra fase")
	assert_ne(base, PickupRules.default_item_id("greenhouse", &"log", Vector2i(4, 5)), "outro tipo")


func test_level_builder_uses_the_same_default_id() -> void:
	assert_eq(
		LevelBuilder.default_item_id("greenhouse", &"cell", Vector2i(7, 3), {}),
		PickupRules.default_item_id("greenhouse", &"cell", Vector2i(7, 3)),
		"construtor delega para as regras"
	)
	assert_eq(
		LevelBuilder.default_item_id("greenhouse", &"log", Vector2i(7, 3), {"id": "log_gh_01"}),
		&"log_gh_01",
		"id explícito do JSON vence"
	)


func test_bob_constants_exist_in_balance() -> void:
	assert_true(Balance.PICKUP_BOB_AMPLITUDE > 0.0, "PICKUP_BOB_AMPLITUDE")
	assert_true(Balance.PICKUP_BOB_SPEED > 0.0, "PICKUP_BOB_SPEED")


func test_first_pickup_hints_do_not_say_the_pickup_is_skippable() -> void:
	var raw: String = FileAccess.get_file_as_string(HUD_TEXTS)
	var parsed: Variant = JSON.parse_string(raw)
	assert_true(parsed is Dictionary, "hud_texts.json carregou")
	if not (parsed is Dictionary):
		return
	var table: Dictionary = parsed
	for kind: StringName in PickupRules.KINDS:
		var hint: String = String(table.get(String(PickupRules.first_hint_id(kind)), ""))
		assert_false(hint.is_empty(), "explicação de %s existe" % kind)
		for word: String in LEAKY_WORDS:
			assert_false(
				hint.to_lower().contains(word),
				"explicação de %s não entrega que a coleta é dispensável" % kind
			)
