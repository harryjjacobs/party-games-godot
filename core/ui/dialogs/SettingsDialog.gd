extends WindowDialog

onready var _master_volume_slider = $ScrollContainer/VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
onready var _music_volume_slider = $ScrollContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider


func _ready():
	assert(Events.connect("open_settings", self, "_on_request_open_settings_menu") == OK)
	_initialise_values()

func _on_request_open_settings_menu():
	popup_centered()

func _on_SettingsDialog_hide():
	Settings.save()

func _initialise_values():
	_master_volume_slider.value = db2linear(Settings.get_master_volume()) * 100.0
	_music_volume_slider.value = db2linear(Settings.get_music_volume()) * 100.0

func _on_MasterVolumeSlider_value_changed(value: float):
	Settings.set_master_volume(linear2db(value / 100.0))

func _on_MusicVolumeSlider_value_changed(value: float):
	Settings.set_music_volume(linear2db(value / 100.0))