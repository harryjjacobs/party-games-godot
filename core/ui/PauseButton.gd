extends TextureButton

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_pressed():
	Events.emit_signal("request_pause")
	
func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_pressed()
