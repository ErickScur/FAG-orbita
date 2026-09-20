extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"
const HALF_CHARGE: float = 50.0

var _state: Node = null
var _applied: Array = []
var _cleared: Array = []


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()
	_state.new_game()
	_applied = []
	_cleared = []
	EventBus.status_applied.connect(_on_status_applied)
	EventBus.status_cleared.connect(_on_status_cleared)


func after_each() -> void:
	EventBus.status_applied.disconnect(_on_status_applied)
	EventBus.status_cleared.disconnect(_on_status_cleared)
	if _state != null:
		_state.free()
		_state = null


func test_apply_status_announces_the_icon() -> void:
	assert_true(_state.apply_status(StatusEffects.CORROSION), "aplicação nova")
	assert_eq(_applied.size(), 1, "um aviso")
	assert_eq(StringName(_applied[0]["id"]), StatusEffects.CORROSION, "id avisado")
	assert_almost_eq(
		float(_applied[0]["duration"]), Balance.CORROSION_TIME, 0.0001, "duração avisada"
	)


func test_reapply_refreshes_the_hud_counter() -> void:
	_state.apply_status(StatusEffects.CORROSION)
	_state.statuses.tick(2.0)
	assert_false(_state.apply_status(StatusEffects.CORROSION), "renovação não é nova")
	assert_eq(_applied.size(), 2, "dois avisos")
	assert_almost_eq(
		float(_applied[1]["duration"]), Balance.CORROSION_TIME, 0.0001, "contador renovado"
	)


func test_unknown_status_is_ignored() -> void:
	assert_false(_state.apply_status(&"rust"), "status desconhecido")
	assert_eq(_applied.size(), 0, "sem aviso")


func test_corrosion_blocks_charge_gain() -> void:
	_state.charge = HALF_CHARGE
	_state.apply_status(StatusEffects.CORROSION)
	_state.add_charge(Balance.ENERGY_CELL_CHARGE)
	assert_almost_eq(_state.charge, HALF_CHARGE, 0.0001, "carga travada")
	_state.clear_status(StatusEffects.CORROSION)
	_state.add_charge(Balance.ENERGY_CELL_CHARGE)
	assert_almost_eq(
		_state.charge, HALF_CHARGE + Balance.ENERGY_CELL_CHARGE, 0.0001, "carga liberada"
	)


func test_corrosion_does_not_block_repair() -> void:
	_state.integrity = 40
	_state.apply_status(StatusEffects.CORROSION)
	_state.repair(Balance.REPAIR_KIT_INTEGRITY)
	assert_eq(_state.integrity, 40 + Balance.REPAIR_KIT_INTEGRITY, "reparo continua valendo")


func test_clear_status_announces_once() -> void:
	_state.apply_status(StatusEffects.CORROSION)
	_state.clear_status(StatusEffects.CORROSION)
	_state.clear_status(StatusEffects.CORROSION)
	assert_eq(_cleared.size(), 1, "um único aviso")
	assert_eq(StringName(_cleared[0]), StatusEffects.CORROSION, "id limpo")


func test_new_game_clears_every_status() -> void:
	_state.apply_status(StatusEffects.CORROSION)
	_state.apply_status(StatusEffects.DISCHARGE)
	_state.new_game()
	assert_true(_state.statuses.is_empty(), "sem status")
	assert_eq(_cleared.size(), 2, "avisou os dois")


func test_load_clears_every_status() -> void:
	_state.apply_status(StatusEffects.CORROSION)
	_state.from_dict(_state.to_dict())
	assert_false(_state.has_status(StatusEffects.CORROSION), "status não sobrevive ao load")


func test_status_is_not_serialized() -> void:
	_state.apply_status(StatusEffects.CORROSION)
	assert_false(_state.to_dict().has("statuses"), "status fora do save")


func _on_status_applied(status_id: StringName, duration: float) -> void:
	_applied.append({"id": status_id, "duration": duration})


func _on_status_cleared(status_id: StringName) -> void:
	_cleared.append(status_id)
