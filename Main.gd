extends Control

enum Games { UNTITLED_MEME_GAME, MUSIQ }

const _GAME_SCENES = {
	Games.UNTITLED_MEME_GAME: preload("res://meme_game/Memes.tscn"),
	Games.MUSIQ: preload("res://musiq_game/Musiq.tscn")
}

const _GAME_NAMES = {
	Games.UNTITLED_MEME_GAME: "untitled meme game",
	Games.MUSIQ: "MusiQ"
}

const _GAME_THEMES = {
	Games.UNTITLED_MEME_GAME: preload("res://meme_game/ui/MemeGameTheme.tres"),
	Games.MUSIQ: preload("res://musiq_game/ui/MusiQTheme.tres")
}

const _MAIN_THEME = preload("res://core/ui/MainTheme.tres")

onready var _main_menu = $MainMenu
onready var _in_game_ui = $CanvasLayer/UI

var active_game

func _ready():
	var _err = Events.connect("request_main_menu", self, "_on_request_main_menu")
	_err = _main_menu.connect("play", self, "_on_menu_request_play_game")
	_err = _main_menu.connect("exit", self, "_on_menu_request_exit")
	assert(_err == OK)

	_in_game_ui.visible = false
	_init_main_menu()

func _init_main_menu():
	var options = []
	for game in Games.values():
		options.push_back(GameSelectionOption.new(_GAME_NAMES[game], game))
	_main_menu.init(options)

func _on_menu_request_play_game(game):
	_main_menu.visible = false
	_in_game_ui.visible = true
	active_game = _GAME_SCENES[game].instance()
	_in_game_ui.theme = _GAME_THEMES[game]
	get_tree().get_root().add_child(active_game)
	Events.emit_signal("game_started")

func _on_menu_request_exit():
	get_tree().quit()

func _on_request_main_menu(error_msg):
	_main_menu.visible = true
	_in_game_ui.visible = false
	_in_game_ui.theme = _MAIN_THEME
	if active_game:
		active_game.queue_free()
	Events.emit_signal("game_stopped")
	if error_msg:
		var dialog = preload("res://core/ui/dialogs/ErrorMessageDialog.tscn").instance()
		dialog.set_error_text(error_msg)
		Events.emit_signal("show_dialog",  dialog)
