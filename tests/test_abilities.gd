extends TestCase

const LOGS_PATH: String = "res://data/logs/greenhouse.json"

var _unlocked: Array[StringName] = []


func before_each() -> void:
	GameState.abilities = []
	_unlocked = []
	EventBus.ability_unlocked.connect(_on_ability_unlocked)


func after_each() -> void:
	EventBus.ability_unlocked.disconnect(_on_ability_unlocked)
	GameState.abilities = []


func test_unlock_adds_and_emits() -> void:
	assert_true(GameState.unlock_ability(ClimbLogic.ABILITY_ID), "primeiro destrave")
	assert_true(GameState.abilities.has(ClimbLogic.ABILITY_ID), "está na lista")
	assert_eq(_unlocked.size(), 1, "emitiu uma vez")


func test_unlock_is_idempotent() -> void:
	GameState.unlock_ability(ClimbLogic.ABILITY_ID)
	assert_false(GameState.unlock_ability(ClimbLogic.ABILITY_ID), "segundo destrave")
	assert_eq(_unlocked.size(), 1, "não reemite ao reler o log")
	assert_eq(GameState.abilities.size(), 1, "não duplica")


func test_unlock_ignores_empty_id() -> void:
	assert_false(GameState.unlock_ability(&""), "id vazio")
	assert_eq(_unlocked.size(), 0, "nada emitido")


func test_has_ability() -> void:
	assert_false(GameState.has_ability(ClimbLogic.ABILITY_ID), "antes do log")
	GameState.unlock_ability(ClimbLogic.ABILITY_ID)
	assert_true(GameState.has_ability(ClimbLogic.ABILITY_ID), "depois do log")


func test_ability_survives_save_round_trip() -> void:
	GameState.unlock_ability(ClimbLogic.ABILITY_ID)
	var data: Dictionary = GameState.to_dict()
	GameState.abilities = []
	GameState.from_dict(data)
	assert_true(GameState.has_ability(ClimbLogic.ABILITY_ID), "garras no save")


func test_greenhouse_log_carries_the_ability() -> void:
	var data: Dictionary = DialogueData.load_file(LOGS_PATH)
	var logs: Dictionary = data.get("logs", {})
	var entry: Variant = logs.get(&"log_gh_02", null)
	assert_not_null(entry, "log da Helena")
	if entry is Dictionary:
		assert_eq(
			String((entry as Dictionary).get("unlock_ability", "")),
			String(ClimbLogic.ABILITY_ID),
			"log_gh_02 destrava as garras"
		)


func _on_ability_unlocked(ability_id: StringName) -> void:
	_unlocked.append(ability_id)
