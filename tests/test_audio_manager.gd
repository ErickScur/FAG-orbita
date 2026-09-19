extends TestCase


func after_each() -> void:
	AudioManager.stop_music(0.0)


func test_music_ids_match_the_gdd_tracks() -> void:
	assert_true(AudioManager.MUSIC.has(&"menu"), "menu")
	assert_true(AudioManager.MUSIC.has(&"core"), "core")
	assert_true(AudioManager.MUSIC.has(&"greenhouse"), "greenhouse")


func test_every_track_resolves_to_a_file() -> void:
	for id: StringName in AudioManager.MUSIC:
		var path: String = AudioManager._resolve_music_path(id)
		assert_false(path.is_empty(), "arquivo para %s" % id)


func test_play_music_sets_current_track() -> void:
	AudioManager.play_music(&"menu", 0.0)
	assert_eq(AudioManager.current_music(), &"menu", "trilha atual")


func test_play_music_crossfades_to_another_track() -> void:
	AudioManager.play_music(&"menu", 0.0)
	AudioManager.play_music(&"core", 0.0)
	assert_eq(AudioManager.current_music(), &"core", "trilha atual")


func test_same_track_does_not_restart() -> void:
	AudioManager.play_music(&"menu", 0.0)
	var player: AudioStreamPlayer = AudioManager._music_active
	AudioManager.play_music(&"menu", 0.0)
	assert_eq(AudioManager._music_active, player, "mesmo player")
	assert_eq(AudioManager.current_music(), &"menu", "mesma trilha")


func test_crossfade_swaps_between_the_two_players() -> void:
	AudioManager.play_music(&"menu", 0.0)
	var first: AudioStreamPlayer = AudioManager._music_active
	AudioManager.play_music(&"core", 0.0)
	assert_ne(AudioManager._music_active, first, "troca de player")


func test_music_players_use_the_music_bus() -> void:
	assert_eq(AudioManager._music_a.bus, &"Music", "MusicA")
	assert_eq(AudioManager._music_b.bus, &"Music", "MusicB")
	assert_eq(AudioManager._voice.bus, &"Voice", "Voice")


func test_sfx_pool_has_eight_players_on_the_sfx_bus() -> void:
	assert_eq(AudioManager._sfx_pool.size(), 8, "tamanho do pool")
	for player: AudioStreamPlayer in AudioManager._sfx_pool:
		assert_eq(player.bus, &"SFX", "bus do player")


func test_ninth_sfx_reuses_the_oldest_player() -> void:
	var streams: Array = AudioManager._streams_for(&"ui_confirm")
	assert_false(streams.is_empty(), "efeito disponível")
	if streams.is_empty():
		return
	var busy: Array[AudioStreamPlayer] = []
	for index: int in range(AudioManager.SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioManager._next_sfx_player()
		assert_false(busy.has(player), "player %d ainda livre" % index)
		busy.append(player)
		player.stream = streams[0]
		player.play()
	var reused: AudioStreamPlayer = AudioManager._next_sfx_player()
	assert_true(busy.has(reused), "nono som reaproveita um player do pool")
	assert_eq(reused, busy[0], "reaproveita o mais antigo")
	for player: AudioStreamPlayer in AudioManager._sfx_pool:
		player.stop()
		player.stream = null


func test_stop_music_clears_current_track() -> void:
	AudioManager.play_music(&"menu", 0.0)
	AudioManager.stop_music(0.0)
	assert_eq(AudioManager.current_music(), &"", "trilha vazia")


func test_unknown_track_is_ignored() -> void:
	AudioManager.stop_music(0.0)
	AudioManager.play_music(&"trilha_inexistente", 0.0)
	assert_eq(AudioManager.current_music(), &"", "sem trilha")


func test_ui_sfx_resolve_to_files() -> void:
	for sfx_name: String in ["ui_move", "ui_confirm", "ui_back", "ui_error"]:
		assert_false(AudioManager._resolve_sfx_path(sfx_name).is_empty(), sfx_name)


func test_sfx_variants_are_grouped() -> void:
	var streams: Array = AudioManager._streams_for(&"step_metal")
	assert_eq(streams.size(), 3, "três variações de passo")


func test_missing_sfx_does_not_break() -> void:
	AudioManager.play_sfx(&"som_que_nao_existe")
	assert_eq(AudioManager._streams_for(&"som_que_nao_existe").size(), 0, "sem streams")


func test_sfx_pool_size() -> void:
	assert_eq(AudioManager.SFX_POOL_SIZE, 8, "pool de SFX")
