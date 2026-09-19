class_name DifficultyText
extends RefCounted

const NORMAL_TEXT: String = "Valores originais do jogo"
const NO_TIMER_TEXT: String = "O reator não perde estabilidade com o tempo"
const SLOWER: String = "mais devagar"
const FASTER: String = "mais rápido"


static func describe(difficulty: StringName) -> String:
	var damage: float = Balance.difficulty_damage_multiplier(difficulty)
	var reactor: float = Balance.difficulty_reactor_multiplier(difficulty)
	if is_equal_approx(damage, 1.0) and is_equal_approx(reactor, 1.0):
		return NORMAL_TEXT
	var delta: int = roundi(absf(reactor - 1.0) * 100.0)
	var direction: String = SLOWER if reactor < 1.0 else FASTER
	return "Dano recebido %d%% · Reator cai %d%% %s" % [roundi(damage * 100.0), delta, direction]


static func no_timer_hint() -> String:
	return NO_TIMER_TEXT
