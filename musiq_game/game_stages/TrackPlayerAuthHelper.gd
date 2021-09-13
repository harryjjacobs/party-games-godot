extends Object
class_name MusiQPlayerAuthHelper

const _authorization_dialog = preload("res://core/ui/dialogs/DefaultConfirmationDialog.tscn")
const _device_selection_dialog = preload("res://musiq_game/ui/dialogs/MusiQPlayerDeviceSelectionDialog.tscn")

var _musiq_player

var _handling_device_connection

func _init(musiq_player):
	_musiq_player = musiq_player
	_musiq_player.connect("requires_authorization", self, "_on_requires_authorization")
	_musiq_player.connect("requires_device_connection", self, "_on_requires_device_connection")
	_musiq_player.connect("authorization_succeeded", self, "_on_track_player_authorization_succeeded")
	_musiq_player.CheckAuth()

func _on_requires_authorization():
	var dialog = _authorization_dialog.instance()
	dialog.set_title("Connect your spotify account")
	dialog.set_yes_text("Login")
	dialog.set_no_text("Cancel (End Game)")
	Events.emit_signal("show_dialog",  dialog)
	var result = yield(dialog, "finished")
	if result:
		yield(_musiq_player.PerformAuthorization(), "completed")
	else:
		Events.emit_signal("request_main_menu")

func _on_track_player_authorization_succeeded():
	_musiq_player.CheckDeviceConnection()

func _on_requires_device_connection():
	if _handling_device_connection:
		return
	_handling_device_connection = true
	print("Searching for available devices...")
	var devices = yield(_musiq_player.GetAvailableDevicesForConnection(), "completed")
	var dialog = _device_selection_dialog.instance()
	dialog.connect("request_refresh", self, "_on_device_selection_dialog_request_refresh")
	Events.emit_signal("show_dialog",  dialog)
	dialog.set_devices(devices)
	var result = yield(dialog, "finished")
	if result:
		var connected = yield(_musiq_player.PerformDeviceConnection(result.Id), "completed")
		if not connected:
			_handling_device_connection = false
			_musiq_player.CheckDeviceConnection()
	else:
		_handling_device_connection = false
		Events.emit_signal("request_main_menu")

func _on_device_selection_dialog_request_refresh(dialog):
	var devices = yield(_musiq_player.GetAvailableDevicesForConnection(), "completed")
	dialog.set_devices(devices)

func is_ready_to_play():
	var authorized = yield(_musiq_player.CheckAuth(), "completed")
	if not authorized:
		return false
	var player_connected = yield(_musiq_player.CheckDeviceConnection(), "completed")
	return player_connected
