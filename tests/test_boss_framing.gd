extends TestCase

const DOCKS_META: String = "res://data/levels/docks.json"
const REACTOR_META: String = "res://data/levels/reactor_core.json"
const BOSS_ID: String = "lock_serralheiro"
const LANDING: Vector2i = Vector2i(91, 40)
const HUD_BAND: float = 40.0
const MAX_PARK_TILES: int = 8
const SCREEN: Vector2 = Vector2(384, 216)
const CAMERA_OFFSET_Y: float = -16.0
const FLOOR_STATIONS: Array[String] = ["rc_console_a", "rc_coupler_01"]
const GAUGE_MARGIN: float = 8.0


func test_focus_between_puts_the_boss_below_the_hud() -> void:
	var player := Vector2(1464, 640)
	var boss_top := Vector2(1576, 522)
	var center: Vector2 = ArenaFraming.focus_between(player, boss_top, SCREEN, 48.0)
	var top: float = center.y - SCREEN.y * 0.5
	assert_almost_eq(boss_top.y - top, 48.0, 0.5, "chefe a 48 px do topo")
	assert_true(absf(player.x - center.x) < SCREEN.x * 0.5, "MU-7 na tela")
	assert_true(absf(boss_top.x - center.x) < SCREEN.x * 0.5, "chefe na tela")
	assert_true(player.y - top < SCREEN.y, "pé do MU-7 na tela")


func test_limit_bottom_follows_the_feet() -> void:
	assert_eq(ArenaFraming.limit_bottom(600.0, 664.0, 696.0, 712.0), 696.0, "no piso: alto")
	assert_eq(ArenaFraming.limit_bottom(700.0, 664.0, 696.0, 712.0), 712.0, "no fosso: baixo")


func test_clamp_center_respects_limits() -> void:
	var limits := Rect2(0, 0, 1000, 500)
	var clamped: Vector2 = ArenaFraming.clamp_center(Vector2(10, 490), limits, SCREEN)
	assert_eq(clamped, Vector2(192, 392), "presa nos limites")


func test_the_serralheiro_parks_in_view_of_the_landing() -> void:
	var boss: Dictionary = _boss()
	var cell: Vector2i = boss.get("cell", Vector2i(-1, -1))
	assert_ne(cell, Vector2i(-1, -1), "Serralheiro no JSON")
	assert_true(absi(cell.x - LANDING.x) <= MAX_PARK_TILES, "braço estacionado à vista do pouso")


func test_wake_focus_frames_the_whole_arm_and_the_mu7() -> void:
	var boss: Dictionary = _boss()
	var params: Dictionary = boss.get("params", {})
	var cell: Vector2i = boss.get("cell", Vector2i.ZERO)
	var rail_top: float = float((params.get("arena", [0, 0]) as Array)[1]) * Balance.TILE_SIZE
	var trolley_top: float = (
		rail_top + Serralheiro.TROLLEY_DROP - Serralheiro.TROLLEY_FRAME.y * 0.5
	)
	var arm_x: float = (float(cell.x) + 0.5) * Balance.TILE_SIZE
	var feet := Vector2((LANDING.x + 0.5) * Balance.TILE_SIZE, (LANDING.y + 1) * Balance.TILE_SIZE)
	var center: Vector2 = ArenaFraming.focus_between(
		feet, Vector2(arm_x, trolley_top), SCREEN, Serralheiro.WAKE_TOP_MARGIN
	)
	var left: float = center.x - SCREEN.x * 0.5
	var top: float = center.y - SCREEN.y * 0.5
	assert_true(trolley_top - top >= HUD_BAND, "carro abaixo da faixa da HUD no despertar")
	var half: float = Serralheiro.TROLLEY_FRAME.x * 0.5
	assert_true(arm_x - half - left >= 0.0, "carro inteiro na tela (esquerda)")
	assert_true(arm_x + half - left <= SCREEN.x, "carro inteiro na tela (direita)")
	assert_true(feet.y - top <= SCREEN.y - 8.0, "MU-7 inteiro no quadro")
	assert_true(feet.y - 32.0 - top >= HUD_BAND, "MU-7 abaixo da HUD")


func test_fight_framing_keeps_the_trolley_under_the_hud_band() -> void:
	var params: Dictionary = _boss().get("params", {})
	assert_true(params.has("framing_floor"), "arena declara o piso de enquadramento")
	var arena: Array = params.get("arena", [])
	var rail_top: float = float(arena[1]) * Balance.TILE_SIZE
	var trolley_top: float = (
		rail_top + Serralheiro.TROLLEY_DROP - Serralheiro.TROLLEY_FRAME.y * 0.5
	)
	var high: float = ArenaFraming.high_bottom(
		trolley_top, Serralheiro.FRAMING_TOP_MARGIN, SCREEN.y
	)
	var low: float = (float(arena[1]) + float(arena[3])) * Balance.TILE_SIZE
	assert_true(
		ArenaFraming.top_on_screen(trolley_top, high, SCREEN.y) >= HUD_BAND,
		"no piso o carro fica abaixo da HUD"
	)
	var floor_top: float = float(params["framing_floor"]) * Balance.TILE_SIZE
	assert_true(high - floor_top >= 32.0, "o piso principal e o MU-7 cabem no quadro alto")
	assert_true(high <= low + Serralheiro.CAMERA_FLOOR_MARGIN, "o quadro alto não passa do fundo")


func test_argos_timer_lamps_wrap_under_the_core() -> void:
	var points: Array[Vector2] = ArgosTimerLamps.horseshoe(
		Balance.ARGOS_SEGMENTS,
		ArgosEncounter.SEGMENT_RADIUS,
		deg_to_rad(ArgosEncounter.SEGMENT_SPREAD_DEGREES)
	)
	assert_eq(points.size(), Balance.ARGOS_SEGMENTS, "uma lâmpada por segmento")
	var lowest: float = -INF
	for point: Vector2 in points:
		assert_true(point.y > -ArgosEncounter.SEGMENT_RADIUS * 0.25, "nenhuma no alto do núcleo")
		lowest = maxf(lowest, point.y)
	assert_almost_eq(lowest, ArgosEncounter.SEGMENT_RADIUS, 1.0, "a do meio fica embaixo")
	assert_true(ArgosTimerLamps.LAMP_SIZE >= 6.0, "lâmpada de 6 px, não ponto")
	var row: Array[Vector2] = ArgosTimerLamps.row(
		Balance.ARGOS_SEGMENTS, ArgosEncounter.GAUGE_SPACING
	)
	assert_almost_eq(row[0].x, -row[row.size() - 1].x, 0.5, "painel centrado")
	assert_true(
		row[1].x - row[0].x >= ArgosTimerLamps.SOCKET_SIZE, "soquetes não se sobrepõem"
	)


func test_every_floor_station_sees_a_whole_timer_gauge() -> void:
	var meta: Dictionary = _load(REACTOR_META)
	var argos: Dictionary = meta.get("argos", {})
	var gauges: Array = argos.get("gauges", [])
	assert_true(gauges.size() >= 2, "painéis do timer no piso")
	var half_width: float = (
		ArgosEncounter.GAUGE_SPACING * float(Balance.ARGOS_SEGMENTS - 1) * 0.5
		+ ArgosTimerLamps.SOCKET_SIZE * 0.5 + ArgosTimerLamps.PLATE_PAD
	)
	for station: String in FLOOR_STATIONS:
		var cell: Vector2i = _find(meta, station)
		assert_ne(cell, Vector2i(-1, -1), "'%s' no JSON" % station)
		var feet := Vector2((cell.x + 0.5) * Balance.TILE_SIZE, (cell.y + 1) * Balance.TILE_SIZE)
		var top: float = feet.y + CAMERA_OFFSET_Y - SCREEN.y * 0.5
		var seen: bool = false
		for value: Variant in gauges:
			var gauge := Vector2(float(value[0]), float(value[1]))
			var inside_x: bool = (
				absf(gauge.x - feet.x) + half_width <= SCREEN.x * 0.5 - GAUGE_MARGIN
			)
			var below_hud: bool = gauge.y - top - ArgosTimerLamps.SOCKET_SIZE >= HUD_BAND
			var above_feet: bool = gauge.y < feet.y - Balance.TILE_SIZE
			if inside_x and below_hud and above_feet:
				seen = true
		assert_true(seen, "de '%s' um painel inteiro do timer aparece" % station)


func test_urgency_starts_with_the_fast_alarm() -> void:
	assert_true(ArgosLogic.is_urgent(Balance.ARGOS_ALARM_FAST_TIME), "nos últimos 20 s")
	assert_false(ArgosLogic.is_urgent(Balance.ARGOS_ALARM_FAST_TIME + 0.1), "antes não")


func test_the_core_sits_below_the_platform_tops() -> void:
	var meta: Dictionary = _load(REACTOR_META)
	var core: Array = (meta.get("argos", {}) as Dictionary).get("core", [])
	var lift: Vector2i = _find(meta, "rc_lift_01")
	var path: Array = (_entity(meta, "rc_lift_01")).get("path", [])
	var top_row: float = float(lift.y) + float((path[path.size() - 1] as Array)[1])
	var feet_y: float = top_row * Balance.TILE_SIZE
	var top: float = feet_y + CAMERA_OFFSET_Y - SCREEN.y * 0.5
	var core_top: float = float(core[1]) - 32.0
	assert_true(core_top - top >= HUD_BAND * 0.5, "do alto da plataforma o núcleo sai da HUD")


func _boss() -> Dictionary:
	var meta: Dictionary = _load(DOCKS_META)
	var entities: Dictionary = meta.get("entities", {})
	for key: Variant in entities:
		var params: Dictionary = entities[key]
		if String(params.get("id", "")) == BOSS_ID:
			return {"cell": LevelParser.key_to_cell(String(key)), "params": params}
	return {}


func _find(meta: Dictionary, entity_id: String) -> Vector2i:
	var entities: Dictionary = meta.get("entities", {})
	for key: Variant in entities:
		if String((entities[key] as Dictionary).get("id", "")) == entity_id:
			return LevelParser.key_to_cell(String(key))
	return Vector2i(-1, -1)


func _entity(meta: Dictionary, entity_id: String) -> Dictionary:
	var entities: Dictionary = meta.get("entities", {})
	for key: Variant in entities:
		if String((entities[key] as Dictionary).get("id", "")) == entity_id:
			return entities[key]
	return {}


func _load(path: String) -> Dictionary:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return raw if raw is Dictionary else {}
