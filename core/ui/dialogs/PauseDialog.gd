extends WindowDialog

onready var confirmation_dialog = $ConfirmationDialog

func _ready():
	var _err = Events.connect("game_paused", self, "_on_game_paused")
	_err = Events.connect("game_resumed", self, "_on_game_resumed")
	assert(_err == OK)

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_game_resumed()

func _on_game_paused():
	popup_centered()

func _on_game_resumed():
	if visible:
		hide()

# ui signals

func _on_popup_hide():
	if get_tree().paused:
		Events.emit_signal("request_resume")

func _on_resume_button_pressed():
	Events.emit_signal("request_resume")
		
func _on_settings_button_pressed():
	Events.emit_signal("open_settings")

func _on_exit_button_pressed():
	confirmation_dialog.title = "Exit to main menu?"
	confirmation_dialog.subtitle = "Are you are you want to exit to the main menu? The current game will end."
	confirmation_dialog.yes_text = "Yes"
	confirmation_dialog.no_text = "No"
	confirmation_dialog.popup_centered()
	var exit = yield(confirmation_dialog, "finished")
	if exit:
		hide()
		Events.emit_signal("request_main_menu", null)

