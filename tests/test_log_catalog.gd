extends TestCase

const ARCHIVE_SCENE: String = "res://scenes/ui/log_archive.tscn"
const ARCHIVE_SCRIPT: String = "res://scenes/ui/log_archive.gd"
const TEXTS_PATH: String = "res://data/ui/log_archive.json"
const THEME_PATH: String = "res://assets/ui/theme.tres"
const LOGS_DIR: String = "res://data/logs/"
const SPEAKERS_DIR: String = "res://data/dialogue/"
const SAVE_PROBE: String = "user://test_log_catalog_save.json"
const SCREEN_WIDTH: float = 384.0
const FONT_SIZE: int = 16
const MISSING_GLYPHS: String = "←→↑↓✓—■□▮▼•"

var _logs: Dictionary = {}
var _speakers: Dictionary = {}
var _sectors: Array[Dictionary] = []


func before_each() -> void:
	_logs = DialogueData.load_dir(LOGS_DIR)["logs"]
	_speakers = DialogueData.load_dir(SPEAKERS_DIR)["speakers"]
	_sectors = StationMapModel.load_station()["sectors"]


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PROBE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PROBE))


func test_the_catalog_lists_every_log_of_the_campaign() -> void:
	var entries: Array[Dictionary] = LogCatalog.entries(_logs, [])
	assert_eq(entries.size(), Balance.LOGS_TOTAL, "um registro por log do Balance")
	for entry: Dictionary in entries:
		assert_false(String(entry[LogCatalog.KEY_TITLE]).is_empty(), "%s tem título" % entry["id"])
		assert_ne(entry[LogCatalog.KEY_AUTHOR], &"", "%s tem autor" % entry["id"])
		assert_false(
			(entry[LogCatalog.KEY_LINES] as PackedStringArray).is_empty(),
			"%s tem texto" % entry["id"]
		)


func test_every_log_sector_is_a_sector_of_the_station_map() -> void:
	var keys: Dictionary = {}
	for sector: Dictionary in _sectors:
		keys[sector[StationMapModel.KEY_ID]] = true
		keys[sector[StationMapModel.KEY_LEVEL]] = true
	for entry: Dictionary in LogCatalog.entries(_logs, []):
		assert_true(
			keys.has(entry[LogCatalog.KEY_SECTOR]),
			"o setor '%s' do log %s está no data/map/station.json" % [
				entry[LogCatalog.KEY_SECTOR], entry["id"]
			]
		)


func test_every_author_has_a_speaker_name() -> void:
	for entry: Dictionary in LogCatalog.entries(_logs, []):
		var author: StringName = entry[LogCatalog.KEY_AUTHOR]
		assert_ne(
			LogCatalog.author_name(author, _speakers),
			String(author).to_upper(),
			"autor '%s' tem nome em speakers.json" % author
		)


func test_collected_logs_are_marked() -> void:
	var entries: Array[Dictionary] = LogCatalog.entries(_logs, [&"log_core_01"])
	for entry: Dictionary in entries:
		assert_eq(
			bool(entry[LogCatalog.KEY_COLLECTED]),
			entry[LogCatalog.KEY_ID] == &"log_core_01",
			"só o log coletado vem marcado (%s)" % entry["id"]
		)
	var mixed: Array = [&"log_core_01", &"data_core_01"]
	assert_eq(LogCatalog.collected_count(_logs, mixed), 1, "conta só log")


func test_groups_follow_the_station_order() -> void:
	var groups: Array[Dictionary] = LogCatalog.group_by_sector(
		LogCatalog.entries(_logs, []), _sectors
	)
	var labels: Array[String] = []
	for group: Dictionary in groups:
		labels.append(String(group[LogCatalog.KEY_LABEL]))
	assert_true(labels.size() >= 4, "um grupo por setor com log")
	assert_eq(labels[0], "NÚCLEO CENTRAL", "primeiro o Núcleo")
	assert_eq(labels[1], "ESTUFA", "depois a Estufa")
	assert_eq(labels[2], "LABORATÓRIO", "depois o Laboratório")
	assert_eq(labels[3], "ENFERMARIA", "depois a Enfermaria")
	assert_eq(LogCatalog.flatten(groups).size(), Balance.LOGS_TOTAL, "nenhum log some")


func test_a_log_from_an_unmapped_sector_still_shows_at_the_end() -> void:
	var logs: Dictionary = _logs.duplicate(true)
	logs[&"zz_probe_log"] = {
		"id": "zz_probe_log", "sector": "zz_probe", "author": "helena", "title": "SONDA",
		"lines": ["linha"],
	}
	var groups: Array[Dictionary] = LogCatalog.group_by_sector(
		LogCatalog.entries(logs, []), _sectors
	)
	var last: Dictionary = groups[groups.size() - 1]
	assert_eq(last[LogCatalog.KEY_ID], &"zz_probe", "setor desconhecido vai para o fim")
	assert_eq(String(last[LogCatalog.KEY_LABEL]), "ZZ_PROBE", "rótulo de reserva")


func test_grouping_by_author_hides_who_wrote_the_missing_logs() -> void:
	var groups: Array[Dictionary] = LogCatalog.group_by_author(
		LogCatalog.entries(_logs, [&"log_core_01", &"log_gh_01"]), _speakers, "NÃO ENCONTRADOS"
	)
	assert_eq(groups.size(), 2, "Helena + não encontrados")
	assert_eq(String(groups[0][LogCatalog.KEY_LABEL]), "DRA. HELENA VASQUEZ", "nome do autor")
	assert_eq((groups[0][LogCatalog.KEY_ENTRIES] as Array).size(), 2, "dois logs lidos")
	assert_eq(String(groups[1][LogCatalog.KEY_LABEL]), "NÃO ENCONTRADOS", "grupo dos ausentes")
	assert_eq(
		(groups[1][LogCatalog.KEY_ENTRIES] as Array).size(),
		Balance.LOGS_TOTAL - 2,
		"o resto fica sem autor"
	)


func test_sector_ids_and_found_counts() -> void:
	var ids: Array[StringName] = LogCatalog.ids_for_sector(_logs, [&"greenhouse"])
	assert_eq(ids.size(), 2, "dois logs na Estufa")
	assert_eq(LogCatalog.found_count(ids, [&"log_gh_02", &"log_core_01"]), 1, "um achado")


func test_the_main_menu_reads_collected_logs_from_the_save_file() -> void:
	var file := FileAccess.open(SAVE_PROBE, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"version": 1, "state": {"collected_ids": ["log_core_01", "data_core_01"]}
	}))
	file.close()
	var ids: Array[StringName] = LogCatalog.collected_from_save(SAVE_PROBE)
	assert_eq(ids.size(), 2, "lê os ids do backup")
	assert_true(ids.has(&"log_core_01"), "log do backup")
	assert_true(LogCatalog.collected_from_save("user://zz_missing.json").is_empty(), "sem backup")


func test_rereading_in_the_archive_never_touches_the_run() -> void:
	var saved_collected: Array[StringName] = GameState.collected_ids.duplicate()
	var saved_logs: Array[StringName] = GameState.logs_collected.duplicate()
	var saved_reactor: float = GameState.reactor_percent
	var one: Array[StringName] = [&"log_core_01"]
	GameState.collected_ids = one.duplicate()
	GameState.logs_collected = one.duplicate()
	GameState.reactor_percent = 50.0
	var archive: Control = _mount_archive()
	assert_eq(archive.call(&"entry_count"), Balance.LOGS_TOTAL, "lista inteira")
	_select(archive, &"log_core_01")
	assert_true(archive.call(&"open_selected"), "abre o log coletado")
	assert_true(archive.call(&"is_reading"), "modo leitura")
	assert_true(
		String(archive.call(&"reader_text")).begins_with("Log de manutenção cento e catorze"),
		"texto completo do log"
	)
	assert_almost_eq(GameState.reactor_percent, 50.0, 0.0001, "reler não dá +0,5%")
	assert_eq(GameState.collected_ids.size(), 1, "reler não registra coleta")
	assert_eq(GameState.logs_collected.size(), 1, "reler não conta log")
	archive.free()
	GameState.collected_ids = saved_collected
	GameState.logs_collected = saved_logs
	GameState.reactor_percent = saved_reactor


func test_a_missing_log_cannot_be_opened() -> void:
	var saved: Array[StringName] = GameState.collected_ids.duplicate()
	var none: Array[StringName] = []
	GameState.collected_ids = none
	var archive: Control = _mount_archive()
	_select(archive, &"log_core_01")
	assert_false(archive.call(&"open_selected"), "log não encontrado não abre")
	assert_false(archive.call(&"is_reading"), "segue na lista")
	archive.free()
	GameState.collected_ids = saved


func test_the_archive_source_never_registers_a_pickup() -> void:
	var source: String = FileAccess.get_file_as_string(ARCHIVE_SCRIPT)
	assert_false(source.contains("open_log"), "não usa o DialogueManager.open_log")
	assert_false(source.contains("register_pickup"), "não registra coleta")
	assert_false(source.contains("log_opened"), "não emite log_opened")
	assert_true(source.contains("PROCESS_MODE_ALWAYS"), "funciona com a árvore pausada")


func test_archive_texts_exist_fit_and_avoid_missing_glyphs() -> void:
	var texts: Dictionary = HudModel.load_texts(TEXTS_PATH)
	var font: Font = (load(THEME_PATH) as Theme).default_font
	for id: StringName in [
		&"title", &"counter", &"by_sector", &"by_author", &"unknown_author", &"missing_title",
		&"missing_body", &"read_hint", &"empty", &"footer_list", &"footer_reader",
	]:
		assert_false(HudModel.text_for(id, texts).is_empty(), "texto '%s'" % id)
	for id: StringName in texts:
		var text: String = HudModel.text_for(id, texts)
		for index: int in range(MISSING_GLYPHS.length()):
			assert_false(
				text.contains(MISSING_GLYPHS.substr(index, 1)), "'%s' usa glifo ausente" % id
			)
	for footer: StringName in [&"footer_list", &"footer_reader"]:
		var width: float = font.get_string_size(
			HudModel.text_for(footer, texts), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE
		).x
		assert_true(width <= SCREEN_WIDTH - 8.0, "rodapé '%s' com %.0f px" % [footer, width])


func test_log_titles_fit_the_list_column() -> void:
	var font: Font = (load(THEME_PATH) as Theme).default_font
	var script: GDScript = load(ARCHIVE_SCRIPT)
	var constants: Dictionary = script.get_script_constant_map()
	var room: float = float(constants["LIST_WIDTH"]) - float(constants["ENTRY_INDENT"])
	for entry: Dictionary in LogCatalog.entries(_logs, []):
		var width: float = font.get_string_size(
			String(entry[LogCatalog.KEY_TITLE]), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE
		).x
		assert_true(width <= room, "título de %s com %.0f px (%.0f)" % [entry["id"], width, room])


func test_pause_and_main_menu_open_the_archive() -> void:
	var pause: String = FileAccess.get_file_as_string("res://scenes/ui/pause_menu.gd")
	assert_true(pause.contains(ARCHIVE_SCENE), "o pause abre o arquivo")
	assert_true(pause.contains('is_action_pressed(&"log_archive")'), "a tecla L abre o arquivo")
	var pause_scene: String = FileAccess.get_file_as_string("res://scenes/ui/pause_menu.tscn")
	assert_true(pause_scene.contains('text = "ARQUIVO DE LOGS"'), "item no pause")
	var menu: String = FileAccess.get_file_as_string("res://scenes/ui/main_menu.tscn")
	assert_true(menu.contains('text = "ARQUIVO"'), "item ARQUIVO na tela inicial")
	var smoke: String = FileAccess.get_file_as_string("res://tests/scenes.txt")
	assert_true(smoke.contains(ARCHIVE_SCENE), "arquivo no smoke")


func _mount_archive() -> Control:
	var archive: Control = (load(ARCHIVE_SCENE) as PackedScene).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(archive)
	return archive


func _select(archive: Control, log_id: StringName) -> void:
	archive.set(&"_selected", log_id)
