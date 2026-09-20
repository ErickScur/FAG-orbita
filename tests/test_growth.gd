extends TestCase

const GROW_TIME: float = 3.0
const FRAMES: int = 6


func test_grows_only_when_powered() -> void:
	assert_almost_eq(Growth.step(0.0, false, 1.0, GROW_TIME), 0.0, 0.0001, "sem luz não cresce")


func test_reaches_one_after_grow_time() -> void:
	var progress: float = 0.0
	for index: int in range(3):
		progress = Growth.step(progress, true, 1.0, GROW_TIME)
	assert_almost_eq(progress, 1.0, 0.0001, "adulta no tempo do GDD-P")


func test_does_not_shrink() -> void:
	var progress: float = Growth.step(0.0, true, 1.5, GROW_TIME)
	assert_almost_eq(progress, 0.5, 0.0001, "meio do crescimento")
	progress = Growth.step(progress, false, 2.0, GROW_TIME)
	assert_almost_eq(progress, 0.5, 0.0001, "sem luz mantém o estágio")


func test_resumes_where_it_stopped() -> void:
	var progress: float = Growth.step(0.5, false, 1.0, GROW_TIME)
	progress = Growth.step(progress, true, 1.5, GROW_TIME)
	assert_almost_eq(progress, 1.0, 0.0001, "retoma e completa")


func test_never_passes_one() -> void:
	assert_almost_eq(Growth.step(0.9, true, 10.0, GROW_TIME), 1.0, 0.0001, "limite superior")


func test_zero_grow_time_completes_at_once() -> void:
	assert_almost_eq(Growth.step(0.0, true, 0.016, 0.0), 1.0, 0.0001, "tempo degenerado")


func test_frame_for_maps_progress() -> void:
	assert_eq(Growth.frame_for(0.0, FRAMES), 0, "broto")
	assert_eq(Growth.frame_for(0.5, FRAMES), 3, "meio do crescimento")
	assert_eq(Growth.frame_for(1.0, FRAMES), FRAMES - 1, "adulta")


func test_frame_for_is_safe_without_frames() -> void:
	assert_eq(Growth.frame_for(1.0, 0), 0, "sem frames")


func test_is_grown() -> void:
	assert_false(Growth.is_grown(0.99), "quase adulta")
	assert_true(Growth.is_grown(1.0), "adulta")


func test_uses_balance_grow_time() -> void:
	var progress: float = Growth.step(0.0, true, Balance.PLANT_GROW_TIME, Balance.PLANT_GROW_TIME)
	assert_true(Growth.is_grown(progress), "cresce em PLANT_GROW_TIME")


func test_accumulated_frames_reach_the_grown_state() -> void:
	var progress: float = 0.0
	var step: float = 1.0 / 60.0
	for index: int in range(int(Balance.PLANT_GROW_TIME * 60.0)):
		progress = Growth.step(progress, true, step, Balance.PLANT_GROW_TIME)
	assert_true(Growth.is_grown(progress), "soma de frames não pode travar em 0,9999")


func test_almost_one_is_grown() -> void:
	assert_true(Growth.is_grown(0.9999999999999999), "erro de ponto flutuante conta como adulta")
