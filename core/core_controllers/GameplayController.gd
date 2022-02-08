extends Node
class_name GameplayController

const GameStage = preload("res://core/game_stages/common/GameStage.gd")

export (PackedScene) onready var _game_builder_scene

var _stage_history = []
var _stage_stack = []
var _current_stage: GameStage

func _ready():
	var _err = Events.connect("request_pause", self, "_on_request_pause")
	_err = Events.connect("request_resume", self, "_on_request_resume")
	_err = Events.connect("request_main_menu", self, "_on_request_main_menu")
	_err = Events.connect("request_restart", self, "_on_request_restart")
	_err = Events.connect("outdated_protocol_version", self, "_on_outdated_protocol_version")
	assert(_err == OK)

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
	_stage_stack = []
	_stage_history = []
	for stage in game_builder.build_stages():
		_push_stage(stage)
	game_builder.queue_free()
	Log.info("[%s] Stages initialised. Stage stack: " % name)
	for stage in _stage_stack:
		Log.info("- %s" % stage.name)
	var music_tracks = game_builder.build_background_music()
	BackgroundMusic.clear_tracks()
	BackgroundMusic.add_tracks(music_tracks)
	Log.info("[%s] Background music initialised. %d tracks added" % [name, len(music_tracks)])

func _begin():
	_perform_stage_transition({})

func _perform_stage_transition(params):
	var transition = GameStage.StageExitTransition.NEXT_STAGE
	if _current_stage:
		transition = _exit_stage(_current_stage)
	match transition:
		GameStage.StageExitTransition.REPEAT_STAGE:
			_stage_stack.push_front(_current_stage)
		GameStage.StageExitTransition.REPEAT_GROUP:
			var group = _current_stage.get_group_name()
			# return all stages between this stage and the next stage with the same group
			var stages = []
			var found_group_start = false
			for stage in _stage_history:	# skip current stage
				if stage != _current_stage and group == stage.get_group_name():
					found_group_start = true
				elif found_group_start:
					break
				stages.push_back(stage)
			if found_group_start:
				for stage in stages:
					_stage_stack.push_front(stage)
					_stage_history.remove(_stage_history.find(stage))
		_:
			pass
	if _stage_stack.empty():
		Log.warn("Cannot perform stage transition. Stage stack empty.")
		return
	var old_stage = _current_stage
	_current_stage = _stage_stack.pop_front()
	_stage_history.push_front(_current_stage)
	if not _current_stage.is_connected("request_exit", self, "_on_stage_request_exit"):
		var _err = _current_stage.connect("request_exit", self, "_on_stage_request_exit")
	Log.info("Stage %s entered" % _current_stage.name)
	add_child(_current_stage)
	_current_stage.enter(params)
	Events.emit_signal("gamestage_changed", old_stage, _current_stage)
	Log.info("Stage stack: %s" % _print_stage_stack())

func _push_stage(stage):
	_stage_stack.push_back(stage)
	var parent = stage.get_parent()
	if parent:
		parent.remove_child(stage)

func _end_current_game(preserve_room = false):
	Log.info("Ending current game")
	if _current_stage:
		_exit_stage(_current_stage)
		_current_stage = null
	if not preserve_room:
		Log.debug("Disconnecting from server...")
		NetworkInterface.disconnect_from_server()
		Log.debug("Disconnected")

func _exit_stage(stage):
	var exit_transition
	if stage.is_inside_tree():
		remove_child(stage)
		exit_transition = stage.exit()
		Log.info("Stage %s exited" % _current_stage.name)
	return exit_transition

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
	_perform_stage_transition(params)

func _on_request_pause():
	Events.emit_signal("game_paused")
	get_tree().paused = true

func _on_request_resume():
	get_tree().paused = false
	Events.emit_signal("game_resumed")

func _on_request_main_menu(_error_msg):
	_end_current_game()
	
func _on_request_restart(keep_players):
	_restart_current_game(keep_players)

func _on_outdated_protocol_version():
	Events.emit_signal("request_main_menu", "Outdated application version. Please update game to the latest version.")

func _print_stage_stack():
	var stack = PoolStringArray()
	for stage in _stage_stack:
		stack.append(stage.name)
	return stack.join(", ")
		
