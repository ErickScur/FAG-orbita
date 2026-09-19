extends SceneTree

const TESTS_DIR: String = "res://tests/"
const RUNNER_FILE: String = "run_tests.gd"
const CASE_FILE: String = "test_case.gd"
const FILTER_PREFIX: String = "--filter="

var _passed: int = 0
var _failed: int = 0
var _owned_autoloads: Array[Node] = []


func _initialize() -> void:
	await process_frame
	_ensure_autoloads()
	var filter: String = _read_filter()
	var suites: PackedStringArray = _list_suites(filter)
	if suites.is_empty():
		print("nenhuma suíte encontrada (filtro: '%s')" % filter)
	for path: String in suites:
		_run_suite(path)
	print("%d passed, %d failed" % [_passed, _failed])
	await _release_autoloads()
	quit(1 if _failed > 0 else 0)


func _release_autoloads() -> void:
	_silence(root)
	await create_timer(0.3).timeout
	for node: Node in _owned_autoloads:
		if is_instance_valid(node):
			root.remove_child(node)
			node.free()
	_owned_autoloads.clear()
	await process_frame


func _silence(node: Node) -> void:
	if node is AudioStreamPlayer:
		var player: AudioStreamPlayer = node
		player.stop()
		player.stream = null
	for child: Node in node.get_children():
		_silence(child)


func _read_filter() -> String:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(FILTER_PREFIX):
			return argument.substr(FILTER_PREFIX.length())
	return ""


func _ensure_autoloads() -> void:
	for property: Dictionary in ProjectSettings.get_property_list():
		var setting: String = String(property.get("name", ""))
		if not setting.begins_with("autoload/"):
			continue
		var node_name: String = setting.trim_prefix("autoload/")
		if node_name.is_empty() or root.has_node(NodePath(node_name)):
			continue
		var value: String = String(ProjectSettings.get_setting(setting, ""))
		var script_path: String = value.trim_prefix("*")
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


func _list_suites(filter: String) -> PackedStringArray:
	var found: PackedStringArray = []
	var dir := DirAccess.open(TESTS_DIR)
	if dir == null:
		push_error("run_tests: não foi possível abrir %s" % TESTS_DIR)
		return found
	for file_name: String in dir.get_files():
		if not file_name.begins_with("test_") or not file_name.ends_with(".gd"):
			continue
		if file_name == CASE_FILE or file_name == RUNNER_FILE:
			continue
		if not filter.is_empty() and not file_name.contains(filter):
			continue
		found.append(TESTS_DIR + file_name)
	found.sort()
	return found


func _run_suite(path: String) -> void:
	var file_name: String = path.get_file()
	var script: Script = load(path)
	if script == null:
		_failed += 1
		print("FAIL %s — não foi possível carregar o script" % file_name)
		return
	var instance: Variant = script.new()
	if not (instance is TestCase):
		_failed += 1
		print("FAIL %s — a suíte precisa herdar de TestCase" % file_name)
		return
	var suite: TestCase = instance
	for method_name: String in _test_methods(suite):
		suite.failures.clear()
		suite.before_each()
		suite.call(method_name)
		suite.after_each()
		if suite.failures.is_empty():
			_passed += 1
			print("PASS %s::%s" % [file_name, method_name])
		else:
			_failed += 1
			for message: String in suite.failures:
				print("FAIL %s::%s — %s" % [file_name, method_name, message])


func _test_methods(suite: TestCase) -> PackedStringArray:
	var names: PackedStringArray = []
	for method: Dictionary in suite.get_method_list():
		var method_name: String = String(method.get("name", ""))
		if not method_name.begins_with("test_"):
			continue
		var arguments: Array = method.get("args", [])
		if arguments.size() > 0:
			continue
		if names.has(method_name):
			continue
		names.append(method_name)
	names.sort()
	return names
