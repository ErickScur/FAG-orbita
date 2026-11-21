extends TestCase

const FONT_PATH: String = "res://assets/fonts/ui_font.ttf"
const TUTORIAL_PATH: String = "res://data/tutorial.json"
const OPTIONS_TEXTS: String = "res://data/ui/options.json"
const DEFAULT_LABELS: Dictionary = {
	&"move_left": "[A]",
	&"move_right": "[D]",
	&"move_up": "[W]",
	&"move_down": "[S]",
	&"jump": "[ESPAÇO]",
	&"dash": "[SHIFT]",
	&"interact": "[E]",
	&"beam": "[Q]",
	&"flashlight": "[F]",
	&"map": "[TAB]",
	&"log_archive": "[L]",
	&"pause": "[ESC]",
}


func after_each() -> void:
	InputMap.load_from_project_settings()


func _defaults() -> Dictionary:
	return KeyBindings.default_layout()


func test_every_game_action_is_remappable_with_its_documented_key() -> void:
	var layout: Dictionary = _defaults()
	for action: StringName in DEFAULT_LABELS:
		assert_true(KeyBindings.is_remappable(action), "%s remapeável" % action)
		assert_eq(
			KeyBindings.key_label(KeyBindings.primary_of(layout, action)),
			DEFAULT_LABELS[action],
			"tecla padrão de %s (GDD-2.4)" % action
		)
	assert_eq(KeyBindings.REMAPPABLE.size(), DEFAULT_LABELS.size(), "as 12 ações do jogo")


func test_arrows_stay_fixed_as_second_movement_key() -> void:
	var layout: Dictionary = _defaults()
	assert_eq(KeyBindings.reserved_by(layout, KEY_LEFT), &"move_left", "seta esquerda")
	assert_eq(KeyBindings.reserved_by(layout, KEY_UP), &"move_up", "seta cima")
	assert_eq(KeyBindings.reserved_by(layout, KEY_K), &"", "K livre")


func test_assign_free_key() -> void:
	var outcome: Dictionary = KeyBindings.assign(_defaults(), &"jump", KEY_K)
	assert_eq(outcome["result"], KeyBindings.RESULT_ASSIGNED, "tecla livre")
	assert_eq(KeyBindings.primary_of(outcome["layout"], &"jump"), KEY_K, "pulo em K")


func test_assign_key_of_another_action_swaps_both() -> void:
	var outcome: Dictionary = KeyBindings.assign(_defaults(), &"jump", KEY_E)
	assert_eq(outcome["result"], KeyBindings.RESULT_SWAPPED, "conflito detectado")
	assert_eq(outcome["other"], &"interact", "conflito com INTERAGIR")
	var layout: Dictionary = outcome["layout"]
	assert_eq(KeyBindings.primary_of(layout, &"jump"), KEY_E, "pulo em E")
	assert_eq(KeyBindings.primary_of(layout, &"interact"), KEY_SPACE, "interagir em ESPAÇO")


func test_no_action_ever_loses_its_key() -> void:
	var layout: Dictionary = _defaults()
	var keys: Array[int] = [KEY_E, KEY_Q, KEY_K, KEY_SPACE, KEY_A, KEY_TAB, KEY_J]
	for index: int in range(keys.size()):
		var action: StringName = KeyBindings.REMAPPABLE[index % KeyBindings.REMAPPABLE.size()]
		layout = KeyBindings.assign(layout, action, keys[index])["layout"]
	var seen: Dictionary = {}
	for action: StringName in KeyBindings.REMAPPABLE:
		var code: int = KeyBindings.primary_of(layout, action)
		assert_true(code > 0, "%s ficou sem tecla" % action)
		assert_false(seen.has(code), "%s repete a tecla de %s" % [action, seen.get(code, "")])
		seen[code] = action


func test_reserved_arrow_is_refused() -> void:
	var layout: Dictionary = _defaults()
	var outcome: Dictionary = KeyBindings.assign(layout, &"jump", KEY_UP)
	assert_eq(outcome["result"], KeyBindings.RESULT_RESERVED, "seta é fixa")
	assert_eq(outcome["other"], &"move_up", "de SUBIR")
	assert_eq(KeyBindings.primary_of(outcome["layout"], &"jump"), KEY_SPACE, "nada mudou")


func test_same_key_and_invalid_key() -> void:
	var layout: Dictionary = _defaults()
	assert_eq(
		KeyBindings.assign(layout, &"jump", KEY_SPACE)["result"],
		KeyBindings.RESULT_UNCHANGED, "mesma tecla"
	)
	assert_eq(KeyBindings.assign(layout, &"jump", 0)["result"], KeyBindings.RESULT_INVALID, "zero")
	assert_eq(
		KeyBindings.assign(layout, &"ui_accept", KEY_K)["result"],
		KeyBindings.RESULT_INVALID, "ação de interface não é remapeável"
	)


func test_overrides_round_trip() -> void:
	var defaults: Dictionary = _defaults()
	var layout: Dictionary = KeyBindings.assign(defaults, &"jump", KEY_K)["layout"]
	layout = KeyBindings.assign(layout, &"dash", KEY_E)["layout"]
	var saved: Dictionary = KeyBindings.overrides(layout, defaults)
	assert_eq(saved.size(), 3, "pulo, impulso e interagir mudaram")
	var restored: Dictionary = KeyBindings.apply_overrides(defaults, saved)
	for action: StringName in KeyBindings.REMAPPABLE:
		assert_eq(
			KeyBindings.primary_of(restored, action),
			KeyBindings.primary_of(layout, action),
			"%s volta igual do arquivo" % action
		)


func test_sanitize_drops_garbage() -> void:
	var clean: Dictionary = KeyBindings.sanitize({
		"jump": KEY_K,
		"ui_accept": KEY_J,
		"dash": "x",
		"beam": -3,
		"map": 75.0,
	})
	assert_eq(clean, {"jump": KEY_K, "map": 75}, "só ação do jogo com tecla válida")
	assert_eq(KeyBindings.sanitize("lixo"), {}, "arquivo corrompido")


func test_write_layout_changes_input_map_and_keeps_joypad() -> void:
	var joypad_before: int = _joypad_events(&"jump")
	var layout: Dictionary = KeyBindings.assign(_defaults(), &"jump", KEY_K)["layout"]
	KeyBindings.write_layout(layout)
	assert_eq(KeyBindings.primary_of(KeyBindings.read_layout(), &"jump"), KEY_K, "InputMap")
	assert_eq(_joypad_events(&"jump"), joypad_before, "botão do controle preservado")
	var press := KeyBindings.make_event(KEY_K)
	press.pressed = true
	assert_true(press.is_action_pressed(&"jump"), "K aciona o pulo")
	var space := KeyBindings.make_event(KEY_SPACE)
	space.pressed = true
	assert_false(space.is_action(&"jump"), "ESPAÇO não pula mais")
	var arrows: Dictionary = KeyBindings.read_layout()
	assert_true(
		(arrows[&"move_left"][KeyBindings.KEY_FIXED] as Array).has(KEY_LEFT), "seta continua"
	)


func test_relabel_follows_the_current_key() -> void:
	var defaults: Dictionary = _defaults()
	assert_eq(KeyBindings.relabel("[ESPAÇO]", [&"jump"]), "[ESPAÇO]", "padrão")
	var layout: Dictionary = KeyBindings.assign(defaults, &"jump", KEY_K)["layout"]
	layout = KeyBindings.assign(layout, &"move_left", KEY_D)["layout"]
	KeyBindings.write_layout(layout)
	assert_eq(KeyBindings.relabel("[ESPAÇO]", [&"jump"]), "[K]", "pulo remapeado")
	assert_eq(
		KeyBindings.relabel("[A] [D] ou [SETAS]", [&"move_left", &"move_right"]),
		"[D] [A] ou [SETAS]",
		"troca sem atropelar"
	)
	assert_eq(InteractionRules.glyph(false), "[E]", "prompt de interação intacto")
	assert_eq(KeyBindings.action_label(&"jump"), "[K]", "rótulo da ação")
	layout = KeyBindings.assign(layout, &"interact", KEY_R)["layout"]
	KeyBindings.write_layout(layout)
	assert_eq(InteractionRules.glyph(false), "[R]", "prompt de interação segue a tecla")
	assert_eq(InteractionRules.glyph(true), "[X]", "controle não muda")


func test_tutorial_cards_unchanged_with_default_keys() -> void:
	var catalog: Dictionary = TutorialData.load_all(TUTORIAL_PATH)
	for tutorial_id: StringName in catalog:
		var entry: Dictionary = TutorialData.entry(tutorial_id, catalog)
		var key: String = String(entry["key"])
		assert_eq(
			KeyBindings.relabel(key, TutorialData.actions_of(tutorial_id, catalog)),
			key,
			"cartão %s muda sem remapeamento" % tutorial_id
		)


func test_labels_and_texts_use_glyphs_the_pixel_font_has() -> void:
	var font: FontFile = load(FONT_PATH) as FontFile
	assert_not_null(font, "fonte pixel")
	if font == null:
		return
	var texts: PackedStringArray = []
	for code: int in range(KEY_A, KEY_Z + 1):
		texts.append(KeyBindings.key_label(code))
	for code: int in range(KEY_0, KEY_9 + 1):
		texts.append(KeyBindings.key_label(code))
	for code: Variant in KeyBindings.KEY_NAMES:
		texts.append(KeyBindings.key_label(int(code)))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(OPTIONS_TEXTS))
	assert_true(parsed is Dictionary, "textos das opções")
	if parsed is Dictionary:
		_collect_strings(parsed, texts)
	for text: String in texts:
		for index: int in range(text.length()):
			var code: int = text.unicode_at(index)
			assert_true(font.has_char(code), "'%s' usa '%s', fora da m5x7" % [text, char(code)])


func _collect_strings(value: Variant, into: PackedStringArray) -> void:
	if value is String:
		into.append(value)
	elif value is Dictionary:
		for item: Variant in (value as Dictionary).values():
			_collect_strings(item, into)
	elif value is Array:
		for item: Variant in value as Array:
			_collect_strings(item, into)


func _joypad_events(action: StringName) -> int:
	var count: int = 0
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			count += 1
	return count
