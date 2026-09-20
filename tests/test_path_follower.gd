extends TestCase

const SPEED: float = 32.0
const WAIT: float = 1.0
const PING_SPEED: float = 64.0
const PING_SECONDS: float = 0.75
const PING_STEPS: int = 45
const CORNER_SLACK: float = PING_SPEED * PING_SECONDS / float(PING_STEPS) * 1.5

var _route: PackedVector2Array = PackedVector2Array()


func before_each() -> void:
	_route = PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.0, -160.0)])


func test_moves_toward_target() -> void:
	var follower := PathFollower.new(_route, SPEED, WAIT)
	var position: Vector2 = _advance(follower, Vector2.ZERO, 1.0, 60)
	assert_almost_eq(position.y, -32.0, 0.001, "um segundo de subida")


func test_stops_at_point_and_waits() -> void:
	var follower := PathFollower.new(_route, SPEED, WAIT)
	var position: Vector2 = _advance(follower, Vector2.ZERO, 5.2, 312)
	assert_almost_eq(position.y, -160.0, 0.001, "chegou na ponta")
	assert_true(follower.is_waiting(), "espera na ponta")
	position = _advance(follower, position, 0.5, 30)
	assert_almost_eq(position.y, -160.0, 0.001, "parada durante a espera")


func test_reverses_after_wait() -> void:
	var follower := PathFollower.new(_route, SPEED, WAIT)
	var position: Vector2 = _advance(follower, Vector2.ZERO, 5.2, 312)
	position = _advance(follower, position, WAIT + 0.5, 90)
	assert_true(position.y > -160.0, "voltou a descer")
	assert_eq(follower.progress_index(), 0, "alvo voltou para a base")


func test_ping_pong_three_points() -> void:
	var route := PackedVector2Array(
		[Vector2.ZERO, Vector2(64.0, 0.0), Vector2(64.0, -64.0)]
	)
	var follower := PathFollower.new(route, PING_SPEED, 0.0)
	assert_eq(follower.progress_index(), 1, "começa indo para o meio")
	var position: Vector2 = _advance(follower, Vector2.ZERO, PING_SECONDS, PING_STEPS)
	assert_almost_eq(position.x, 48.0, 0.001, "andando no primeiro trecho")
	position = _advance(follower, position, PING_SECONDS, PING_STEPS)
	assert_eq(follower.progress_index(), 2, "virou para a ponta de cima")
	assert_almost_eq(position.y, -32.0, CORNER_SLACK, "subindo o segundo trecho")
	position = _advance(follower, position, PING_SECONDS, PING_STEPS)
	assert_eq(follower.progress_index(), 1, "inverteu na ponta")
	assert_almost_eq(position.y, -48.0, CORNER_SLACK * 2.0, "descendo de volta")


func test_no_overshoot() -> void:
	var follower := PathFollower.new(_route, SPEED, WAIT)
	var position: Vector2 = follower.step(Vector2.ZERO, 10.0)
	assert_eq(position, Vector2(0.0, -160.0), "não passa do ponto")


func test_single_point_never_moves() -> void:
	var follower := PathFollower.new(PackedVector2Array([Vector2(8.0, 8.0)]), SPEED, WAIT)
	assert_eq(follower.step(Vector2(8.0, 8.0), 1.0), Vector2(8.0, 8.0), "trajeto degenerado")


func test_zero_speed_never_moves() -> void:
	var follower := PathFollower.new(_route, 0.0, WAIT)
	assert_eq(follower.step(Vector2.ZERO, 1.0), Vector2.ZERO, "sem velocidade")


func test_resumes_from_the_same_point_after_a_pause() -> void:
	var follower := PathFollower.new(_route, SPEED, 0.0)
	var position: Vector2 = _advance(follower, Vector2.ZERO, 1.0, 60)
	var frozen: Vector2 = position
	position = follower.step(position, 1.0 / 60.0)
	assert_true(position.y < frozen.y, "continua subindo do mesmo ponto")


func test_uses_balance_defaults() -> void:
	var follower := PathFollower.new(_route, Balance.PLATFORM_SPEED, Balance.PLATFORM_WAIT)
	assert_almost_eq(follower.speed, Balance.PLATFORM_SPEED, 0.0001, "velocidade do GDD-P")
	assert_almost_eq(follower.wait_time, Balance.PLATFORM_WAIT, 0.0001, "pausa do GDD-P")


func _advance(follower: PathFollower, from: Vector2, seconds: float, steps: int) -> Vector2:
	var position: Vector2 = from
	var delta: float = seconds / float(steps)
	for index: int in range(steps):
		position = follower.step(position, delta)
	return position
