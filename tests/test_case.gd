class_name TestCase
extends RefCounted

var failures: Array[String] = []


func before_each() -> void:
	return


func after_each() -> void:
	return


func fail(message: String) -> void:
	failures.append(message)


func assert_true(value: bool, message: String = "") -> void:
	if not value:
		fail(_describe(message, "esperado verdadeiro, obtido falso"))


func assert_false(value: bool, message: String = "") -> void:
	if value:
		fail(_describe(message, "esperado falso, obtido verdadeiro"))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail(_describe(message, "esperado %s, obtido %s" % [str(expected), str(actual)]))


func assert_ne(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		fail(_describe(message, "não deveria ser %s" % str(expected)))


func assert_almost_eq(
	actual: float, expected: float, tolerance: float = 0.001, message: String = ""
) -> void:
	if absf(actual - expected) > tolerance:
		fail(
			_describe(
				message, "esperado %s (±%s), obtido %s" % [str(expected), str(tolerance), str(actual)]
			)
		)


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail(_describe(message, "esperado valor não nulo"))


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail(_describe(message, "esperado nulo, obtido %s" % str(value)))


func _describe(message: String, detail: String) -> String:
	if message.is_empty():
		return detail
	return "%s — %s" % [message, detail]
