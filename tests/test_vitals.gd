extends TestCase

const STEP: float = 1.0 / 60.0


func test_scale_damage_normal() -> void:
	assert_eq(Vitals.scale_damage(10, 1.0), 10, "dano normal")


func test_scale_damage_easy_hard() -> void:
	assert_eq(Vitals.scale_damage(10, 0.5), 5, "fácil")
	assert_eq(Vitals.scale_damage(10, 1.5), 15, "difícil")
	assert_eq(Vitals.scale_damage(5, 1.5), 8, "arredonda para cima")


func test_scale_damage_never_zero() -> void:
	assert_eq(Vitals.scale_damage(1, 0.5), 1, "dano mínimo de 1")
	assert_eq(Vitals.scale_damage(0, 1.0), 0, "sem dano")
	assert_eq(Vitals.scale_damage(-5, 1.0), 0, "dano negativo")
	assert_eq(Vitals.scale_damage(10, 0.0), 0, "multiplicador zero")


func test_scale_damage_uses_balance_multipliers() -> void:
	var damage: int = Balance.SR3_CONTACT_DAMAGE
	var easy: int = Vitals.scale_damage(damage, Balance.difficulty_damage_multiplier(&"easy"))
	var normal: int = Vitals.scale_damage(damage, Balance.difficulty_damage_multiplier(&"normal"))
	var hard: int = Vitals.scale_damage(damage, Balance.difficulty_damage_multiplier(&"hard"))
	assert_eq(easy, 5, "SR-3 no fácil")
	assert_eq(normal, 10, "SR-3 no normal")
	assert_eq(hard, 15, "SR-3 no difícil")


func test_cell_states() -> void:
	assert_eq(Vitals.cell_states(100, 100, 4), [2, 2, 2, 2] as Array[int], "cheia")
	assert_eq(Vitals.cell_states(60, 100, 4), [2, 2, 1, 0] as Array[int], "parcial")
	assert_eq(Vitals.cell_states(0, 100, 4), [0, 0, 0, 0] as Array[int], "vazia")
	assert_eq(Vitals.cell_states(25, 100, 4), [2, 0, 0, 0] as Array[int], "uma célula")


func test_cell_states_invalid() -> void:
	assert_eq(Vitals.cell_states(50, 100, 0).size(), 0, "sem células")
	assert_eq(Vitals.cell_states(50, 0, 4).size(), 0, "sem máximo")


func test_cell_states_matches_balance() -> void:
	var states: Array[int] = Vitals.cell_states(
		Balance.INTEGRITY_MAX, Balance.INTEGRITY_MAX, Balance.INTEGRITY_CELLS
	)
	assert_eq(states.size(), Balance.INTEGRITY_CELLS, "quantidade de células")
	for state: int in states:
		assert_eq(state, Vitals.FULL_CELL, "célula cheia")


func test_respawn_integrity() -> void:
	assert_eq(Vitals.respawn_integrity(100, 0.5), 50, "metade de 100")
	assert_eq(Vitals.respawn_integrity(125, 0.5), 63, "metade de 125")
	assert_eq(Vitals.respawn_integrity(1, 0.5), 1, "nunca zero")
	assert_eq(Vitals.respawn_integrity(100, 2.0), 100, "nunca acima do máximo")


func test_respawn_integrity_from_balance() -> void:
	var value: int = Vitals.respawn_integrity(
		Balance.INTEGRITY_MAX, Balance.RESPAWN_INTEGRITY_RATIO
	)
	assert_eq(value, 50, "50% do chassi")


func test_respawn_charge() -> void:
	var value: float = Vitals.respawn_charge(Balance.CHARGE_MAX, Balance.RESPAWN_CHARGE_RATIO)
	assert_almost_eq(value, Balance.CHARGE_MAX, 0.0001, "carga cheia no respawn")


func test_accumulate_dps() -> void:
	var accumulator: float = 0.0
	var dealt: int = 0
	for index: int in range(60):
		var result: Vector2 = Vitals.accumulate(accumulator, Balance.SPORE_DPS, STEP)
		accumulator = result.y
		dealt += int(result.x)
	assert_almost_eq(float(dealt) + accumulator, 5.0, 0.001, "1 s de 5 pts/s")
	assert_true(dealt >= 4 and dealt <= 5, "dano inteiro aplicado (%d)" % dealt)
	assert_true(accumulator < 1.0, "resto sempre menor que 1")


func test_accumulate_two_seconds() -> void:
	var accumulator: float = 0.0
	var dealt: int = 0
	for index: int in range(120):
		var result: Vector2 = Vitals.accumulate(accumulator, 5.0, STEP)
		accumulator = result.y
		dealt += int(result.x)
	assert_true(dealt >= 9 and dealt <= 10, "2 s de 5 pts/s (%d)" % dealt)


func test_accumulate_ignores_negatives() -> void:
	var result: Vector2 = Vitals.accumulate(0.0, -5.0, STEP)
	assert_almost_eq(result.x, 0.0, 0.0001, "sem dano")
	assert_almost_eq(result.y, 0.0, 0.0001, "sem resto")


func test_clamp_add() -> void:
	assert_almost_eq(Vitals.clamp_add(90.0, 40.0, 100.0), 100.0, 0.0001, "satura")
	assert_almost_eq(Vitals.clamp_add(10.0, -30.0, 100.0), 0.0, 0.0001, "piso")
	assert_almost_eq(Vitals.clamp_add(10.0, 5.0, 100.0), 15.0, 0.0001, "soma simples")
