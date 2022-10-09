extends Object
class_name MusiQPlayerAuthHelper

const AUTH_DIALOG = preload("res://core/ui/dialogs/DefaultConfirmationDialog.tscn")
const DEVICE_DIALOG = preload("res://musiq_game/ui/dialogs/MusiQPlayerDeviceSelectionDialog.tscn")

var _musiq_player

var _auth_dialog
var _device_dialog
var _handling_device_connection

func _init(musiq_player):
	_musiq_player = musiq_player
	_musiq_player.connect("requires_authorization", self, "_on_requires_authorization")
	_musiq_player.connect("requires_device_connection", self, "_on_requires_device_connection")
	_musiq_player.connect("authorization_succeeded", self, "_on_track_player_authorization_succeeded")
	_musiq_player.connect("ready_to_play", self, "_on_musiq_player_ready")
	_musiq_player.CheckAuth()

func _on_requires_authorization():
	_auth_dialog = AUTH_DIALOG.instance()
	_auth_dialog.set_title("Connect your spotify account")
	_auth_dialog.set_yes_text("Login")
	_auth_dialog.set_no_text("Cancel (End Game)")
	Events.emit_signal("show_dialog", _auth_dialog)
	var result = yield(_auth_dialog, "finished")
	if result:
		yield(_musiq_player.PerformAuthorization(), "completed")
	else:
		Events.emit_signal("request_main_menu", null)

func _on_track_player_authorization_succeeded():
	pass
	# _musiq_player.CheckDeviceConnection()

func _on_requires_device_connection():
	if _handling_device_connection:
		return
	_handling_device_connection = true
	Log.info("Searching for available devices...")
	var devices = yield(_musiq_player.GetAvailableDevicesForConnection(), "completed")
	_device_dialog = DEVICE_DIALOG.instance()
	_device_dialog.connect("request_refresh", self, "_on_device_selection_dialog_request_refresh")
	Events.emit_signal("show_dialog",  _device_dialog)
	_device_dialog.set_devices(devices)
	var result = yield(_device_dialog, "finished")
	if result:
		var connected = yield(_musiq_player.PerformDeviceConnection(result.Id), "completed")
		if not connected:
			_handling_device_connection = false
			_musiq_player.CheckDeviceConnection()
	else:
		_handling_device_connection = false
		Events.emit_signal("request_main_menu", null)

func _on_device_selection_dialog_request_refresh(dialog):
	var devices = yield(_musiq_player.GetAvailableDevicesForConnection(), "completed")
	dialog.set_devices(devices)

func _on_musiq_player_ready():
	if _auth_dialog:
		_auth_dialog.hide()
	if _device_dialog:
		_device_dialog.hide()
