extends TestCase

const PLAYER_SCENE: String = "res://scenes/player/mu7.tscn"
const TICK: float = 1.0 / 60.0

var _player: Node = null


func before_each() -> void:
	GameState.new_game()


func after_each() -> void:
	if is_instance_valid(_player):
		_player.get_parent().remove_child(_player)
		_player.free()
	_player = null
	GameState.new_game()


func test_a_blow_flashes_full_and_damage_over_time_only_pulses() -> void:
	assert_eq(HitFlashRules.flash_for(false, 0.0), HitFlashRules.FULL, "golpe: flash cheio")
	assert_eq(HitFlashRules.flash_for(true, 0.0), 0.0, "tick logo depois: sem flash")
	assert_eq(
		HitFlashRules.flash_for(true, HitFlashRules.OVER_TIME_INTERVAL),
		HitFlashRules.OVER_TIME,
		"pulso fraco a cada intervalo"
	)
	assert_true(HitFlashRules.OVER_TIME < 0.5, "pulso nunca vira silhueta branca")
	assert_true(HitFlashRules.shakes(false), "golpe treme")
	assert_false(HitFlashRules.shakes(true), "dano contínuo não treme a cada tick")


func test_game_state_tells_damage_over_time_apart() -> void:
	var seen: Array[bool] = []
	var listener := func(_amount: int) -> void: seen.append(GameState.is_damage_over_time())
	EventBus.player_damaged.connect(listener)
	GameState.apply_damage(5)
	var carry: float = 0.0
	for index: int in range(60):
		carry = GameState.apply_damage_over_time(10.0, TICK, carry)
	EventBus.player_damaged.disconnect(listener)
	assert_true(seen.size() >= 2, "golpe e ticks chegaram")
	assert_false(seen[0], "golpe não é contínuo")
	assert_true(seen[seen.size() - 1], "tick é contínuo")
	assert_false(GameState.is_damage_over_time(), "a marca não vaza para depois do tick")


func test_mu7_stays_readable_under_continuous_damage() -> void:
	_player = load(PLAYER_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(_player)
	var carry: float = 0.0
	var peak: float = 0.0
	for index: int in range(120):
		carry = GameState.apply_damage_over_time(30.0, TICK, carry)
		peak = maxf(peak, float(_player.call(&"flash_amount")))
		_player.call(&"_update_flash", TICK)
	assert_true(peak > 0.0, "dano contínuo ainda pisca de leve")
	assert_true(peak <= HitFlashRules.OVER_TIME + 0.001, "sem flash cheio a cada tick")
	GameState.apply_damage(1)
	assert_almost_eq(float(_player.call(&"flash_amount")), 1.0, 0.001, "golpe ainda pisca cheio")


func test_invincibility_blink_never_hides_the_mu7() -> void:
	_player = load(PLAYER_SCENE).instantiate()
	Engine.get_main_loop().root.add_child(_player)
	var sprite: CanvasItem = _player.get_node("AnimatedSprite2D")
	_player.set(&"_invincible_left", Balance.INVULNERABLE_TIME)
	var dimmed: bool = false
	for index: int in range(60):
		_player.call(&"_update_timers", TICK)
		assert_true(sprite.visible, "o MU-7 que renasce na doca nunca some")
		assert_true(sprite.modulate.a >= 0.39, "pisca só esmaecendo")
		dimmed = dimmed or sprite.modulate.a < 1.0
	assert_true(dimmed, "ainda pisca durante a invencibilidade")
	assert_almost_eq(sprite.modulate.a, 1.0, 0.001, "volta inteiro depois")
