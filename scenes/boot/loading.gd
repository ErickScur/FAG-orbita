extends Control

const DATA_PATH: String = "res://data/ui/loading.json"

const SYSTEM_LINES: Array[String] = [
	"SUPORTE DE VIDA",
	"SENSORES INTERNOS",
	"DISTRIBUIÇÃO DE ENERGIA",
	"MAPA DO SETOR",
]
const SYSTEM_PENDING_COLOR: Color = Color(0.435294, 0.509804, 0.560784)
const SYSTEM_READY_COLOR: Color = Color(0.372549, 0.831373, 0.784314)

@onready var sector_label: Label = %SectorName
@onready var bar: ProgressBar = %Bar
@onready var tip_label: Label = %Tip
@onready var systems_box: VBoxContainer = %Systems

var _path: String = ""
var _elapsed: float = 0.0
var _system_labels: Array[Label] = []


func _ready() -> void:
	var data: Dictionary = _load_data()
	_path = SceneManager.pending_path
	sector_label.text = _sector_name(data, _path)
	tip_label.text = _random_tip(data)
	bar.value = 0.0
	_build_system_lines()
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
	_refresh_system_lines(minf(bar.value / 100.0, _elapsed / Balance.LOADING_MIN_TIME))
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
	_refresh_system_lines(1.0)
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


func _build_system_lines() -> void:
	for line in SYSTEM_LINES:
		var label := Label.new()
		label.text = "[  ] " + line
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", SYSTEM_PENDING_COLOR)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		systems_box.add_child(label)
		_system_labels.append(label)


func _refresh_system_lines(ratio: float) -> void:
	var total: int = _system_labels.size()
	if total == 0:
		return
	var ready_count: int = clampi(int(ratio * float(total + 1)), 0, total)
	for i in range(total):
		var label: Label = _system_labels[i]
		var done: bool = i < ready_count
		var prefix: String = "[OK] " if done else "[  ] "
		label.text = prefix + SYSTEM_LINES[i]
		label.add_theme_color_override("font_color", SYSTEM_READY_COLOR if done else SYSTEM_PENDING_COLOR)
