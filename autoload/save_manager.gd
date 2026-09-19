extends Node

const SAVE_PATH: String = "user://save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	return false


func load_game() -> bool:
	return false


func delete_save() -> void:
	return
