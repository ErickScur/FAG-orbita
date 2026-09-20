extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"
const CORE_SCENE: String = "res://scenes/levels/core_hub.tscn"
const GREENHOUSE_SCENE: String = "res://scenes/levels/greenhouse.tscn"

var _state: Node = null


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()
	_state.new_game()


func after_each() -> void:
	if _state != null:
		_state.free()
		_state = null


func test_registra_quando_nao_ha_checkpoint() -> void:
	var changed: bool = _state.register_entry_checkpoint(CORE_SCENE, "core_dock_01")
	assert_true(changed, "gravou o checkpoint de entrada")
	assert_eq(String(_state.checkpoint.get("scene", "")), CORE_SCENE, "cena")
	assert_eq(String(_state.checkpoint.get("dock_id", "")), "core_dock_01", "doca")


func test_registra_ao_trocar_de_fase() -> void:
	_state.checkpoint = {"scene": CORE_SCENE, "dock_id": "hab_dock_01"}
	var changed: bool = _state.register_entry_checkpoint(GREENHOUSE_SCENE, "gh_dock_01")
	assert_true(changed, "trocou para a fase nova")
	assert_eq(String(_state.checkpoint.get("scene", "")), GREENHOUSE_SCENE, "cena")
	assert_eq(String(_state.checkpoint.get("dock_id", "")), "gh_dock_01", "doca")


func test_nao_rebaixa_checkpoint_da_mesma_fase() -> void:
	_state.checkpoint = {"scene": GREENHOUSE_SCENE, "dock_id": "gh_dock_02"}
	var changed: bool = _state.register_entry_checkpoint(GREENHOUSE_SCENE, "gh_dock_01")
	assert_false(changed, "não regrava na mesma fase")
	assert_eq(String(_state.checkpoint.get("dock_id", "")), "gh_dock_02", "doca preservada")


func test_ignora_cena_vazia() -> void:
	var changed: bool = _state.register_entry_checkpoint("", "gh_dock_01")
	assert_false(changed, "cena vazia não grava")
	assert_eq(_state.checkpoint.size(), 0, "checkpoint intacto")


func test_ignora_doca_vazia() -> void:
	var changed: bool = _state.register_entry_checkpoint(GREENHOUSE_SCENE, "")
	assert_false(changed, "fase sem doca não grava")
	assert_eq(_state.checkpoint.size(), 0, "checkpoint intacto")


func test_new_game_limpa_checkpoint_de_entrada() -> void:
	_state.register_entry_checkpoint(GREENHOUSE_SCENE, "gh_dock_01")
	_state.new_game()
	assert_eq(_state.checkpoint.size(), 0, "checkpoint zerado")
