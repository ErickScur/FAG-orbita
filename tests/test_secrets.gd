extends TestCase

const GAME_STATE_SCRIPT: String = "res://autoload/game_state.gd"
const WALL_SCENE: String = "res://scenes/world/secret_wall.tscn"
const SECRET_A: StringName = &"gh_secret_01"
const SECRET_B: StringName = &"core_secret_01"

var _state: Node = null


func before_each() -> void:
	_state = load(GAME_STATE_SCRIPT).new()
	_state.new_game()


func after_each() -> void:
	if _state != null:
		_state.free()
		_state = null


func test_register_new_secret_returns_true() -> void:
	assert_true(_state.register_secret(SECRET_A))
	assert_true(_state.has_secret(SECRET_A))
	assert_eq(_state.secrets_found(), 1)


func test_register_same_secret_twice_returns_false() -> void:
	assert_true(_state.register_secret(SECRET_A))
	assert_false(_state.register_secret(SECRET_A))
	assert_eq(_state.secrets_found(), 1)


func test_register_ignores_empty_id() -> void:
	assert_false(_state.register_secret(&""))
	assert_false(_state.has_secret(&""))
	assert_eq(_state.secrets_found(), 0)


func test_unknown_secret_is_not_found() -> void:
	assert_true(_state.register_secret(SECRET_A))
	assert_false(_state.has_secret(SECRET_B))


func test_two_secrets_are_counted_apart() -> void:
	assert_true(_state.register_secret(SECRET_A))
	assert_true(_state.register_secret(SECRET_B))
	assert_eq(_state.secrets_found(), 2)


func test_secrets_survive_to_dict_from_dict() -> void:
	_state.register_secret(SECRET_A)
	var text: String = JSON.stringify(_state.to_dict())
	var loaded: Node = load(GAME_STATE_SCRIPT).new()
	loaded.from_dict(JSON.parse_string(text))
	var found: bool = loaded.has_secret(SECRET_A)
	var count: int = loaded.secrets_found()
	loaded.free()
	assert_true(found)
	assert_eq(count, 1)


func test_new_game_clears_secrets() -> void:
	_state.register_secret(SECRET_A)
	_state.new_game()
	assert_false(_state.has_secret(SECRET_A))
	assert_eq(_state.secrets_found(), 0)


func test_stats_report_secrets_over_total() -> void:
	_state.register_secret(SECRET_A)
	var stats: Dictionary = _state.get_stats()
	assert_eq(int(stats.get("secrets", 0)), 1)
	assert_eq(int(stats.get("secrets_total", 0)), Balance.SECRETS_TOTAL)
	var lines: PackedStringArray = stats.get("lines", PackedStringArray())
	assert_true("\n".join(lines).contains("SEGREDOS   1/4"))


func test_walls_share_one_group_per_secret() -> void:
	var scene: PackedScene = load(WALL_SCENE)
	var first: SecretWall = scene.instantiate()
	var second: SecretWall = scene.instantiate()
	var other: SecretWall = scene.instantiate()
	first.secret_id = SECRET_A
	second.secret_id = SECRET_A
	other.secret_id = SECRET_B
	var same: bool = first.group_name() == second.group_name()
	var apart: bool = first.group_name() != other.group_name()
	var named: bool = String(first.group_name()) == "secret_" + String(SECRET_A)
	first.free()
	second.free()
	other.free()
	assert_true(same)
	assert_true(apart)
	assert_true(named)


func test_reveal_drops_collision_and_alpha() -> void:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		fail("sem SceneTree para montar a parede")
		return
	var wall: SecretWall = load(WALL_SCENE).instantiate()
	wall.secret_id = SECRET_A
	tree.root.add_child(wall)
	var solid_before: bool = wall.collision_layer == SecretWall.WALL_LAYER
	wall.reveal(true)
	var revealed: bool = wall.is_revealed()
	var alpha: float = wall.modulate.a
	var in_group: bool = wall.is_in_group(wall.group_name())
	wall.free()
	assert_true(solid_before)
	assert_true(revealed)
	assert_true(in_group)
	assert_almost_eq(alpha, Balance.SECRET_WALL_ALPHA)


func test_capacitor_raises_charge_max() -> void:
	assert_almost_eq(_state.charge_max, Balance.CHARGE_MAX)
	_state.expand_charge_max(Balance.CAPACITOR_BONUS)
	assert_almost_eq(_state.charge_max, Balance.CHARGE_MAX + Balance.CAPACITOR_BONUS)
