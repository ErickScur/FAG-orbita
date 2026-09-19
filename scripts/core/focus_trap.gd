class_name FocusTrap
extends RefCounted

var _suspended: Array[Dictionary] = []


func capture(allowed: Array[Control]) -> void:
	if allowed.is_empty():
		return
	var tree: SceneTree = allowed[0].get_tree()
	if tree == null:
		return
	for node in tree.root.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null or allowed.has(control):
			continue
		if control.focus_mode == Control.FOCUS_NONE:
			continue
		_suspended.append({"control": control, "mode": control.focus_mode})
		control.focus_mode = Control.FOCUS_NONE
	_link(allowed)


func release() -> void:
	for entry in _suspended:
		var control: Control = entry["control"]
		if is_instance_valid(control):
			control.focus_mode = entry["mode"]
	_suspended.clear()


func _link(allowed: Array[Control]) -> void:
	var total: int = allowed.size()
	for i in range(total):
		var current: Control = allowed[i]
		var previous: NodePath = current.get_path_to(allowed[(i - 1 + total) % total])
		var next: NodePath = current.get_path_to(allowed[(i + 1) % total])
		current.focus_neighbor_left = previous
		current.focus_neighbor_top = previous
		current.focus_previous = previous
		current.focus_neighbor_right = next
		current.focus_neighbor_bottom = next
		current.focus_next = next
