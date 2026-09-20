class_name DialogueData
extends RefCounted

const MODE_BLOCKING: StringName = &"blocking"
const MODE_AMBIENT: StringName = &"ambient"
const VALID_MODES: Array[StringName] = [MODE_BLOCKING, MODE_AMBIENT]
const MAX_LINE_CHARS: int = 110
const FORBIDDEN_WORDS: PackedStringArray = [
	"morreu", "morreram", "morta", "mortos", "selou", "40 pessoas", "quarentena definitiva"
]


static func empty() -> Dictionary:
	return {"sequences": {}, "logs": {}, "speakers": {}, "errors": PackedStringArray()}


static func load_file(path: String) -> Dictionary:
	var result: Dictionary = empty()
	var errors: PackedStringArray = result["errors"]
	if not FileAccess.file_exists(path):
		errors.append("arquivo ausente: %s" % path)
		result["errors"] = errors
		return result
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (parsed is Dictionary):
		errors.append("JSON inválido: %s" % path)
		result["errors"] = errors
		return result
	var data: Dictionary = parsed
	var sequences: Dictionary = result["sequences"]
	for key: Variant in data.get("sequences", {}) as Dictionary:
		sequences[StringName(key)] = (data["sequences"] as Dictionary)[key]
	var speakers: Dictionary = result["speakers"]
	for key: Variant in data.get("speakers", {}) as Dictionary:
		speakers[StringName(key)] = (data["speakers"] as Dictionary)[key]
	var logs: Dictionary = result["logs"]
	for value: Variant in data.get("logs", []) as Array:
		if not (value is Dictionary):
			errors.append("log inválido em %s" % path)
			continue
		var entry: Dictionary = value
		var log_id: StringName = StringName(String(entry.get("id", "")))
		if log_id == &"":
			errors.append("log sem id em %s" % path)
			continue
		logs[log_id] = entry
	result["errors"] = errors
	return result


static func load_dir(path: String) -> Dictionary:
	var loaded: Array = []
	var dir := DirAccess.open(path)
	if dir == null:
		var missing: Dictionary = empty()
		missing["errors"] = PackedStringArray(["diretório ausente: %s" % path])
		return missing
	var files: PackedStringArray = dir.get_files()
	files.sort()
	for file_name: String in files:
		if not file_name.ends_with(".json"):
			continue
		loaded.append(load_file(path.path_join(file_name)))
	return merge(loaded)


static func merge(dicts: Array) -> Dictionary:
	var result: Dictionary = empty()
	var errors: PackedStringArray = result["errors"]
	for value: Variant in dicts:
		if not (value is Dictionary):
			continue
		var data: Dictionary = value
		for group: String in ["sequences", "logs", "speakers"]:
			var target: Dictionary = result[group]
			for key: Variant in data.get(group, {}) as Dictionary:
				if target.has(key):
					errors.append("id duplicado em %s: %s" % [group, key])
				target[key] = (data[group] as Dictionary)[key]
		for message: String in data.get("errors", PackedStringArray()) as PackedStringArray:
			errors.append(message)
	result["errors"] = errors
	return result


static func validate(
	sequences: Dictionary, logs: Dictionary, speakers: Dictionary
) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key: Variant in sequences:
		var sequence: Variant = sequences[key]
		if not (sequence is Dictionary):
			errors.append("sequência '%s' não é um objeto" % key)
			continue
		var data: Dictionary = sequence
		var mode: StringName = StringName(String(data.get("mode", "")))
		if not VALID_MODES.has(mode):
			errors.append("sequência '%s': modo inválido '%s'" % [key, mode])
		var lines: Array = data.get("lines", [])
		if lines.is_empty():
			errors.append("sequência '%s' sem linhas" % key)
		for value: Variant in lines:
			if not (value is Dictionary):
				errors.append("sequência '%s': linha inválida" % key)
				continue
			var line: Dictionary = value
			var speaker: StringName = StringName(String(line.get("speaker", "")))
			if not speakers.has(speaker):
				errors.append("sequência '%s': falante desconhecido '%s'" % [key, speaker])
			if String(line.get("text", "")).strip_edges().is_empty():
				errors.append("sequência '%s': linha sem texto" % key)
	for key: Variant in logs:
		var entry: Dictionary = logs[key]
		var author: StringName = StringName(String(entry.get("author", "")))
		if not speakers.has(author):
			errors.append("log '%s': autor desconhecido '%s'" % [key, author])
		if (entry.get("lines", []) as Array).is_empty():
			errors.append("log '%s' sem linhas" % key)
		if String(entry.get("title", "")).strip_edges().is_empty():
			errors.append("log '%s' sem título" % key)
	return errors


static func wrap_length_errors(sequences: Dictionary, max_chars: int) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key: Variant in sequences:
		var data: Dictionary = sequences[key]
		for value: Variant in data.get("lines", []) as Array:
			var text: String = String((value as Dictionary).get("text", ""))
			if text.length() > max_chars:
				errors.append("sequência '%s': linha com %d caracteres" % [key, text.length()])
	return errors


static func log_length_errors(logs: Dictionary, max_chars: int) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key: Variant in logs:
		for value: Variant in (logs[key] as Dictionary).get("lines", []) as Array:
			var text: String = String(value)
			if text.length() > max_chars:
				errors.append("log '%s': linha com %d caracteres" % [key, text.length()])
	return errors


static func forbidden_word_errors(logs: Dictionary, words: PackedStringArray) -> PackedStringArray:
	var errors: PackedStringArray = []
	for key: Variant in logs:
		for value: Variant in (logs[key] as Dictionary).get("lines", []) as Array:
			var text: String = String(value).to_lower()
			for word: String in words:
				if text.contains(word.to_lower()):
					errors.append("log '%s': palavra proibida '%s'" % [key, word])
	return errors


static func sequence_mode(sequences: Dictionary, sequence_id: StringName) -> StringName:
	var data: Variant = sequences.get(sequence_id, {})
	if not (data is Dictionary):
		return MODE_BLOCKING
	return StringName(String((data as Dictionary).get("mode", MODE_BLOCKING)))


static func log_to_sequence(entry: Dictionary) -> Dictionary:
	var lines: Array = []
	for value: Variant in entry.get("lines", []) as Array:
		lines.append({"speaker": String(entry.get("author", "helena")), "text": String(value)})
	return {
		"mode": String(MODE_BLOCKING),
		"once": false,
		"header": header_for(entry),
		"unlock_ability": String(entry.get("unlock_ability", "")),
		"lines": lines,
	}


static func header_for(entry: Dictionary) -> String:
	var title: String = String(entry.get("title", ""))
	var subtitle: String = String(entry.get("subtitle", ""))
	if subtitle.is_empty():
		return title
	return "%s · %s" % [title, subtitle]
