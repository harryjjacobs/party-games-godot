extends CanvasLayer

onready var _pause_button = $PauseButton

func _ready():
	_pause_button.visible = false
	Events.connect("server_connection_state_changed", self, "_on_server_connection_state_changed")
	Events.connect("game_started", self, "_on_game_started")
	Events.connect("game_stopped", self, "_on_game_stopped")

func _on_server_connection_state_changed(state):
	if state == NetworkInterface.ConnectionState.DISCONNECTED:
		pass

func _on_game_started():
	_pause_button.visible = true

func _on_game_stopped():
	_pause_button.visible = false