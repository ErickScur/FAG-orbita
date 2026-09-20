class_name Fx
extends RefCounted

const DUST_PUFF: String = "res://scenes/fx/dust_puff.tscn"
const PICKUP_SPARKLE: String = "res://scenes/fx/pickup_sparkle.tscn"
const POWER_PULSE: String = "res://scenes/fx/power_pulse.tscn"
const DUST_TINT: Color = Color(0.792157, 0.827451, 0.858824, 0.72549)
const SPARKLE_TINT: Color = Color(0.937255, 0.898039, 0.478431, 1.0)
const PULSE_TINT: Color = Color(0.74902, 0.901961, 1.0, 1.0)


static func burst(host: Node, scene_path: String, at: Vector2, tint: Color) -> SparkBurst:
	var parent: Node = _parent_for(host)
	if parent == null or not ResourceLoader.exists(scene_path):
		return null
	var packed: PackedScene = load(scene_path)
	if packed == null:
		return null
	var instance: Node = packed.instantiate()
	if not (instance is SparkBurst):
		instance.free()
		return null
	var burst_node: SparkBurst = instance
	parent.add_child(burst_node)
	burst_node.emit(at, tint, true)
	return burst_node


static func _parent_for(host: Node) -> Node:
	if host == null or not host.is_inside_tree():
		return null
	var parent: Node = host.get_parent()
	if parent is CanvasItem:
		return parent
	if host is CanvasItem:
		return host
	return null
