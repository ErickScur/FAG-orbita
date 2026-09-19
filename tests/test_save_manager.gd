extends TestCase

const TEST_PATH: String = "user://test_save.json"

var _previous_path: String = ""
var _snapshot: Dictionary = {}


func before_each() -> void:
	_previous_path = SaveManager.save_path
	_snapshot = GameState.to_dict()
	SaveManager.save_path = TEST_PATH
	_remove_file()


func after_each() -> void:
	_remove_file()
	SaveManager.save_path = _previous_path
	GameState.from_dict(_snapshot)


func _remove_file() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func _write_raw(text: String) -> void:
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	if file == null:
		fail("não foi possível escrever o arquivo de teste")
		return
	file.store_string(text)
	file.close()


func _mutate_state() -> void:
	GameState.new_game()
	GameState.reactor_percent = 82.5
	GameState.integrity = 75
	GameState.charge = 40.0
	var logs: Array[StringName] = [&"log_helena_01", &"log_helena_02"]
	var research: Array[StringName] = [&"res_greenhouse_01"]
	var collected: Array[StringName] = [&"cell_core_01", &"log_helena_01"]
	var abilities: Array[StringName] = [&"magnetic_claws"]
	var sectors: Array[StringName] = [&"core"]
	var systems: Array[StringName] = [&"grow_lamp", &"door_north"]
	GameState.logs_collected = logs
	GameState.research_collected = research
	GameState.collected_ids = collected
	GameState.abilities = abilities
	GameState.sectors_restored = sectors
	GameState.energy_states = {&"greenhouse_terminal": systems}
	GameState.checkpoint = {
		"scene": "res://scenes/levels/greenhouse.tscn", "dock_id": "greenhouse_dock_1"
	}
	GameState.deaths = 2
	GameState.play_time = 754.2
	GameState.flags = {"tutorial_done": true, "secret_greenhouse_01": true}
	GameState.current_objective = "Religar o Nó de Energia da Estufa"


func test_save_creates_versioned_file() -> void:
	assert_true(SaveManager.save_game(), "gravou")
	assert_true(FileAccess.file_exists(TEST_PATH), "arquivo existe")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
	assert_true(parsed is Dictionary, "json é objeto")
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	assert_eq(int(data.get("version", -1)), SaveManager.VERSION, "versão")
	assert_true(int(data.get("saved_at", 0)) > 0, "carimbo de tempo")
	assert_true(data.get("state", null) is Dictionary, "estado presente")


func test_round_trip_restores_every_field() -> void:
	_mutate_state()
	var expected: String = JSON.stringify(GameState.to_dict())
	assert_true(SaveManager.save_game(), "gravou")
	GameState.new_game()
	assert_ne(JSON.stringify(GameState.to_dict()), expected, "estado foi zerado")
	assert_true(SaveManager.load_game(), "carregou")
	assert_eq(JSON.stringify(GameState.to_dict()), expected, "estado idêntico")
	assert_eq(GameState.deaths, 2, "mortes")
	assert_almost_eq(GameState.play_time, 754.2, 0.001, "tempo")
	assert_eq(GameState.logs_collected.size(), 2, "logs")
	assert_eq(GameState.energy_states.size(), 1, "terminais de energia")
	assert_true(GameState.energy_states.has(&"greenhouse_terminal"), "terminal por StringName")
	assert_true(bool(GameState.flags.get("secret_greenhouse_01", false)), "flag de segredo")
	assert_eq(String(GameState.checkpoint.get("dock_id", "")), "greenhouse_dock_1", "doca")


func test_has_save_without_file() -> void:
	assert_false(SaveManager.has_save(), "sem arquivo")


func test_has_save_after_write() -> void:
	assert_true(SaveManager.save_game(), "gravou")
	assert_true(SaveManager.has_save(), "com arquivo")


func test_delete_save_removes_file() -> void:
	assert_true(SaveManager.save_game(), "gravou")
	SaveManager.delete_save()
	assert_false(FileAccess.file_exists(TEST_PATH), "arquivo removido")
	assert_false(SaveManager.has_save(), "sem backup")


func test_delete_without_file_is_silent() -> void:
	SaveManager.delete_save()
	assert_false(SaveManager.has_save(), "segue sem backup")


func test_unknown_version_is_refused() -> void:
	_mutate_state()
	var expected: String = JSON.stringify(GameState.to_dict())
	_write_raw(JSON.stringify({"version": 99, "saved_at": 1, "state": {"reactor_percent": 1.0}}))
	assert_false(SaveManager.has_save(), "versão desconhecida não conta como backup")
	assert_false(SaveManager.load_game(), "recusou carregar")
	assert_eq(JSON.stringify(GameState.to_dict()), expected, "estado intacto")


func test_corrupted_file_is_refused() -> void:
	_mutate_state()
	var expected: String = JSON.stringify(GameState.to_dict())
	_write_raw("{isso não é json")
	assert_false(SaveManager.has_save(), "arquivo corrompido não conta como backup")
	assert_false(SaveManager.load_game(), "recusou carregar")
	assert_eq(JSON.stringify(GameState.to_dict()), expected, "estado intacto")


func test_empty_file_is_refused() -> void:
	_write_raw("")
	assert_false(SaveManager.has_save(), "arquivo vazio")
	assert_false(SaveManager.load_game(), "recusou carregar")


func test_missing_state_is_refused() -> void:
	_write_raw(JSON.stringify({"version": SaveManager.VERSION, "saved_at": 1}))
	assert_false(SaveManager.has_save(), "sem estado")
	assert_false(SaveManager.load_game(), "recusou carregar")


func test_is_corrupted_without_file() -> void:
	assert_false(SaveManager.is_corrupted(), "sem arquivo não é corrompido")


func test_is_corrupted_with_bad_file() -> void:
	_write_raw("{isso não é json")
	assert_true(SaveManager.is_corrupted(), "arquivo inválido")


func test_is_corrupted_with_unknown_version() -> void:
	_write_raw(JSON.stringify({"version": 99, "state": {}}))
	assert_true(SaveManager.is_corrupted(), "versão desconhecida")


func test_is_corrupted_with_valid_file() -> void:
	assert_true(SaveManager.save_game(), "gravou")
	assert_false(SaveManager.is_corrupted(), "backup válido")


func test_read_header_without_file() -> void:
	var header: Dictionary = SaveManager.read_header()
	assert_false(bool(header.get("exists", true)), "não existe")
	assert_eq(String(header.get("scene", "x")), "", "sem cena")


func test_read_header_describes_save() -> void:
	_mutate_state()
	assert_true(SaveManager.save_game(), "gravou")
	var header: Dictionary = SaveManager.read_header()
	assert_true(bool(header.get("exists", false)), "existe")
	assert_eq(
		String(header.get("scene", "")), "res://scenes/levels/greenhouse.tscn", "cena do checkpoint"
	)
	assert_almost_eq(float(header.get("reactor", 0.0)), 82.5, 0.001, "reator")
	assert_true(int(header.get("saved_at", 0)) > 0, "carimbo de tempo")
