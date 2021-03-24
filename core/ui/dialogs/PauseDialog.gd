extends WindowDialog

func _ready():
	assert(Events.connect("game_paused", self, "_on_game_paused") == OK)
	assert(Events.connect("game_resumed", self, "_on_game_resumed") == OK)

func _on_game_paused():
	popup_centered()

func _on_game_resumed():
	if visible:
		visible = false

# ui signals

func _on_popup_hide():
	if get_tree().paused:
		Events.emit_signal("request_resume")

func _on_resume_button_pressed():
	Events.emit_signal("request_resume")
		
func _on_settings_button_pressed():
	pass

func _on_exit_button_pressed():
	pass

