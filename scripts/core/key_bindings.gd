class_name KeyBindings
extends RefCounted

const REMAPPABLE: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_up",
	&"move_down",
	&"jump",
	&"dash",
	&"interact",
	&"beam",
	&"flashlight",
	&"map",
	&"log_archive",
	&"pause",
]
const RESULT_ASSIGNED: StringName = &"assigned"
const RESULT_SWAPPED: StringName = &"swapped"
const RESULT_UNCHANGED: StringName = &"unchanged"
const RESULT_RESERVED: StringName = &"reserved"
const RESULT_INVALID: StringName = &"invalid"
const KEY_PRIMARY: String = "primary"
const KEY_FIXED: String = "fixed"
const PROJECT_INPUT_PREFIX: String = "input/"
const UNKNOWN_KEY: String = "?"
const KEY_NAMES: Dictionary = {
	KEY_SPACE: "ESPAÇO",
	KEY_ESCAPE: "ESC",
	KEY_SHIFT: "SHIFT",
	KEY_TAB: "TAB",
	KEY_UP: "CIMA",
	KEY_DOWN: "BAIXO",
	KEY_LEFT: "ESQUERDA",
	KEY_RIGHT: "DIREITA",
	KEY_ENTER: "ENTER",
	KEY_KP_ENTER: "ENTER",
	KEY_CTRL: "CTRL",
	KEY_ALT: "ALT",
	KEY_META: "CMD",
	KEY_BACKSPACE: "APAGAR",
	KEY_CAPSLOCK: "CAPS",
	KEY_DELETE: "DEL",
}


static func is_remappable(action: StringName) -> bool:
	return REMAPPABLE.has(action)


static func entry(primary: int, fixed: Array = []) -> Dictionary:
	var keys: Array[int] = []
	for code: Variant in fixed:
		if int(code) > 0 and int(code) != primary:
			keys.append(int(code))
	return {KEY_PRIMARY: primary, KEY_FIXED: keys}


static func primary_of(layout: Dictionary, action: StringName) -> int:
	var data: Dictionary = layout.get(action, {})
	return int(data.get(KEY_PRIMARY, 0))


static func owner_of(layout: Dictionary, keycode: int, except: StringName = &"") -> StringName:
	for action: Variant in layout:
		if StringName(action) == except:
			continue
		if primary_of(layout, StringName(action)) == keycode:
			return StringName(action)
	return &""


static func reserved_by(layout: Dictionary, keycode: int) -> StringName:
	for action: Variant in layout:
		var data: Dictionary = layout[action]
		if (data.get(KEY_FIXED, []) as Array).has(keycode):
			return StringName(action)
	return &""


static func assign(layout: Dictionary, action: StringName, keycode: int) -> Dictionary:
	var result: Dictionary = {"result": RESULT_INVALID, "other": &"", "layout": layout}
	if keycode <= 0 or not layout.has(action):
		return result
	if primary_of(layout, action) == keycode:
		result["result"] = RESULT_UNCHANGED
		return result
	var reserving: StringName = reserved_by(layout, keycode)
	if reserving != &"":
		result["result"] = RESULT_RESERVED
		result["other"] = reserving
		return result
	var updated: Dictionary = layout.duplicate(true)
	var previous: int = primary_of(layout, action)
	var holder: StringName = owner_of(layout, keycode, action)
	updated[action][KEY_PRIMARY] = keycode
	result["layout"] = updated
	if holder == &"":
		result["result"] = RESULT_ASSIGNED
		return result
	updated[holder][KEY_PRIMARY] = previous
	result["result"] = RESULT_SWAPPED
	result["other"] = holder
	return result


static func overrides(layout: Dictionary, defaults: Dictionary) -> Dictionary:
	var changed: Dictionary = {}
	for action: Variant in layout:
		var code: int = primary_of(layout, StringName(action))
		if code > 0 and code != primary_of(defaults, StringName(action)):
			changed[String(action)] = code
	return changed


static func apply_overrides(defaults: Dictionary, saved: Dictionary) -> Dictionary:
	var layout: Dictionary = defaults.duplicate(true)
	for action: StringName in REMAPPABLE:
		var key: String = String(action)
		if not saved.has(key):
			continue
		layout = assign(layout, action, int(saved[key]))["layout"]
	return layout


static func sanitize(raw: Variant) -> Dictionary:
	var clean: Dictionary = {}
	if not (raw is Dictionary):
		return clean
	for key: Variant in raw as Dictionary:
		var action := StringName(String(key))
		var value: Variant = (raw as Dictionary)[key]
		if not is_remappable(action):
			continue
		if not (value is int or value is float):
			continue
		if int(value) <= 0:
			continue
		clean[String(action)] = int(value)
	return clean


static func event_keycode(event: InputEventKey) -> int:
	if event == null:
		return 0
	return event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode


static func make_event(keycode: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	return event


static func read_layout() -> Dictionary:
	var layout: Dictionary = {}
	for action: StringName in REMAPPABLE:
		if not InputMap.has_action(action):
			continue
		layout[action] = _entry_from_events(InputMap.action_get_events(action))
	return layout


static func default_layout() -> Dictionary:
	var layout: Dictionary = {}
	for action: StringName in REMAPPABLE:
		var setting: Variant = ProjectSettings.get_setting(PROJECT_INPUT_PREFIX + String(action))
		if not (setting is Dictionary):
			continue
		var events: Array[InputEvent] = []
		for event: Variant in (setting as Dictionary).get("events", []):
			if event is InputEvent:
				events.append(event)
		layout[action] = _entry_from_events(events)
	return layout


static func write_layout(layout: Dictionary) -> void:
	for action: Variant in layout:
		var name := StringName(action)
		if not InputMap.has_action(name):
			continue
		var others: Array[InputEvent] = []
		for event: InputEvent in InputMap.action_get_events(name):
			if not (event is InputEventKey):
				others.append(event)
		InputMap.action_erase_events(name)
		var data: Dictionary = layout[action]
		var primary: int = int(data.get(KEY_PRIMARY, 0))
		if primary > 0:
			InputMap.action_add_event(name, make_event(primary))
		for code: Variant in data.get(KEY_FIXED, []) as Array:
			InputMap.action_add_event(name, make_event(int(code)))
		for event: InputEvent in others:
			InputMap.action_add_event(name, event)


static func key_name(keycode: int) -> String:
	if keycode <= 0:
		return UNKNOWN_KEY
	if KEY_NAMES.has(keycode):
		return String(KEY_NAMES[keycode])
	var text: String = OS.get_keycode_string(keycode as Key).to_upper()
	return text if not text.is_empty() else UNKNOWN_KEY


static func key_label(keycode: int) -> String:
	return "[%s]" % key_name(keycode)


static func action_label(action: StringName) -> String:
	return key_label(primary_of(read_layout(), action))


static func relabel(text: String, actions: Array[StringName]) -> String:
	if text.is_empty() or actions.is_empty():
		return text
	var current: Dictionary = read_layout()
	var defaults: Dictionary = default_layout()
	var result: String = text
	var pending: Dictionary = {}
	for index: int in range(actions.size()):
		var action: StringName = actions[index]
		var old_label: String = key_label(primary_of(defaults, action))
		var new_label: String = key_label(primary_of(current, action))
		if old_label == new_label or not result.contains(old_label):
			continue
		var token: String = "\u0001%d\u0001" % index
		result = result.replace(old_label, token)
		pending[token] = new_label
	for token: Variant in pending:
		result = result.replace(String(token), String(pending[token]))
	return result


static func _entry_from_events(events: Array[InputEvent]) -> Dictionary:
	var keys: Array[int] = []
	for event: InputEvent in events:
		if event is InputEventKey:
			var code: int = event_keycode(event as InputEventKey)
			if code > 0 and not keys.has(code):
				keys.append(code)
	if keys.is_empty():
		return entry(0)
	return entry(keys[0], keys.slice(1))
