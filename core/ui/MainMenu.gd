extends Control

const _meme_game_scene = preload("res://meme_game/Memes.tscn")

onready var confirmation_dialog = $ConfirmationDialog

var active_game

func _ready():
	var _err = Events.connect("request_main_menu", self, "_request_main_menu")

func _on_play_button_pressed():
	visible = false
	active_game = _meme_game_scene.instance()
	get_tree().get_root().add_child(active_game)

func _on_exit_button_pressed():
	confirmation_dialog.title = "Quit?"
	confirmation_dialog.subtitle = "Are you are you want to exit the game?"
	confirmation_dialog.yes_text = "Yes"
	confirmation_dialog.no_text = "No"
	confirmation_dialog.popup_centered()
	var quit = yield(confirmation_dialog, "finished")
	if quit:
		get_tree().quit()

func _request_main_menu():
	visible = true
	if active_game:
		active_game.queue_free()
