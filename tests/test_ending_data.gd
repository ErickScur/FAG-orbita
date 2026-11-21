extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"
const README_PATH: String = "res://README.md"
const FONT_PATH: String = "res://assets/fonts/ui_font.ttf"
const SAVE_FIXTURE: String = "user://test_f66_save.json"
const LOG_NAMES: PackedStringArray = [
	"Helena Vasquez", "Samira Okafor", "Marcos", "Teodoro", "Ana Lúcia", "Davi"
]
const NEAR_STATION_RATIO: float = 0.5

var _state: Node = null
var _table: Dictionary = {}


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()
	_table = EndingData.load_table()


func after_each() -> void:
	if _state != null:
		_state.free()
		_state = null
	if FileAccess.file_exists(SAVE_FIXTURE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FIXTURE))


func test_endings_data_is_complete() -> void:
	var problems: PackedStringArray = EndingData.errors(_table)
	assert_true(problems.is_empty(), ", ".join(problems))


func test_the_seeding_cut_keeps_the_capsule_near_artemis() -> void:
	var events: Array[Dictionary] = EndingData.cutscene_events(_table, EndingData.SEEDING)
	var launch_at: float = -1.0
	for event: Dictionary in events:
		if String(event.get("do", "")) == "launch":
			launch_at = float(event.get("at", 0.0))
	assert_true(launch_at >= 0.0, "a Semeadura lança a cápsula")
	var flight: float = EndingData.capsule_flight(_table, EndingData.SEEDING)
	assert_true(flight > 0.0, "a Semeadura define o tempo de voo da cápsula")
	var flown: float = (EndingData.cutscene_length(events) - launch_at) / maxf(flight, 0.001)
	assert_true(
		flown <= NEAR_STATION_RATIO,
		"corte com a cápsula a %.0f%% do voo; corta perto da ARTEMIS" % (flown * 100.0)
	)


func test_continue_hint_follows_the_input_device() -> void:
	var keyboard: String = EndingData.continue_hint(_table, false)
	var pad: String = EndingData.continue_hint(_table, true)
	assert_true(keyboard.begins_with("[ENTER]"), "teclado mostra ENTER: %s" % keyboard)
	assert_true(pad.begins_with("[A]"), "controle mostra o botão A: %s" % pad)
	assert_ne(keyboard, pad, "as duas dicas são diferentes")


func test_joypad_detection_follows_the_last_device() -> void:
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	assert_true(EndingData.joypad_from_event(button, false), "botão de controle")
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	assert_false(EndingData.joypad_from_event(key, true), "tecla volta ao teclado")
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.1
	assert_false(EndingData.joypad_from_event(drift, false), "ruído do analógico não troca")
	var mouse := InputEventMouseMotion.new()
	assert_true(EndingData.joypad_from_event(mouse, true), "mouse que só se mexe mantém")


func test_no_data_is_the_lowest_tier() -> void:
	assert_eq(EndingData.tier_for(0, Balance.RESEARCH_TOTAL), EndingData.TIER_FEW, "zero dados")


func test_every_data_is_the_highest_tier() -> void:
	var total: int = Balance.RESEARCH_TOTAL
	assert_eq(EndingData.tier_for(total, total), EndingData.TIER_MOST, "todos os dados")


func test_tiers_follow_the_ratios_of_the_final_total() -> void:
	assert_eq(EndingData.tier_for(3, 12), EndingData.TIER_FEW, "3 de 12")
	assert_eq(EndingData.tier_for(4, 12), EndingData.TIER_SOME, "4 de 12")
	assert_eq(EndingData.tier_for(8, 12), EndingData.TIER_SOME, "8 de 12")
	assert_eq(EndingData.tier_for(9, 12), EndingData.TIER_MOST, "9 de 12")


func test_tiers_also_work_with_the_current_total() -> void:
	assert_eq(EndingData.tier_for(2, 8), EndingData.TIER_FEW, "2 de 8")
	assert_eq(EndingData.tier_for(3, 8), EndingData.TIER_SOME, "3 de 8")
	assert_eq(EndingData.tier_for(6, 8), EndingData.TIER_MOST, "6 de 8")


func test_tier_tolerates_bad_counts() -> void:
	assert_eq(EndingData.tier_for(99, 12), EndingData.TIER_MOST, "acima do total")
	assert_eq(EndingData.tier_for(-3, 12), EndingData.TIER_FEW, "negativo")
	assert_eq(EndingData.tier_for(5, 0), EndingData.TIER_FEW, "total zero")


func test_each_tier_tells_a_different_epilogue() -> void:
	for ending_id: StringName in EndingData.ENDING_IDS:
		var seen: Dictionary = {}
		for tier: StringName in EndingData.TIERS:
			var text: String = "\n".join(EndingData.epilogue(_table, ending_id, tier))
			assert_false(seen.has(text), "%s/%s repete outra faixa" % [ending_id, tier])
			seen[text] = true


func test_the_two_endings_tell_different_stories() -> void:
	for tier: StringName in EndingData.TIERS:
		var seeding: PackedStringArray = EndingData.epilogue(_table, EndingData.SEEDING, tier)
		var signal_text: PackedStringArray = EndingData.epilogue(
			_table, EndingData.TRANSMISSION, tier
		)
		assert_ne("\n".join(seeding), "\n".join(signal_text), "faixa %s igual nos dois" % tier)


func test_the_most_confident_epilogue_cites_coordinates() -> void:
	for ending_id: StringName in EndingData.ENDING_IDS:
		var most: String = "\n".join(EndingData.epilogue(_table, ending_id, EndingData.TIER_MOST))
		var few: String = "\n".join(EndingData.epilogue(_table, ending_id, EndingData.TIER_FEW))
		assert_true(most.contains("graus"), "%s com muitos dados cita a latitude" % ending_id)
		assert_false(few.contains("graus"), "%s com poucos dados não sabe a latitude" % ending_id)


func test_record_choice_marks_the_game_as_completed() -> void:
	var flags: Dictionary = {}
	assert_true(EndingData.record_choice(flags, EndingData.TRANSMISSION), "grava")
	assert_eq(EndingData.chosen(flags), EndingData.TRANSMISSION, "final")
	assert_true(EndingData.is_completed(flags), "jogo concluído")


func test_record_choice_rejects_an_unknown_ending() -> void:
	var flags: Dictionary = {}
	assert_false(EndingData.record_choice(flags, &"explode"), "final inexistente")
	assert_true(flags.is_empty(), "nada gravado")
	assert_eq(EndingData.chosen_or_default(flags), EndingData.SEEDING, "padrão para a tela")


func test_choice_survives_the_save_round_trip() -> void:
	EndingData.record_choice(_state.flags, EndingData.SEEDING)
	var file := FileAccess.open(SAVE_FIXTURE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"state": _state.to_dict()}))
	file.close()
	assert_eq(EndingData.from_save(SAVE_FIXTURE), EndingData.SEEDING, "lido do save")
	assert_eq(EndingData.from_save("user://nao_existe_f66.json"), &"", "sem save, sem marca")


func test_stats_rows_list_time_logs_data_deaths_and_ending() -> void:
	_state.play_time = 754.0
	_state.deaths = 3
	_state.logs_collected.append(&"log_a")
	_state.research_collected.append(&"res_a")
	_state.research_collected.append(&"res_b")
	var rows: Array[PackedStringArray] = EndingData.stats_rows(_state, _table, EndingData.SEEDING)
	assert_eq(rows.size(), 5, "cinco linhas")
	assert_eq(rows[0][1], "12:34", "tempo")
	assert_eq(rows[1][1], "1/%d" % Balance.LOGS_TOTAL, "logs")
	assert_eq(rows[2][1], "2/%d" % Balance.RESEARCH_TOTAL, "dados")
	assert_eq(rows[3][1], "3", "mortes")
	assert_eq(rows[4][1], "SEMEADURA", "final escolhido")


func test_the_crew_has_exactly_forty_unique_people() -> void:
	var crew: Array[Dictionary] = EndingData.crew()
	assert_eq(crew.size(), Balance.CREW_TOTAL, "40 nomes")
	var names: Dictionary = {}
	for member: Dictionary in crew:
		var name: String = String(member.get("name", ""))
		assert_false(name.is_empty(), "nome vazio")
		assert_false(String(member.get("role", "")).is_empty(), "%s sem função" % name)
		assert_false(names.has(name), "%s repetido" % name)
		names[name] = true


func test_the_crew_includes_everyone_the_logs_mention() -> void:
	var roster: String = ""
	for member: Dictionary in EndingData.crew():
		roster += String(member.get("name", "")) + "\n"
	for name: String in LOG_NAMES:
		assert_true(roster.contains(name), "%s está nos logs e falta na tripulação" % name)


func test_credits_name_the_team_of_the_readme() -> void:
	var lines: PackedStringArray = EndingData.credit_lines(EndingData.credits())
	var credits_text: String = "\n".join(lines)
	for person: String in _readme_team():
		assert_true(credits_text.contains(person), "%s falta nos créditos" % person)
	for required: String in ["Jeferson Eduardo Guido", "Desenvolvimento de Jogos", "Godot", "m5x7"]:
		assert_true(credits_text.contains(required), "%s falta nos créditos" % required)


func test_credits_cover_every_third_party_author_of_the_readme() -> void:
	var credits_text: String = "\n".join(EndingData.credit_lines(EndingData.credits()))
	var readme: String = FileAccess.get_file_as_string(README_PATH)
	for author: String in ["Daniel Linssen", "Kenney"]:
		assert_true(readme.contains(author), "README cita %s" % author)
		assert_true(credits_text.contains(author), "créditos citam %s" % author)


func test_every_ending_text_fits_the_ui_font() -> void:
	var font: FontFile = load(FONT_PATH)
	assert_not_null(font, "fonte da UI")
	if font == null:
		return
	var texts: PackedStringArray = EndingData.credit_lines(EndingData.credits())
	for ending_id: StringName in EndingData.ENDING_IDS:
		for tier: StringName in EndingData.TIERS:
			texts.append_array(EndingData.epilogue(_table, ending_id, tier))
		texts.append(EndingData.text(_table, ending_id, "confirm"))
	for member: Dictionary in EndingData.crew():
		texts.append(String(member.get("name", "")) + String(member.get("role", "")))
	for value: Variant in (_table.get("ui", {}) as Dictionary).values():
		texts.append(String(value))
	for text: String in texts:
		for index: int in range(text.length()):
			var code: int = text.unicode_at(index)
			assert_true(font.has_char(code), "glifo '%s' ausente na m5x7 em: %s" % [text[index], text])


func _readme_team() -> PackedStringArray:
	var readme: String = FileAccess.get_file_as_string(README_PATH)
	var start: int = readme.find("## Equipe")
	assert_true(start >= 0, "README tem a seção Equipe")
	var lines: PackedStringArray = readme.substr(start).split("\n")
	var team := PackedStringArray()
	for line: String in lines.slice(1):
		if line.strip_edges().is_empty():
			continue
		for person: String in line.split(" · "):
			team.append(person.strip_edges())
		break
	return team
