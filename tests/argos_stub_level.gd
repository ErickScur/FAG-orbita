extends Node2D

var meta: Dictionary = {}


func meta_value(key: String) -> Variant:
	return meta.get(key, null)
