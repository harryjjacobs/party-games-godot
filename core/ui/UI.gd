extends Control

onready var _pause_button = $PauseButton

func _ready():
	_pause_button.visible = false
	var err = Events.connect("server_connection_state_changed", self, "_on_server_connection_state_changed")
	err = Events.connect("game_started", self, "_on_game_started")
	err = Events.connect("game_stopped", self, "_on_game_stopped")
	err = Events.connect("show_dialog", self, "_on_show_dialog")
	
	assert(err == OK)

func _on_server_connection_state_changed(state):
	if state == NetworkInterface.ConnectionState.DISCONNECTED:
		pass

func _on_game_started():
	_pause_button.visible = true

func _on_game_stopped():
	_pause_button.visible = false

func _on_show_dialog(dialog):
	add_child(dialog)
	dialog.popup_centered()
	yield(dialog, "finished")
	remove_child(dialog)
