extends Node

const _FILE_NAME = "user://settings.cfg"

var _config: ConfigFile

func _ready():
	_config = _load_config_file()

func save():
	_save_config_file()

func set_master_volume(db):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
	_config.set_value("audio", "master_volume", db)

func get_master_volume():
	return _config.get_value("audio", "master_volume", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))

func set_music_volume(db):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Background"), db)
	_config.set_value("audio", "music_volume", db)

func get_music_volume():
	return _config.get_value("audio", "music_volume", AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Background")))

func _load_config_file():
	var config = ConfigFile.new()
	var err = config.load(_FILE_NAME)
	if err != OK:
		Log.warn("Could not load settings file. It may not exist yet.")
	return config

func _save_config_file():
	var err = _config.save(_FILE_NAME)
	if err != OK:
		printerr("Error saving settings file")
		return
	Log.info("Saved settings")
