extends WindowDialog

onready var _master_volume_slider = $ScrollContainer/VBoxContainer/MasterVolumeContainer/MasterVolumeSlider
onready var _music_volume_slider = $ScrollContainer/VBoxContainer/MusicVolumeContainer/MusicVolumeSlider
onready var _fullscreen_checkbox = $ScrollContainer/VBoxContainer/FullscreenContainer/FullscreenCheckBox

func _ready():
	var _err = Events.connect("open_settings", self, "_on_request_open_settings_menu")
	assert(_err == OK)
	_initialise_values()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide()
		accept_event()	

func _on_request_open_settings_menu():
	popup_centered()

func _on_SettingsDialog_hide():
	Settings.save()

func _initialise_values():
	_master_volume_slider.value = db2linear(Settings.get_master_volume()) * 100.0
	_music_volume_slider.value = db2linear(Settings.get_music_volume()) * 100.0
	_fullscreen_checkbox.pressed = Settings.get_fullscreen()
	
func _on_MasterVolumeSlider_value_changed(value: float):
	Settings.set_master_volume(linear2db(value / 100.0))

func _on_MusicVolumeSlider_value_changed(value: float):
	Settings.set_music_volume(linear2db(value / 100.0))

func _on_FullscreenCheckBox_toggled(button_pressed):
	Settings.set_fullscreen(button_pressed)
