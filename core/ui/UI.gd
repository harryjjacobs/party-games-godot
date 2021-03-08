extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = Events.connect("server_connection_state_changed", self, "_on_server_connection_state_changed")

func _on_server_connection_state_changed(state):
	if state == NetworkInterface.ConnectionState.DISCONNECTED:
		pass
