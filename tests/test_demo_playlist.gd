extends TestCase

const PLAYLIST_DIR: String = "res://tests/qa/demo/"
const PLAYLISTS: Array[String] = ["novidades", "completo"]


func _sample() -> Dictionary:
	return DemoPlaylist.parse({
		"nome": "teste",
		"capitulos": [
			{"id": "docas", "titulo": "Docas", "roteiro": "res://a.json", "espera_transicao": 12},
			{"id": "final", "titulo": "Final", "roteiro": "res://final_{final}.json"},
		],
	})


func test_parse_reads_chapters_in_order() -> void:
	var parsed: Dictionary = _sample()
	var chapters: Array = parsed["chapters"]
	assert_eq(parsed["name"], "teste", "nome")
	assert_eq(chapters.size(), 2, "dois capítulos")
	assert_eq((chapters[0] as Dictionary)["id"], "docas", "ordem")
	assert_almost_eq(float((chapters[0] as Dictionary)["wait_transition"]), 12.0, 0.001, "espera")
	assert_almost_eq(float((chapters[1] as Dictionary)["wait_transition"]), 0.0, 0.001, "padrão")
	assert_eq((parsed["errors"] as PackedStringArray).size(), 0, "sem erros")


func test_parse_reports_broken_playlists() -> void:
	assert_true((DemoPlaylist.parse([])["errors"] as PackedStringArray).size() > 0, "lista solta")
	var empty: Dictionary = DemoPlaylist.parse({"capitulos": [{"id": "x"}]})
	assert_eq((empty["chapters"] as Array).size(), 0, "capítulo sem roteiro some")
	assert_true((empty["errors"] as PackedStringArray).size() >= 2, "avisa roteiro e lista vazia")


func test_chapter_index_by_id_number_or_default() -> void:
	var chapters: Array = _sample()["chapters"]
	assert_eq(DemoPlaylist.chapter_index(chapters, ""), 0, "sem pedido começa no primeiro")
	assert_eq(DemoPlaylist.chapter_index(chapters, "final"), 1, "por id")
	assert_eq(DemoPlaylist.chapter_index(chapters, "2"), 1, "por número, a partir de 1")
	assert_eq(DemoPlaylist.chapter_index(chapters, "3"), -1, "número fora")
	assert_eq(DemoPlaylist.chapter_index(chapters, "0"), -1, "zero fora")
	assert_eq(DemoPlaylist.chapter_index(chapters, "lab"), -1, "id desconhecido")
	assert_eq(DemoPlaylist.chapter_index([], ""), -1, "playlist vazia")


func test_next_index_stops_past_the_end() -> void:
	assert_eq(DemoPlaylist.next_index(0, 3), 1, "avança")
	assert_eq(DemoPlaylist.next_index(2, 3), 3, "último leva ao fim")
	assert_eq(DemoPlaylist.next_index(3, 3), 3, "não passa do fim")
	assert_true(DemoPlaylist.is_past_end(3, 3), "fim")
	assert_false(DemoPlaylist.is_past_end(2, 3), "último ainda vale")


func test_final_token_picks_the_ending() -> void:
	var chapter: Dictionary = (_sample()["chapters"] as Array)[1]
	assert_eq(DemoPlaylist.script_path(chapter, "transmissao"), "res://final_transmissao.json")
	assert_eq(DemoPlaylist.script_path(chapter, "semeadura"), "res://final_semeadura.json")
	assert_eq(DemoPlaylist.script_path(chapter, "outro"), "res://final_semeadura.json", "padrão")


func test_advance_press_only_for_pressed_accept_actions() -> void:
	assert_true(DemoPlaylist.is_advance_press({"action": "ui_accept", "pressed": true}))
	assert_true(DemoPlaylist.is_advance_press({"action": "interact", "pressed": true}))
	assert_true(DemoPlaylist.is_advance_press({"action": "jump"}), "pressed padrão é verdadeiro")
	assert_false(DemoPlaylist.is_advance_press({"action": "ui_accept", "pressed": false}))
	assert_false(DemoPlaylist.is_advance_press({"action": "move_right", "pressed": true}))
	assert_false(DemoPlaylist.is_advance_press({"call": "GameState.new_game"}))


func test_teleports_are_found_and_cut_smoothly() -> void:
	var events: Array = [
		{"frame": 5, "call": "Lab/Player.set_indexed", "args": ["global_position:x", 10]},
		{"frame": 5, "call": "Lab/Player.set_indexed", "args": ["global_position:y", 10]},
		{"frame": 9, "call": "Docks/Entities/Serralheiro.set_indexed", "args": ["_fight:time_left", 1]},
		{"frame": 40, "call": "Hub/Player.set_indexed", "args": ["global_position:x", 3]},
	]
	var frames: Array[int] = DemoPlaylist.teleport_frames(events)
	assert_eq(frames, [5, 40] as Array[int], "um corte por quadro de teleporte")
	assert_almost_eq(DemoPlaylist.cut_alpha(5, frames, 4, 6), 1.0, 0.001, "preto no teleporte")
	assert_almost_eq(DemoPlaylist.cut_alpha(0, frames, 4, 6), 0.0, 0.001, "antes do corte")
	assert_true(DemoPlaylist.cut_alpha(3, frames, 4, 6) > 0.0, "escurece antes")
	assert_true(DemoPlaylist.cut_alpha(8, frames, 4, 6) > 0.0, "clareia depois")
	assert_almost_eq(DemoPlaylist.cut_alpha(20, frames, 4, 6), 0.0, 0.001, "longe do corte")


func test_reading_hold_grows_with_text_and_caps() -> void:
	assert_almost_eq(DemoPlaylist.reading_hold(0), DemoPlaylist.HOLD_BASE, 0.001, "mínimo")
	assert_almost_eq(DemoPlaylist.reading_hold(40), 1.1, 0.001, "0,5 + 0,015 por letra")
	assert_almost_eq(DemoPlaylist.reading_hold(1000), DemoPlaylist.HOLD_MAX, 0.001, "teto")
	assert_true(DemoPlaylist.reading_hold(80) > DemoPlaylist.reading_hold(20), "cresce")


func test_freeze_never_lands_on_an_input_frame() -> void:
	assert_true(DemoPlaylist.can_freeze_after(10, 9), "último aperto no quadro anterior")
	assert_false(DemoPlaylist.can_freeze_after(10, 10), "aperto neste quadro")
	assert_true(DemoPlaylist.can_freeze_after(0, -1), "nenhum aperto ainda")


func test_clock_formats_minutes_and_seconds() -> void:
	assert_eq(DemoPlaylist.clock(0.0), "00:00")
	assert_eq(DemoPlaylist.clock(75.9), "01:15")
	assert_eq(DemoPlaylist.clock(-3.0), "00:00")


func test_pause_spec_parses_chapter_frame_and_seconds() -> void:
	var pauses: Array[Dictionary] = DemoPlaylist.parse_pauses("docas@120:3,reator@50:2.5,lixo,x@a:1")
	assert_eq(pauses.size(), 2, "dois válidos")
	assert_eq(pauses[0]["chapter"], "docas")
	assert_eq(pauses[0]["frame"], 120)
	assert_almost_eq(float(pauses[1]["seconds"]), 2.5, 0.001)
	assert_false(bool(pauses[0]["done"]), "ainda não disparou")
	assert_eq(pauses[0]["key"], "P", "tempo vira pausa")
	var keys: Array[Dictionary] = DemoPlaylist.parse_pauses("docas@10:N,reator@20:R,x@5:Q")
	assert_eq(keys.size(), 2, "N e R valem, outra letra não")
	assert_eq(keys[0]["key"], "N")
	assert_eq(keys[1]["key"], "R")


func test_shipped_playlists_point_to_existing_scripts() -> void:
	for playlist: String in PLAYLISTS:
		var path: String = PLAYLIST_DIR + playlist + ".json"
		assert_true(FileAccess.file_exists(path), "playlist %s" % path)
		if not FileAccess.file_exists(path):
			continue
		var parsed: Dictionary = DemoPlaylist.parse(
			JSON.parse_string(FileAccess.get_file_as_string(path))
		)
		assert_eq((parsed["errors"] as PackedStringArray).size(), 0, "%s sem erros" % path)
		for chapter: Dictionary in parsed["chapters"] as Array:
			for final_id: String in DemoPlaylist.FINALS:
				var script: String = DemoPlaylist.script_path(chapter, final_id)
				assert_true(FileAccess.file_exists(script), "%s: %s" % [path, script])
