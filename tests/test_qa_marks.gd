extends TestCase


func test_numbers_compare_by_value_across_int_and_float() -> void:
	assert_true(QAMarks.same_value(1, 1.0), "1 e 1.0")
	assert_true(QAMarks.same_value(50.0, 50.00001), "tolerância pequena")
	assert_false(QAMarks.same_value(50.0, 49.0), "valores diferentes")


func test_text_compares_string_and_string_name() -> void:
	assert_true(QAMarks.same_value(&"core_hub", "core_hub"), "StringName e String")
	assert_false(QAMarks.same_value(&"lab", "core_hub"), "textos diferentes")


func test_booleans_do_not_match_numbers() -> void:
	assert_true(QAMarks.same_value(true, true), "verdadeiro")
	assert_false(QAMarks.same_value(true, 1), "bool não vale número")
	assert_false(QAMarks.same_value(false, true), "falso")


func test_events_in_the_same_frame_keep_the_script_order() -> void:
	var raw: Array = [{"frame": 40, "quit": true}]
	for index: int in range(30):
		raw.append({"frame": 340, "step": index})
	raw.append({"frame": 1, "step": -1})
	raw.append("lixo")
	var ordered: Array[Dictionary] = QAMarks.ordered_events(raw)
	assert_eq(ordered.size(), 32, "só dicionários")
	assert_eq(int(ordered[0].get("step", 0)), -1, "quadro 1 primeiro")
	assert_true(ordered[1].has("quit"), "quadro 40 depois")
	for index: int in range(30):
		assert_eq(int(ordered[index + 2]["step"]), index, "mesmo quadro na ordem do roteiro")
