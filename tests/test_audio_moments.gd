extends TestCase

const MOMENTS: Array[StringName] = [
	&"chassis_lost", &"game_over", &"sector_restored", &"reactor_critical",
]
const DURATION_RANGE: Dictionary = {
	&"chassis_lost": Vector2(6.0, 10.0),
	&"game_over": Vector2(10.0, 15.0),
	&"sector_restored": Vector2(15.0, 20.0),
	&"reactor_critical": Vector2(20.0, 30.0),
}
const DURATION_TOLERANCE: float = 0.05


func before_each() -> void:
	AudioManager.stop_all()


func after_each() -> void:
	AudioManager.stop_all()


func test_moment_tracks_are_registered() -> void:
	for id: StringName in MOMENTS:
		assert_true(AudioManager.MUSIC.has(id), "trilha %s registrada" % id)


func test_moment_tracks_resolve_to_a_file() -> void:
	for id: StringName in MOMENTS:
		assert_false(AudioManager._resolve_music_path(id).is_empty(), "arquivo de %s" % id)


func test_every_track_declares_whether_it_loops() -> void:
	for id: StringName in AudioManager.MUSIC:
		var looping: bool = AudioManager.MUSIC_LOOPING.has(id)
		var one_shot: bool = AudioManager.MUSIC_ONE_SHOT.has(id)
		assert_true(looping != one_shot, "%s em exatamente uma lista" % id)


func test_dramatic_moments_are_one_shot_and_tension_layer_loops() -> void:
	for id: StringName in [&"chassis_lost", &"game_over", &"sector_restored"]:
		assert_true(AudioManager.MUSIC_ONE_SHOT.has(id), "%s toca uma vez" % id)
	assert_true(AudioManager.MUSIC_LOOPING.has(&"reactor_critical"), "camada em loop")


func test_one_shot_streams_do_not_loop() -> void:
	for id: StringName in AudioManager.MUSIC_ONE_SHOT:
		var stream: AudioStream = AudioManager._load_track(id, false)
		assert_not_null(stream, "stream de %s" % id)
		if stream is AudioStreamWAV:
			var wav: AudioStreamWAV = stream
			assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED, "%s sem loop" % id)


func test_tension_layer_stream_loops() -> void:
	var stream: AudioStream = AudioManager._load_track(&"reactor_critical", true)
	assert_not_null(stream, "stream da camada")
	if stream is AudioStreamWAV:
		var wav: AudioStreamWAV = stream
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "camada em loop")


func test_placeholder_durations_follow_the_contract() -> void:
	for id: StringName in MOMENTS:
		var stream: AudioStream = AudioManager._load_track(id, false)
		if stream == null:
			fail("stream de %s" % id)
			continue
		var range_seconds: Vector2 = DURATION_RANGE[id]
		var length: float = stream.get_length()
		assert_true(length >= range_seconds.x - DURATION_TOLERANCE, "%s dura o mínimo" % id)
		assert_true(length <= range_seconds.y + DURATION_TOLERANCE, "%s dura o máximo" % id)


func test_moment_players_use_the_music_bus() -> void:
	assert_eq(AudioManager._layer.bus, &"Music", "camada de tensão no bus de música")


func test_one_shot_takes_over_the_current_track() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager.play_one_shot(&"chassis_lost")
	assert_eq(AudioManager.current_music(), &"chassis_lost", "trilha do momento")
	assert_eq(AudioManager.current_one_shot(), &"chassis_lost", "momento ativo")
	assert_true(AudioManager.is_one_shot_playing(), "one-shot tocando")


func test_one_shot_gives_the_level_track_back_when_it_ends() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager.play_one_shot(&"chassis_lost")
	AudioManager._on_one_shot_finished()
	assert_eq(AudioManager.current_music(), &"core", "trilha da fase de volta")
	assert_false(AudioManager.is_one_shot_playing(), "one-shot terminou")


func test_one_shot_does_not_loop_back_into_itself() -> void:
	AudioManager.play_music(&"greenhouse", 0.0)
	AudioManager.play_one_shot(&"sector_restored")
	AudioManager._on_one_shot_finished()
	assert_ne(AudioManager.current_music(), &"sector_restored", "não repete")
	assert_eq(AudioManager.current_music(), &"greenhouse", "volta para a estufa")


func test_game_over_one_shot_ends_in_silence() -> void:
	AudioManager.play_music(&"greenhouse", 0.0)
	AudioManager.play_one_shot(&"game_over", false)
	assert_eq(AudioManager.current_music(), &"game_over", "trilha da perda de órbita")
	AudioManager._on_one_shot_finished()
	assert_eq(AudioManager.current_music(), &"", "silêncio depois")


func test_one_shot_does_not_restart_while_it_plays() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager.play_one_shot(&"chassis_lost")
	var player: AudioStreamPlayer = AudioManager._music_active
	AudioManager.play_one_shot(&"chassis_lost")
	assert_eq(AudioManager._music_active, player, "mesmo player")


func test_second_one_shot_keeps_the_original_resume_track() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager.play_one_shot(&"chassis_lost")
	AudioManager.play_one_shot(&"sector_restored")
	AudioManager._on_one_shot_finished()
	assert_eq(AudioManager.current_music(), &"core", "volta para a fase")


func test_tension_layer_rides_over_the_level_track() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager._on_reactor_critical(true)
	assert_eq(AudioManager.current_layer(), &"reactor_critical", "camada ligada")
	assert_eq(AudioManager.current_music(), &"core", "trilha da fase continua")
	assert_true(AudioManager._layer.playing, "player da camada tocando")


func test_leaving_the_critical_state_gives_the_level_track_back() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager._on_reactor_critical(true)
	AudioManager._on_reactor_critical(false)
	assert_eq(AudioManager.current_layer(), &"", "camada desligada")
	assert_eq(AudioManager.current_music(), &"core", "trilha da fase intacta")


func test_tension_layer_survives_a_one_shot() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager._on_reactor_critical(true)
	AudioManager.play_one_shot(&"chassis_lost")
	assert_eq(AudioManager.current_layer(), &"reactor_critical", "camada continua")
	AudioManager._on_one_shot_finished()
	assert_eq(AudioManager.current_music(), &"core", "trilha da fase de volta")
	assert_eq(AudioManager.current_layer(), &"reactor_critical", "camada ainda ligada")


func test_stop_music_silences_layer_and_one_shot() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager._on_reactor_critical(true)
	AudioManager.play_one_shot(&"sector_restored")
	AudioManager.stop_music(0.0)
	assert_eq(AudioManager.current_music(), &"", "sem trilha")
	assert_eq(AudioManager.current_layer(), &"", "sem camada")
	assert_false(AudioManager.is_one_shot_playing(), "sem momento")


func test_unknown_moment_keeps_the_level_track() -> void:
	AudioManager.play_music(&"core", 0.0)
	AudioManager.play_one_shot(&"momento_inexistente")
	assert_eq(AudioManager.current_music(), &"core", "trilha da fase intacta")
	assert_false(AudioManager.is_one_shot_playing(), "nenhum momento ativo")


func test_audio_manager_listens_to_the_moment_signals() -> void:
	assert_true(
		EventBus.sector_restored.is_connected(AudioManager._on_sector_restored),
		"setor religado"
	)
	assert_true(
		EventBus.reactor_critical.is_connected(AudioManager._on_reactor_critical),
		"estado crítico"
	)
	assert_true(EventBus.game_over.is_connected(AudioManager._on_game_over), "perda de órbita")
