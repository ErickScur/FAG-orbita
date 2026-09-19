extends Control

const STEP: float = 0.25
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Voice"]

@onready var track_label: Label = %TrackLabel
@onready var master_label: Label = %MasterLabel
@onready var music_label: Label = %MusicLabel
@onready var sfx_label: Label = %SfxLabel
@onready var voice_label: Label = %VoiceLabel


func _ready() -> void:
	AudioManager.play_music(&"menu", 0.0)
	_refresh()


func _process(_delta: float) -> void:
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed():
		return
	if event.is_action("ui_left"):
		_nudge_music(-STEP)
	elif event.is_action("ui_right"):
		_nudge_music(STEP)
	elif event.is_action("ui_accept"):
		AudioManager.play_sfx(&"ui_confirm")
	elif event.is_action("ui_cancel"):
		AudioManager.play_sfx(&"ui_back")


func _nudge_music(amount: float) -> void:
	AudioManager.set_bus_volume(&"Music", clampf(Settings.music_volume + amount, 0.0, 1.0))
	AudioManager.play_sfx(&"ui_move")


func _refresh() -> void:
	var track: StringName = AudioManager.current_music()
	track_label.text = "TRILHA: %s" % ("nenhuma" if track == &"" else String(track))
	master_label.text = _bus_text("MASTER", &"Master")
	music_label.text = _bus_text("MÚSICA", &"Music")
	sfx_label.text = _bus_text("EFEITOS", &"SFX")
	voice_label.text = _bus_text("VOZ", &"Voice")


func _bus_text(title: String, bus: StringName) -> String:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return "%s: AUSENTE" % title
	if AudioServer.is_bus_mute(index):
		return "%s: MUDO (%.1f dB)" % [title, AudioServer.get_bus_volume_db(index)]
	return "%s: %.2f (%.1f dB)" % [
		title, AudioManager.get_bus_volume(bus), AudioServer.get_bus_volume_db(index)
	]
