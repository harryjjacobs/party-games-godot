extends Control

const _MAIN_THEME = preload("res://core/ui/MainTheme.tres")

const _SIMULATION_RUNNER = preload("res://testing/simulation/SimulationRunner.tscn")

onready var _main_menu = $MainMenu
onready var _in_game_ui = $CanvasLayer/UI

var active_game

func _ready():
	var run_simulation = -1
	var args = _parse_arguments()
	if "run-simulation" in args:
		var game_id = args["run-simulation"]
		for game in GameTypes.Types.values():
			if game_id == GameTypes.STRING_IDS[game]:
				run_simulation = game
				break
	if run_simulation in GameTypes.Types.values():
		call_deferred("_run_simulation", run_simulation)
	else:
		_init_main_menu()

func _parse_arguments():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		var key_value
		if argument.find("=") > -1:
			key_value = argument.split("=")
		elif argument.find("=") > -1:
			key_value = argument.split(" ")
		else:
			printerr("Invalid command line arguments")
		arguments[key_value[0].lstrip("--")] = key_value[1]
	return arguments

func _init_main_menu():
	var _err = Events.connect("request_main_menu", self, "_on_request_main_menu")
	_err = _main_menu.connect("play", self, "_on_menu_request_play_game")
	_err = _main_menu.connect("exit", self, "_on_menu_request_exit")
	assert(_err == OK)
	_in_game_ui.theme = _MAIN_THEME
	_in_game_ui.visible = false
	var options = []
	for game in GameTypes.Types.values():
		options.push_back(GameSelectionOption.new(GameTypes.NAMES[game], game))
	_main_menu.init(options)

func _run_simulation(game):
	_play_game(game)
	var sim_runner = _SIMULATION_RUNNER.instance()
	get_tree().get_root().add_child(sim_runner)
	sim_runner.run(game, active_game)

func _play_game(game):
	_main_menu.visible = false
	_in_game_ui.visible = true
	active_game = GameTypes.SCENES[game].instance()
	_in_game_ui.theme = GameTypes.THEMES[game]
	get_tree().get_root().add_child(active_game)
	Events.emit_signal("game_started")
	Log.warn("GAME STARTED: " + GameTypes.NAMES[game])

func _on_menu_request_play_game(game):
	_play_game(game)

func _on_menu_request_exit():
	get_tree().quit()

func _on_request_main_menu(error_msg):
	_main_menu.visible = true
	_in_game_ui.visible = false
	_in_game_ui.theme = _MAIN_THEME
	if active_game and is_instance_valid(active_game):
		active_game.queue_free()
	Events.emit_signal("game_stopped")
	if error_msg:
		var dialog = preload("res://core/ui/dialogs/ErrorMessageDialog.tscn").instance()
		dialog.set_error_text(error_msg)
		Events.emit_signal("show_dialog",  dialog)
