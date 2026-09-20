extends TestCase

const CARD_SCENE: String = "res://scenes/ui/tutorial_card.tscn"
const ZONE_SCENE: String = "res://scenes/world/tutorial_zone.tscn"
const LEVEL_BASE: String = "res://scenes/levels/level_base.tscn"
const BRIEFING_SCENE: String = "res://scenes/boot/briefing.tscn"
const BRIEFING_SCRIPT: String = "res://scenes/boot/briefing.gd"
const LEVELS_DIR: String = "res://data/levels/"
const REQUIRED_IDS: Array[String] = [
	"tut_move",
	"tut_pause",
	"tut_jump",
	"tut_drop",
	"tut_interact",
	"tut_flashlight",
	"tut_terminal",
	"tut_climb",
]

var _catalog: Dictionary = {}


func before_each() -> void:
	_catalog = TutorialData.load_all()


func test_catalog_loads_every_required_card() -> void:
	assert_false(_catalog.is_empty(), "catálogo carregou")
	for tutorial_id: String in REQUIRED_IDS:
		assert_true(
			TutorialData.has(StringName(tutorial_id), _catalog), "cartão '%s'" % tutorial_id
		)
	assert_eq(_catalog.size(), REQUIRED_IDS.size(), "nenhum cartão a mais no catálogo")


func test_catalog_is_valid() -> void:
	var errors: PackedStringArray = TutorialData.validate(_catalog)
	assert_true(errors.is_empty(), ", ".join(errors))


func test_every_card_completes_with_the_key_it_shows() -> void:
	var expected: Dictionary = {
		&"tut_move": [&"move_left", &"move_right"],
		&"tut_pause": [&"pause"],
		&"tut_jump": [&"jump"],
		&"tut_drop": [&"move_down"],
		&"tut_interact": [&"interact"],
		&"tut_flashlight": [&"flashlight"],
		&"tut_terminal": [&"interact"],
		&"tut_climb": [&"move_up"],
	}
	for tutorial_id: Variant in expected:
		var actions: Array[StringName] = TutorialData.actions_of(tutorial_id, _catalog)
		assert_eq(
			_names(actions), _names(expected[tutorial_id]), "inputs de '%s'" % tutorial_id
		)


func test_card_text_fits_the_384_pixel_screen() -> void:
	for tutorial_id: StringName in _catalog:
		var entry: Dictionary = TutorialData.entry(tutorial_id, _catalog)
		var headline: String = TutorialData.headline(tutorial_id, _catalog)
		assert_true(
			headline.length() <= 38, "'%s' com %d caracteres" % [tutorial_id, headline.length()]
		)
		assert_true(
			String(entry["hint"]).length() <= 38, "dica de '%s' longa demais" % tutorial_id
		)


func test_card_text_avoids_glyphs_the_pixel_font_lacks() -> void:
	var missing: String = "←→↑↓✓—"
	for tutorial_id: StringName in _catalog:
		var entry: Dictionary = TutorialData.entry(tutorial_id, _catalog)
		var text: String = "%s%s%s" % [entry["key"], entry["text"], entry["hint"]]
		for index: int in range(missing.length()):
			assert_false(
				text.contains(missing.substr(index, 1)),
				"'%s' usa um glifo que a m5x7 não tem" % tutorial_id
			)


func test_flag_name_is_the_card_id() -> void:
	assert_eq(TutorialData.flag_name(&"tut_jump"), "tut_jump", "a flag é o próprio id")


func test_scenes_exist_and_are_registered() -> void:
	var smoke: String = FileAccess.get_file_as_string("res://tests/scenes.txt")
	for path: String in [CARD_SCENE, ZONE_SCENE, BRIEFING_SCENE]:
		assert_true(ResourceLoader.exists(path), "cena %s existe" % path)
		assert_true(smoke.contains(path), "cena %s no smoke" % path)


func test_level_base_mounts_the_card() -> void:
	var text: String = FileAccess.get_file_as_string(LEVEL_BASE)
	assert_true(text.contains(CARD_SCENE), "level_base instancia o cartão")


func test_event_bus_publishes_the_tutorial_signals() -> void:
	assert_true(EventBus.has_signal(&"tutorial_requested"), "sinal de pedido")
	assert_true(EventBus.has_signal(&"tutorial_completed"), "sinal de conclusão")


func test_level_triggers_only_use_cards_that_exist() -> void:
	for level_id: String in _level_ids():
		for value: Variant in _meta(level_id).get("triggers", []) as Array:
			var tutorial: String = String((value as Dictionary).get("tutorial", ""))
			if tutorial.is_empty():
				continue
			assert_true(
				TutorialData.has(StringName(tutorial), _catalog),
				"fase '%s': cartão '%s' inexistente" % [level_id, tutorial]
			)


func test_every_card_is_used_by_some_level() -> void:
	var used: Dictionary = {}
	for level_id: String in _level_ids():
		for value: Variant in _meta(level_id).get("triggers", []) as Array:
			var tutorial: String = String((value as Dictionary).get("tutorial", ""))
			if not tutorial.is_empty():
				used[tutorial] = true
	for tutorial_id: String in REQUIRED_IDS:
		assert_true(used.has(tutorial_id), "cartão '%s' sem gatilho em nenhuma fase" % tutorial_id)


func test_briefing_reads_its_text_from_data() -> void:
	var script: Script = load(BRIEFING_SCRIPT)
	assert_not_null(script, "script do briefing carregou")
	var data: Dictionary = script.call("load_data")
	var blocks: Array = data.get("blocks", [])
	assert_eq(blocks.size(), 5, "cinco blocos de briefing")
	for value: Variant in blocks:
		var block: Dictionary = value
		assert_false(String(block.get("title", "")).is_empty(), "bloco sem título")
		var fields: Array = block.get("fields", [])
		var lines: Array = block.get("lines", [])
		assert_true(fields.size() + lines.size() > 0, "bloco vazio")
	assert_eq((blocks[0] as Dictionary).get("fields", []).size(), 5, "ficha com cinco campos")


func test_briefing_goes_to_the_first_level() -> void:
	var text: String = FileAccess.get_file_as_string(BRIEFING_SCRIPT)
	assert_true(text.contains("res://scenes/levels/core_hub.tscn"), "briefing aponta o Núcleo")
	var menu: String = FileAccess.get_file_as_string("res://scenes/ui/main_menu.gd")
	assert_true(menu.contains(BRIEFING_SCENE), "NOVO SISTEMA passa pelo briefing")


func test_briefing_footer_changes_when_the_block_is_done() -> void:
	var script: Script = load(BRIEFING_SCRIPT)
	assert_ne(script.call("footer_text", true), script.call("footer_text", false), "rodapé muda")


func _names(values: Array) -> PackedStringArray:
	var result := PackedStringArray()
	for value: Variant in values:
		result.append(String(value))
	return result


func _level_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	var dir := DirAccess.open(LEVELS_DIR)
	if dir == null:
		return ids
	for file_name: String in dir.get_files():
		if file_name.ends_with(".txt"):
			ids.append(file_name.get_basename())
	ids.sort()
	return ids


func _meta(level_id: String) -> Dictionary:
	var path: String = LEVELS_DIR + level_id + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_cards_that_do_not_share_a_key_with_dialogue_are_never_blocked() -> void:
	var table: Dictionary = TutorialData.load_all()
	var advance: Array[StringName] = DialogueManager.ADVANCE_ACTIONS
	for tutorial_id: StringName in [&"tut_climb", &"tut_flashlight", &"tut_drop", &"tut_move"]:
		var actions: Array[StringName] = TutorialData.actions_of(tutorial_id, table)
		assert_false(
			TutorialData.shares_action_with(actions, advance),
			"cartão '%s' não pode depender de tecla que o diálogo consome" % tutorial_id
		)


func test_cards_that_share_a_key_with_dialogue_stay_guarded() -> void:
	var table: Dictionary = TutorialData.load_all()
	var advance: Array[StringName] = DialogueManager.ADVANCE_ACTIONS
	for tutorial_id: StringName in [&"tut_jump", &"tut_interact", &"tut_terminal"]:
		var actions: Array[StringName] = TutorialData.actions_of(tutorial_id, table)
		assert_true(
			TutorialData.shares_action_with(actions, advance),
			"cartão '%s' divide tecla com o diálogo e precisa da guarda" % tutorial_id
		)
