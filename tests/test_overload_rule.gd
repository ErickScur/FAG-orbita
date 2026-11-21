extends TestCase

const FULL: float = 100.0
const STEP: float = 0.5

var _rule: OverloadRule = null


func before_each() -> void:
	_rule = OverloadRule.new()
	_rule.begin()


func test_full_recharge_from_low_fires_once() -> void:
	var charge: float = 50.0
	var fired: int = 0
	while charge < FULL:
		var after: float = minf(FULL, charge + STEP)
		if _rule.feed(charge, after, FULL):
			fired += 1
		charge = after
	assert_eq(fired, 1, "uma SOBRECARGA ao completar")
	assert_true(_rule.has_fired(), "encaixe gasto")
	assert_false(_rule.feed(FULL, FULL, FULL), "parado em 100% não renova")


func test_standing_at_full_never_fires() -> void:
	for frame: int in range(600):
		assert_false(_rule.feed(FULL, FULL, FULL), "100% parado, quadro %d" % frame)
	assert_almost_eq(_rule.recharged(), 0.0, 0.0001, "nada recarregado")


func test_small_drain_refilled_does_not_count_as_full_recharge() -> void:
	var drain: float = Balance.FLASHLIGHT_DRAIN / 60.0
	assert_false(_rule.feed(FULL - drain, FULL, FULL), "lanterna drenando na doca")
	assert_false(_rule.has_fired(), "não gastou o encaixe")


func test_minimum_recharge_is_inclusive() -> void:
	var start: float = FULL - Balance.OVERLOAD_MIN_RECHARGE
	assert_true(_rule.feed(start, FULL, FULL), "exatamente o mínimo dispara")


func test_just_below_minimum_does_not_fire() -> void:
	var start: float = FULL - Balance.OVERLOAD_MIN_RECHARGE + 1.0
	assert_false(_rule.feed(start, FULL, FULL), "9 de Carga não bastam")


func test_new_docking_session_can_fire_again() -> void:
	assert_true(_rule.feed(80.0, FULL, FULL), "primeiro encaixe")
	assert_false(_rule.feed(80.0, FULL, FULL), "mesmo encaixe não repete")
	_rule.begin()
	assert_true(_rule.feed(80.0, FULL, FULL), "encaixe novo dispara")


func test_spending_inside_the_session_does_not_reset_it() -> void:
	assert_true(_rule.feed(70.0, FULL, FULL), "completa")
	assert_false(_rule.feed(FULL - Balance.DASH_COST, FULL, FULL), "dash e volta não renova")


func test_no_gain_while_corroded_never_fires() -> void:
	assert_false(_rule.feed(40.0, 40.0, FULL), "corrosão: Carga parada")
	assert_almost_eq(_rule.recharged(), 0.0, 0.0001, "nada somado")


func test_reaches_full_edges() -> void:
	assert_true(OverloadRule.reaches_full(99.0, 100.0, 100.0), "cruza o máximo")
	assert_false(OverloadRule.reaches_full(100.0, 100.0, 100.0), "já estava cheio")
	assert_false(OverloadRule.reaches_full(90.0, 99.0, 100.0), "ainda não chegou")
	assert_false(OverloadRule.reaches_full(0.0, 0.0, 0.0), "máximo zero")


func test_larger_charge_max_needs_the_new_maximum() -> void:
	var bigger: float = FULL + Balance.CAPACITOR_BONUS
	assert_false(_rule.feed(80.0, FULL, bigger), "100 de 125 não é cheio")
	assert_true(_rule.feed(FULL, bigger, bigger), "chega a 125")


func test_overload_speeds_up_walking() -> void:
	var statuses := StatusEffects.new()
	statuses.apply(StatusEffects.OVERLOAD)
	assert_almost_eq(
		FreezeRules.walk_speed(statuses.speed_multiplier()),
		Balance.WALK_SPEED * Balance.OVERLOAD_SPEED_MULT,
		0.001,
		"+30% de velocidade"
	)
	assert_false(statuses.blocks_abilities(), "buff não bloqueia nada")
	statuses.tick(Balance.OVERLOAD_TIME - 0.01)
	assert_true(statuses.has(StatusEffects.OVERLOAD), "dura quase 10 s")
	statuses.tick(0.02)
	assert_false(statuses.has(StatusEffects.OVERLOAD), "acaba aos 10 s")
	assert_almost_eq(statuses.speed_multiplier(), 1.0, 0.0001, "velocidade normal")


func test_discharge_blocks_abilities_for_its_time() -> void:
	var statuses := StatusEffects.new()
	statuses.apply(StatusEffects.DISCHARGE)
	assert_true(statuses.blocks_abilities(), "bloqueia")
	assert_false(
		DashLogic.can_use(100.0, Balance.DASH_COST, 0.0, statuses.blocks_abilities()), "dash"
	)
	assert_false(
		BeamLogic.can_fire(100.0, Balance.BEAM_COST, statuses.blocks_abilities()), "feixe"
	)
	assert_false(
		VacuumRules.can_thrust(true, statuses.blocks_abilities(), 100.0, Vector2.UP), "propulsor"
	)
	statuses.tick(Balance.DISCHARGE_TIME - 0.01)
	assert_true(statuses.blocks_abilities(), "ainda bloqueia antes de 3 s")
	statuses.tick(0.02)
	assert_false(statuses.blocks_abilities(), "libera aos 3 s")


func test_discharge_refreshed_on_a_live_floor_lasts_after_leaving() -> void:
	var statuses := StatusEffects.new()
	for frame: int in range(120):
		statuses.apply(StatusEffects.DISCHARGE)
		statuses.tick(1.0 / 60.0)
	var left: float = statuses.remaining(StatusEffects.DISCHARGE)
	assert_true(left > Balance.DISCHARGE_TIME - 0.05, "renovada enquanto pisa")
	statuses.tick(Balance.DISCHARGE_TIME)
	assert_false(statuses.has(StatusEffects.DISCHARGE), "vence 3 s depois de sair do piso")
