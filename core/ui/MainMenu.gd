extends Control
class_name MainMenu

signal play
signal exit

onready var _confirmation_dialog = $ConfirmationDialog
onready var _game_selection_dialog = $GameSelectionDialog

func init(game_selection_options):
	_game_selection_dialog.set_game_selection_options(game_selection_options)

func _on_play_button_pressed():
	_game_selection_dialog.popup_centered()
	var game_type = yield(_game_selection_dialog, "selected")
	emit_signal("play", game_type)

func _on_settings_button_pressed():
	Events.emit_signal("open_settings")

func _on_exit_button_pressed():
	_confirmation_dialog.title = "Quit?"
	_confirmation_dialog.subtitle = "Are you are you want to exit the game?"
	_confirmation_dialog.yes_text = "Yes"
	_confirmation_dialog.no_text = "No"
	_confirmation_dialog.popup_centered()
	var quit = yield(_confirmation_dialog, "finished")
	if quit:
		emit_signal("exit")
