class_name DemoPlaylist
extends RefCounted

const FINAL_TOKEN: String = "{final}"
const FINALS: Array[String] = ["semeadura", "transmissao"]
const DEFAULT_FINAL: String = "semeadura"
const ADVANCE_ACTIONS: Array[String] = ["ui_accept", "interact", "jump"]
const TELEPORT_CALL: String = ".set_indexed"
const TELEPORT_PROPERTY: String = "global_position"
const HOLD_BASE: float = 1.5
const HOLD_PER_CHAR: float = 0.035
const HOLD_MAX: float = 5.0
const KEY_ID: String = "id"
const KEY_TITLE: String = "titulo"
const KEY_SCRIPT: String = "roteiro"
const KEY_WAIT: String = "espera_transicao"
const KEY_START: String = "inicio_s"
const TEST_KEYS: Array[String] = ["N", "R"]


static func parse(raw: Variant) -> Dictionary:
	var errors: PackedStringArray = []
	var chapters: Array = []
	var playlist_name: String = ""
	if not (raw is Dictionary):
		errors.append("playlist não é um objeto")
		return {"name": playlist_name, "chapters": chapters, "errors": errors}
	var data: Dictionary = raw
	playlist_name = String(data.get("nome", ""))
	var raw_chapters: Variant = data.get("capitulos", [])
	if not (raw_chapters is Array):
		errors.append("capitulos não é uma lista")
		return {"name": playlist_name, "chapters": chapters, "errors": errors}
	for entry: Variant in raw_chapters as Array:
		if not (entry is Dictionary):
			errors.append("capítulo inválido")
			continue
		var chapter: Dictionary = entry
		var script: String = String(chapter.get(KEY_SCRIPT, ""))
		if script.is_empty():
			errors.append("capítulo sem roteiro")
			continue
		chapters.append({
			"id": String(chapter.get(KEY_ID, "cap%d" % (chapters.size() + 1))),
			"title": String(chapter.get(KEY_TITLE, "")),
			"script": script,
			"wait_transition": maxf(0.0, float(chapter.get(KEY_WAIT, 0.0))),
			"start": float(chapter.get(KEY_START, -1.0)),
		})
	if chapters.is_empty():
		errors.append("playlist sem capítulos")
	return {"name": playlist_name, "chapters": chapters, "errors": errors}


static func chapter_index(chapters: Array, wanted: String) -> int:
	if wanted.is_empty():
		return 0 if not chapters.is_empty() else -1
	if wanted.is_valid_int():
		var number: int = int(wanted)
		if number >= 1 and number <= chapters.size():
			return number - 1
		return -1
	for index: int in range(chapters.size()):
		if String((chapters[index] as Dictionary).get("id", "")) == wanted:
			return index
	return -1


static func next_index(index: int, count: int) -> int:
	return mini(index + 1, count)


static func is_past_end(index: int, count: int) -> bool:
	return index >= count


static func valid_final(final_id: String) -> String:
	if FINALS.has(final_id):
		return final_id
	return DEFAULT_FINAL


static func script_path(chapter: Dictionary, final_id: String) -> String:
	return String(chapter.get("script", "")).replace(FINAL_TOKEN, valid_final(final_id))


static func is_advance_press(event: Dictionary) -> bool:
	if not event.has("action") or not bool(event.get("pressed", true)):
		return false
	return ADVANCE_ACTIONS.has(String(event.get("action", "")))


static func is_teleport(event: Dictionary) -> bool:
	if not String(event.get("call", "")).ends_with(TELEPORT_CALL):
		return false
	var args: Variant = event.get("args", [])
	if not (args is Array) or (args as Array).is_empty():
		return false
	return String((args as Array)[0]).begins_with(TELEPORT_PROPERTY)


static func teleport_frames(events: Array) -> Array[int]:
	var frames: Array[int] = []
	for entry: Variant in events:
		if entry is Dictionary and is_teleport(entry):
			var frame: int = int((entry as Dictionary).get("frame", 0))
			if not frames.has(frame):
				frames.append(frame)
	frames.sort()
	return frames


static func cut_alpha(frame: int, teleports: Array[int], lead: int, tail: int) -> float:
	var alpha: float = 0.0
	for teleport: int in teleports:
		if frame >= teleport - lead and frame <= teleport:
			alpha = maxf(alpha, float(frame - teleport + lead + 1) / float(lead + 1))
		elif frame > teleport and frame <= teleport + tail:
			alpha = maxf(alpha, 1.0 - float(frame - teleport) / float(tail + 1))
	return clampf(alpha, 0.0, 1.0)


static func reading_hold(chars: int) -> float:
	return clampf(HOLD_BASE + HOLD_PER_CHAR * float(maxi(chars, 0)), HOLD_BASE, HOLD_MAX)


static func can_freeze_after(frame: int, last_input_frame: int) -> bool:
	return last_input_frame < frame


static func clock(seconds: float) -> String:
	var total: int = maxi(0, int(seconds))
	return "%02d:%02d" % [total / 60, total % 60]


static func parse_pauses(spec: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: String in spec.split(",", false):
		var at: int = item.find("@")
		var colon: int = item.rfind(":")
		if at <= 0 or colon <= at + 1:
			continue
		var frame_text: String = item.substr(at + 1, colon - at - 1)
		var seconds_text: String = item.substr(colon + 1)
		if not frame_text.is_valid_int():
			continue
		var key: String = "P"
		var seconds: float = 0.0
		if TEST_KEYS.has(seconds_text):
			key = seconds_text
		elif seconds_text.is_valid_float():
			seconds = maxf(0.1, float(seconds_text))
		else:
			continue
		result.append({
			"chapter": item.substr(0, at),
			"frame": int(frame_text),
			"key": key,
			"seconds": seconds,
			"done": false,
		})
	return result
