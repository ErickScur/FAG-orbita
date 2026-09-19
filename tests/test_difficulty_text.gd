extends TestCase


func test_easy_uses_balance_multipliers() -> void:
	assert_eq(
		DifficultyText.describe(&"easy"),
		"Dano recebido 50% · Reator cai 50% mais devagar",
		"fácil"
	)


func test_normal_says_original_values() -> void:
	assert_eq(DifficultyText.describe(&"normal"), "Valores originais do jogo", "normal")


func test_hard_uses_balance_multipliers() -> void:
	assert_eq(
		DifficultyText.describe(&"hard"),
		"Dano recebido 150% · Reator cai 50% mais rápido",
		"difícil"
	)


func test_unknown_difficulty_falls_back_to_normal() -> void:
	assert_eq(DifficultyText.describe(&"impossivel"), "Valores originais do jogo", "desconhecida")


func test_describe_follows_balance_numbers() -> void:
	for difficulty: StringName in [&"easy", &"normal", &"hard"]:
		var damage: int = roundi(Balance.difficulty_damage_multiplier(difficulty) * 100.0)
		var text: String = DifficultyText.describe(difficulty)
		if difficulty == &"normal":
			assert_false(text.contains("%"), "normal sem porcentagem")
		else:
			assert_true(text.contains("%d%%" % damage), "dano de %s" % difficulty)


func test_no_timer_hint() -> void:
	assert_eq(
		DifficultyText.no_timer_hint(),
		"O reator não perde estabilidade com o tempo",
		"dica do modo sem timer"
	)
