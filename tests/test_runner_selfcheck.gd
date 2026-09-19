extends TestCase

var _before_calls: int = 0


func before_each() -> void:
	_before_calls += 1


func test_before_each_runs() -> void:
	assert_true(_before_calls > 0, "before_each executado")


func test_assert_true_and_false() -> void:
	assert_true(true, "verdadeiro")
	assert_false(false, "falso")


func test_assert_eq_and_ne() -> void:
	assert_eq(2 + 2, 4, "soma")
	assert_eq(&"menu", &"menu", "StringName")
	assert_ne("a", "b", "diferentes")


func test_assert_almost_eq_tolerance() -> void:
	assert_almost_eq(0.1 + 0.2, 0.3, 0.0001, "ponto flutuante")


func test_assert_not_null() -> void:
	assert_not_null(RefCounted.new(), "instância")
	assert_null(null, "nulo")


func test_failures_are_collected_and_cleared() -> void:
	var probe := TestCase.new()
	probe.assert_true(false, "proposital")
	assert_eq(probe.failures.size(), 1, "uma falha registrada")
	assert_true(probe.failures[0].contains("proposital"), "mensagem preservada")
	probe.failures.clear()
	assert_eq(probe.failures.size(), 0, "limpo")
