extends Node
class_name GameplayController

const GameStage = preload("res://core/game_stages/common/GameStage.gd")

export (PackedScene) onready var _game_builder_scene

var _stage_stack = []
var _current_stage: GameStage

func _ready():
	var _err = Events.connect("request_pause", self, "_on_request_pause")
	_err = Events.connect("request_resume", self, "_on_request_resume")
	_err = Events.connect("request_main_menu", self, "_on_request_main_menu")
	_err = Events.connect("request_restart", self, "_on_request_restart")
	_initialise_stage_stack()
	_begin()

func _exit_tree():
	for stage in _stage_stack:
		stage.queue_free()
	BackgroundMusic.pause()
	BackgroundMusic.clear_tracks()

func _initialise_stage_stack(game_builder = null):
	if not game_builder:
		game_builder = _game_builder_scene.instance()
	for stage in game_builder.build_stages():
		_stage_stack.push_back(stage)
		var parent = stage.get_parent()
		if parent:
			parent.remove_child(stage)
			game_builder.queue_free()
		Log.info("[%s] Stages initialised. Stage stack: " % name)
	for stage in _stage_stack:
		Log.info("- %s" % stage.name)
	var music_tracks = game_builder.build_background_music()
	BackgroundMusic.clear_tracks()
	BackgroundMusic.add_tracks(music_tracks)
	Log.info("[%s] Background music initialised. %d tracks added" % [name, len(music_tracks)])

func _begin():
	_next_stage({})

func _next_stage(params):
	if _stage_stack.empty():
		return
	if _current_stage:
		_current_stage.exit()
		remove_child(_current_stage)
		Log.info("Stage %s exited" % _current_stage.name)
	var old_stage = _current_stage
	_current_stage = _stage_stack.pop_front()
	var _err = _current_stage.connect("request_exit", self, "_on_stage_request_exit")
	Log.info("Stage %s entered" % _current_stage.name)
	add_child(_current_stage)
	_current_stage.enter(params)
	Events.emit_signal("gamestage_changed", old_stage, _current_stage)

func _end_current_game(preserve_room = false):
	Log.info("Ending current game")
	if _current_stage:
		_current_stage.exit()
		remove_child(_current_stage)
		Log.info("Stage %s exited" % _current_stage.name)
	if not preserve_room:
		Log.debug("Disconnecting from server...")
		NetworkInterface.disconnect_from_server()
		Log.debug("Disconnected")

func _restart_current_game(preserve_room):
	_end_current_game(preserve_room)
	_initialise_stage_stack()
	if preserve_room:
		for stage in _stage_stack:
			if stage is LobbyStage:
				_stage_stack.erase(stage)
				break
	_begin()

func _on_stage_request_exit(params):
	_next_stage(params)

func _on_request_pause():
	Events.emit_signal("game_paused")
	get_tree().paused = true

func _on_request_resume():
	get_tree().paused = false
	Events.emit_signal("game_resumed")

func _on_request_main_menu():
	_end_current_game()

func _on_request_restart(keep_players):
	_restart_current_game(keep_players)
