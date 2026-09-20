extends TestCase

const SPACING: float = 32.0
const LIMIT: int = 8

var _state: Node = null
var _previous_no_timer: bool = false


func before_each() -> void:
	_previous_no_timer = Settings.no_timer
	Settings.no_timer = false
	_state = load("res://autoload/game_state.gd").new()
	_state.name = "CutsceneTestState"
	(Engine.get_main_loop() as SceneTree).root.add_child(_state)
	_state.set_process(false)


func after_each() -> void:
	Settings.no_timer = _previous_no_timer
	if _state == null:
		return
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.remove_child(_state)
	_state.free()
	_state = null


func test_path_starts_and_ends_where_asked() -> void:
	var points: Array[Vector2] = [Vector2(300, 0), Vector2(600, 0)]
	var path: Array[Vector2] = CutsceneRoute.build(
		Vector2(1000, 0), Vector2.ZERO, points, SPACING, LIMIT
	)
	assert_eq(path[0], Vector2(1000, 0), "começa no Nó")
	assert_eq(path[path.size() - 1], Vector2.ZERO, "termina no início da fase")


func test_points_are_ordered_from_node_to_start() -> void:
	var points: Array[Vector2] = [Vector2(200, 0), Vector2(800, 0), Vector2(500, 0)]
	var path: Array[Vector2] = CutsceneRoute.build(
		Vector2(1000, 0), Vector2.ZERO, points, SPACING, LIMIT
	)
	assert_eq(path[1], Vector2(800, 0), "o mais perto do Nó vem primeiro")
	assert_eq(path[2], Vector2(500, 0), "depois o do meio")
	assert_eq(path[3], Vector2(200, 0), "por último o mais perto do início")


func test_vertical_level_is_ordered_too() -> void:
	var points: Array[Vector2] = [Vector2(0, 100), Vector2(0, 700), Vector2(0, 400)]
	var path: Array[Vector2] = CutsceneRoute.build(
		Vector2(0, 900), Vector2.ZERO, points, SPACING, LIMIT
	)
	assert_eq(path[1], Vector2(0, 700), "fase vertical desce na ordem certa")
	assert_eq(path[3], Vector2(0, 100), "até o topo da fase")


func test_close_points_are_merged() -> void:
	var points: Array[Vector2] = [Vector2(500, 0), Vector2(510, 0), Vector2(520, 0)]
	var path: Array[Vector2] = CutsceneRoute.build(
		Vector2(1000, 0), Vector2.ZERO, points, SPACING, LIMIT
	)
	assert_eq(path.size(), 3, "lâmpadas coladas viram uma parada só")


func test_limit_caps_the_waypoints() -> void:
	var points: Array[Vector2] = []
	for index: int in range(40):
		points.append(Vector2(float(index) * 100.0, 0.0))
	var path: Array[Vector2] = CutsceneRoute.build(
		Vector2(5000, 0), Vector2.ZERO, points, SPACING, 4
	)
	assert_eq(path.size(), 6, "início + 4 paradas + fim")


func test_level_without_points_still_has_a_path() -> void:
	var empty: Array[Vector2] = []
	var path: Array[Vector2] = CutsceneRoute.build(
		Vector2(640, 0), Vector2.ZERO, empty, SPACING, LIMIT
	)
	assert_eq(path.size(), 2, "sempre dá para varrer do Nó até o começo")
	assert_almost_eq(CutsceneRoute.length(path), 640.0, 0.001, "comprimento da varredura")


func test_point_at_walks_the_polyline() -> void:
	var path: Array[Vector2] = [Vector2.ZERO, Vector2(100, 0), Vector2(100, 100)]
	assert_eq(CutsceneRoute.point_at(path, 0.0), Vector2.ZERO, "início")
	assert_eq(CutsceneRoute.point_at(path, 50.0), Vector2(50, 0), "meio do primeiro trecho")
	assert_eq(CutsceneRoute.point_at(path, 150.0), Vector2(100, 50), "meio do segundo trecho")
	assert_eq(CutsceneRoute.point_at(path, 999.0), Vector2(100, 100), "não passa do fim")


func test_ratio_sampling_is_monotonic() -> void:
	var path: Array[Vector2] = [Vector2.ZERO, Vector2(400, 0)]
	var previous: float = -1.0
	for step: int in range(11):
		var point: Vector2 = CutsceneRoute.point_at_ratio(path, float(step) / 10.0)
		assert_true(point.x >= previous, "a câmera nunca anda para trás")
		previous = point.x


func test_duration_respects_the_limits() -> void:
	assert_almost_eq(CutsceneRoute.duration_for(100.0, 150.0, 3.0, 9.0), 3.0, 0.001, "piso")
	assert_almost_eq(CutsceneRoute.duration_for(600.0, 150.0, 3.0, 9.0), 4.0, 0.001, "proporcional")
	assert_almost_eq(CutsceneRoute.duration_for(9000.0, 150.0, 3.0, 9.0), 9.0, 0.001, "teto")


func test_snap_keeps_the_camera_on_whole_pixels() -> void:
	assert_eq(CutsceneRoute.snap(Vector2(12.4, -7.6)), Vector2(12, -8), "pixel inteiro")


func test_ease_is_smooth_and_bounded() -> void:
	assert_almost_eq(CutsceneRoute.ease_in_out(0.0), 0.0, 0.001, "parado no início")
	assert_almost_eq(CutsceneRoute.ease_in_out(1.0), 1.0, 0.001, "parado no fim")
	assert_almost_eq(CutsceneRoute.ease_in_out(0.5), 0.5, 0.001, "meio")
	assert_almost_eq(CutsceneRoute.ease_in_out(2.0), 1.0, 0.001, "clampado")


func test_on_screen_uses_the_view_box() -> void:
	var half := Vector2(144.0, 88.0)
	assert_true(
		CutsceneRoute.is_on_screen(Vector2.ZERO, Vector2(100, 40), half), "dentro da tela"
	)
	assert_false(
		CutsceneRoute.is_on_screen(Vector2.ZERO, Vector2(200, 0), half), "longe na horizontal"
	)
	assert_false(
		CutsceneRoute.is_on_screen(Vector2.ZERO, Vector2(0, 120), half), "longe na vertical"
	)


func test_control_waits_for_the_skip_key_to_be_released() -> void:
	assert_false(
		CutsceneRoute.can_release_control(0.0, 0.4, true),
		"com a tecla do pulo ainda apertada o MU-7 fica travado"
	)
	assert_true(
		CutsceneRoute.can_release_control(0.1, 0.4, false),
		"soltou a tecla, devolve o controle no quadro seguinte"
	)
	assert_true(
		CutsceneRoute.can_release_control(0.4, 0.4, true),
		"tecla segurada demais não pode prender o jogador para sempre"
	)


func test_cutscene_freezes_the_reactor() -> void:
	_state.set_reactor_online(true)
	EventBus.sector_cutscene_started.emit(&"greenhouse")
	assert_true(_state.is_timer_frozen(), "cutscene congela o timer como a leitura de log")
	EventBus.sector_cutscene_finished.emit(&"greenhouse")
	assert_false(_state.is_timer_frozen(), "volta a correr no fim")
