class_name ScenePaths
extends RefCounted

const LEVELS_DIR: String = "res://scenes/levels/"
const MAIN_MENU: String = "res://scenes/ui/main_menu.tscn"
const LOADING: String = "res://scenes/boot/loading.tscn"
const SPLASH: String = "res://scenes/boot/splash.tscn"


static func is_level(path: String) -> bool:
	return path.begins_with(LEVELS_DIR) and path.ends_with(".tscn")


static func level_key(path: String) -> String:
	return path.get_file().get_basename()
