extends Control

const DATA_PATH: String = "res://data/ui/loading.json"

@onready var sector_label: Label = %SectorName
@onready var bar: ProgressBar = %Bar
@onready var tip_label: Label = %Tip

var _path: String = ""
var _elapsed: float = 0.0


func _ready() -> void:
	var data: Dictionary = _load_data()
	_path = SceneManager.pending_path
	sector_label.text = _sector_name(data, _path)
	tip_label.text = _random_tip(data)
	bar.value = 0.0
	if _path.is_empty():
		set_process(false)
		return
	if ResourceLoader.load_threaded_request(_path) != OK:
		set_process(false)
		SceneManager.abort_loading("requisição de carregamento recusada")


func _process(delta: float) -> void:
	_elapsed += delta
	var progress: Array = []
	var status: int = ResourceLoader.load_threaded_get_status(_path, progress)
	if progress.size() > 0:
		bar.value = float(progress[0]) * 100.0
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			if _elapsed >= Balance.LOADING_MIN_TIME:
				_complete()
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			set_process(false)
			SceneManager.abort_loading("recurso inválido")


func _complete() -> void:
	set_process(false)
	bar.value = bar.max_value
	var packed: Variant = ResourceLoader.load_threaded_get(_path)
	SceneManager.finish_loading(packed as PackedScene)


func _load_data() -> Dictionary:
	if not FileAccess.file_exists(DATA_PATH):
		return {}
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		return parsed
	return {}


func _sector_name(data: Dictionary, path: String) -> String:
	if path.is_empty():
		return ""
	var names: Dictionary = data.get("sector_names", {})
	return String(names.get(ScenePaths.level_key(path), ""))


func _random_tip(data: Dictionary) -> String:
	var tips: Array = data.get("tips", [])
	if tips.is_empty():
		return ""
	return String(tips[randi() % tips.size()])
