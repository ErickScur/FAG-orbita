extends TestCase

var _statuses: StatusEffects = null


func before_each() -> void:
	_statuses = StatusEffects.new()


func test_defines_the_five_gdd_statuses() -> void:
	assert_eq(StatusEffects.ORDER.size(), 5, "cinco status")
	for status_id: StringName in StatusEffects.ORDER:
		assert_true(StatusEffects.is_known(status_id), "definido: %s" % status_id)
		assert_false(StatusEffects.definition(status_id).is_empty(), "ficha de %s" % status_id)
	assert_false(StatusEffects.is_known(&"rust"), "status inventado")


func test_definitions_mirror_balance() -> void:
	assert_almost_eq(
		StatusEffects.default_duration(StatusEffects.CORROSION),
		Balance.CORROSION_TIME,
		0.0001,
		"duração da corrosão"
	)
	assert_almost_eq(
		StatusEffects.default_duration(StatusEffects.DISCHARGE),
		Balance.DISCHARGE_TIME,
		0.0001,
		"duração da descarga"
	)
	assert_almost_eq(
		StatusEffects.default_duration(StatusEffects.OVERLOAD),
		Balance.OVERLOAD_TIME,
		0.0001,
		"duração da sobrecarga"
	)


func test_exposure_statuses_use_the_grace_window() -> void:
	assert_true(StatusEffects.lasts_while_exposed(StatusEffects.OVERHEAT), "superaquecimento")
	assert_true(StatusEffects.lasts_while_exposed(StatusEffects.FREEZE), "congelamento")
	assert_false(StatusEffects.lasts_while_exposed(StatusEffects.CORROSION), "corrosão")
	assert_almost_eq(
		StatusEffects.default_duration(StatusEffects.OVERHEAT),
		Balance.STATUS_EXPOSURE_GRACE,
		0.0001,
		"janela de exposição"
	)


func test_corrosion_expires_after_balance_time() -> void:
	assert_true(_statuses.apply(StatusEffects.CORROSION), "aplicação nova")
	assert_almost_eq(
		_statuses.remaining(StatusEffects.CORROSION),
		Balance.CORROSION_TIME,
		0.0001,
		"tempo restante"
	)
	var expired: Array[StringName] = _statuses.tick(Balance.CORROSION_TIME)
	assert_eq(expired.size(), 1, "um status expirado")
	assert_eq(expired[0], StatusEffects.CORROSION, "id expirado")
	assert_false(_statuses.has(StatusEffects.CORROSION), "corrosão ativa")


func test_reapply_refreshes_and_returns_false() -> void:
	_statuses.apply(StatusEffects.CORROSION)
	_statuses.tick(3.0)
	assert_almost_eq(
		_statuses.remaining(StatusEffects.CORROSION),
		Balance.CORROSION_TIME - 3.0,
		0.0001,
		"tempo consumido"
	)
	assert_false(_statuses.apply(StatusEffects.CORROSION), "reaplicação não é nova")
	assert_almost_eq(
		_statuses.remaining(StatusEffects.CORROSION),
		Balance.CORROSION_TIME,
		0.0001,
		"tempo renovado"
	)


func test_refresh_never_shortens_the_timer() -> void:
	_statuses.apply(StatusEffects.CORROSION)
	_statuses.apply(StatusEffects.CORROSION, 1.0)
	assert_almost_eq(
		_statuses.remaining(StatusEffects.CORROSION),
		Balance.CORROSION_TIME,
		0.0001,
		"duração menor não encurta"
	)


func test_unknown_status_is_never_applied() -> void:
	assert_false(_statuses.apply(&"rust"), "status desconhecido")
	assert_true(_statuses.is_empty(), "nada ativo")


func test_corrosion_blocks_charge_gain() -> void:
	assert_false(_statuses.blocks_charge_gain(), "sem status")
	_statuses.apply(StatusEffects.OVERLOAD)
	assert_false(_statuses.blocks_charge_gain(), "sobrecarga não bloqueia")
	_statuses.apply(StatusEffects.CORROSION)
	assert_true(_statuses.blocks_charge_gain(), "corrosão bloqueia")
	_statuses.clear(StatusEffects.CORROSION)
	assert_false(_statuses.blocks_charge_gain(), "corrosão removida")


func test_discharge_blocks_abilities() -> void:
	assert_false(_statuses.blocks_abilities(), "sem status")
	_statuses.apply(StatusEffects.DISCHARGE)
	assert_true(_statuses.blocks_abilities(), "descarga bloqueia habilidades")


func test_freeze_multipliers() -> void:
	_statuses.apply(StatusEffects.FREEZE)
	assert_almost_eq(
		_statuses.speed_multiplier(), Balance.FREEZE_SPEED_MULT, 0.0001, "velocidade"
	)
	assert_almost_eq(_statuses.jump_multiplier(), Balance.FREEZE_JUMP_MULT, 0.0001, "pulo")
	assert_true(_statuses.is_slippery(), "piso escorregadio")


func test_overload_and_freeze_multiply() -> void:
	_statuses.apply(StatusEffects.FREEZE)
	_statuses.apply(StatusEffects.OVERLOAD)
	assert_almost_eq(
		_statuses.speed_multiplier(),
		Balance.FREEZE_SPEED_MULT * Balance.OVERLOAD_SPEED_MULT,
		0.0001,
		"produto dos multiplicadores"
	)


func test_overheat_dps_and_drain() -> void:
	assert_almost_eq(_statuses.integrity_dps(), 0.0, 0.0001, "sem dano")
	assert_almost_eq(_statuses.charge_drain_multiplier(), 1.0, 0.0001, "sem dreno extra")
	_statuses.apply(StatusEffects.OVERHEAT)
	assert_almost_eq(_statuses.integrity_dps(), Balance.OVERHEAT_DPS, 0.0001, "dano por segundo")
	assert_almost_eq(
		_statuses.charge_drain_multiplier(), Balance.OVERHEAT_CHARGE_MULT, 0.0001, "dreno"
	)


func test_exposure_status_needs_refresh() -> void:
	_statuses.apply(StatusEffects.OVERHEAT)
	var expired: Array[StringName] = _statuses.tick(Balance.STATUS_EXPOSURE_GRACE)
	assert_eq(expired.size(), 1, "expira sem renovação")
	assert_false(_statuses.has(StatusEffects.OVERHEAT), "superaquecimento ativo")


func test_active_ids_follow_gdd_order() -> void:
	_statuses.apply(StatusEffects.OVERLOAD)
	_statuses.apply(StatusEffects.CORROSION)
	_statuses.apply(StatusEffects.FREEZE)
	var ids: Array[StringName] = _statuses.active_ids()
	assert_eq(ids.size(), 3, "três ativos")
	assert_eq(ids[0], StatusEffects.CORROSION, "primeiro")
	assert_eq(ids[1], StatusEffects.FREEZE, "segundo")
	assert_eq(ids[2], StatusEffects.OVERLOAD, "terceiro")


func test_tick_expires_only_what_ended() -> void:
	_statuses.apply(StatusEffects.CORROSION)
	_statuses.apply(StatusEffects.DISCHARGE)
	var expired: Array[StringName] = _statuses.tick(Balance.DISCHARGE_TIME)
	assert_eq(expired.size(), 1, "só a descarga")
	assert_eq(expired[0], StatusEffects.DISCHARGE, "id")
	assert_true(_statuses.has(StatusEffects.CORROSION), "corrosão continua")


func test_clear_all_returns_nothing_active() -> void:
	_statuses.apply(StatusEffects.CORROSION)
	_statuses.apply(StatusEffects.DISCHARGE)
	var cleared: Array[StringName] = _statuses.clear_all()
	assert_eq(cleared.size(), 2, "dois limpos")
	assert_true(_statuses.is_empty(), "nada ativo")
	assert_false(_statuses.blocks_charge_gain(), "sem bloqueio")


func test_hud_has_an_icon_for_every_status() -> void:
	var seen: Dictionary = {}
	for status_id: StringName in StatusEffects.ORDER:
		assert_true(HudModel.STATUS_ICONS.has(status_id), "ícone de %s" % status_id)
		var index: int = HudModel.status_icon_index(status_id)
		assert_false(seen.has(index), "ícone repetido em %s" % status_id)
		seen[index] = status_id
