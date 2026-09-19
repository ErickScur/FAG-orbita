extends Node

const VERSION: int = 1
const DEFAULT_SAVE_PATH: String = "user://save.json"
const TOAST_SCENE: String = "res://scenes/ui/save_toast.tscn"
const SAVED_MESSAGE: String = "BACKUP SALVO"

var save_path: String = DEFAULT_SAVE_PATH

var _toast: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.checkpoint_reached.connect(_on_checkpoint_reached)
	EventBus.sector_restored.connect(_on_sector_restored)
	_spawn_toast()


func has_save() -> bool:
	return not _read_validated().is_empty()


func is_corrupted() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	return _read_validated().is_empty()


func save_game() -> bool:
	var payload: Dictionary = {
		"version": VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"state": GameState.to_dict(),
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: não foi possível escrever %s" % save_path)
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true


func load_game() -> bool:
	var data: Dictionary = _read_validated()
	if data.is_empty():
		return false
	GameState.from_dict(data.get("state", {}))
	return true


func delete_save() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var error: int = DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if error != OK:
		push_warning("SaveManager: não foi possível apagar %s (%d)" % [save_path, error])


func read_header() -> Dictionary:
	var data: Dictionary = _read_validated()
	if data.is_empty():
		return {"exists": false, "saved_at": 0, "scene": "", "reactor": 0.0}
	var state: Dictionary = data.get("state", {})
	var raw_checkpoint: Variant = state.get("checkpoint", {})
	var checkpoint: Dictionary = {}
	if raw_checkpoint is Dictionary:
		checkpoint = raw_checkpoint
	return {
		"exists": true,
		"saved_at": int(data.get("saved_at", 0)),
		"scene": String(checkpoint.get("scene", "")),
		"reactor": float(state.get("reactor_percent", 0.0)),
	}


func show_saved_toast() -> void:
	if _toast == null or not is_instance_valid(_toast):
		return
	_toast.call(&"show_toast", SAVED_MESSAGE)


func _read_validated() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var text: String = FileAccess.get_file_as_string(save_path)
	if text.is_empty():
		push_warning("SaveManager: backup vazio em %s" % save_path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		push_warning("SaveManager: backup corrompido em %s" % save_path)
		return {}
	var data: Dictionary = parsed
	if int(data.get("version", -1)) != VERSION:
		push_warning("SaveManager: versão de backup desconhecida em %s" % save_path)
		return {}
	if not (data.get("state", null) is Dictionary):
		push_warning("SaveManager: backup sem estado em %s" % save_path)
		return {}
	return data


func _spawn_toast() -> void:
	if not ResourceLoader.exists(TOAST_SCENE):
		return
	var packed: PackedScene = load(TOAST_SCENE)
	if packed == null:
		return
	var instance: Node = packed.instantiate()
	if not (instance is CanvasLayer):
		instance.free()
		return
	_toast = instance
	add_child(_toast)


func _on_checkpoint_reached(_checkpoint_id: StringName) -> void:
	_request_save()


func _on_sector_restored(_sector_id: StringName) -> void:
	_request_save()


func _request_save() -> void:
	_commit_save.call_deferred()


func _commit_save() -> void:
	if not save_game():
		return
	show_saved_toast()
