extends SceneTree

const LEVELS_DIR: String = "res://data/levels/"
const REACHABILITY_SCRIPT: String = "res://scripts/core/level_reachability.gd"
const LEVEL_PREFIX: String = "--level="
const LEGEND_TEXT: String = "legenda: '_' apoio alcançável · '.' célula tocada pelo corpo"

var _owned_autoloads: Array[Node] = []


func _initialize() -> void:
	await process_frame
	_ensure_autoloads()
	var reach: Script = load(REACHABILITY_SCRIPT)
	var failures: int = 0
	for path: String in _levels():
		var started: int = Time.get_ticks_msec()
		var result: Dictionary = reach.call(&"analyze_file", path)
		var elapsed: int = Time.get_ticks_msec() - started
		print("== %s (%d ms)" % [path.get_file(), elapsed])
		print(reach.call(&"render", result))
		print(LEGEND_TEXT)
		var missing: Array = reach.call(&"unreachable_pickups", result)
		missing.append_array(reach.call(&"unreachable_interactables", result))
		for item: Variant in missing:
			print("INALCANÇÁVEL " + String(reach.call(&"describe", item)))
		failures += missing.size()
		if missing.is_empty():
			print("tudo alcançável")
	await _release_autoloads()
	quit(1 if failures > 0 else 0)


func _levels() -> PackedStringArray:
	var found: PackedStringArray = []
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(LEVEL_PREFIX):
			var name: String = argument.substr(LEVEL_PREFIX.length())
			found.append(LEVELS_DIR + name.get_basename() + ".txt")
	if not found.is_empty():
		return found
	for file_name: String in DirAccess.get_files_at(LEVELS_DIR):
		if file_name.ends_with(".txt"):
			found.append(LEVELS_DIR + file_name)
	found.sort()
	return found


func _ensure_autoloads() -> void:
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting: String = String(property.get("name", ""))
		if not setting.begins_with("autoload/"):
			continue
		var node_name: String = setting.trim_prefix("autoload/")
		if node_name.is_empty() or root.has_node(NodePath(node_name)):
			continue
		var script_path: String = String(ProjectSettings.get_setting(setting, "")).trim_prefix("*")
		if script_path.is_empty() or not ResourceLoader.exists(script_path):
			continue
		var script: Script = load(script_path)
		if script == null:
			continue
		var instance: Variant = script.new()
		if not (instance is Node):
			continue
		var node: Node = instance
		node.name = node_name
		root.add_child(node)
		_owned_autoloads.append(node)


func _release_autoloads() -> void:
	for node: Node in _owned_autoloads:
		if is_instance_valid(node):
			root.remove_child(node)
			node.free()
	_owned_autoloads.clear()
	await process_frame
