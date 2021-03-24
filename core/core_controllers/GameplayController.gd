extends Node
class_name GameplayController

const GameStage = preload("res://core/game_stages/common/GameStage.gd")

export (PackedScene) onready var _game_builder_scene

var _stage_stack = []
var _current_stage: GameStage

func _ready():
	var _err = Events.connect("request_pause", self, "_on_request_pause")
	_err = Events.connect("request_resume", self, "_on_request_resume")

	_initialise()
	_begin()

func _exit_tree():
	for stage in _stage_stack:
		stage.queue_free()

func _initialise(game_builder = null):
	if not game_builder:
		game_builder = _game_builder_scene.instance()
	for stage in game_builder.build_stages():
		_stage_stack.push_back(stage)
		var parent = stage.get_parent()
		if parent:
			parent.remove_child(stage)
			game_builder.queue_free()
	print("[%s] Stages initialised. Stage stack: " % name)
	for stage in _stage_stack:
		print("- %s" % stage.name)
	var music_tracks = game_builder.build_background_music()
	BackgroundMusic.clear_tracks()
	BackgroundMusic.add_tracks(music_tracks)
	print("[%s] Background music initialised. %d tracks added" % [name, len(music_tracks)])

func _begin():
	_next_stage({})

func _next_stage(params):
	if _stage_stack.empty():
		return
	if _current_stage:
		_current_stage.exit()
		remove_child(_current_stage)
		print("Stage %s exited" % _current_stage.name)
	var old_stage = _current_stage
	_current_stage = _stage_stack.pop_front()
	var _err = _current_stage.connect("request_exit", self, "_on_stage_request_exit")
	print("Stage %s entered" % _current_stage.name)
	add_child(_current_stage)
	_current_stage.enter(params)
	Events.emit_signal("gamestage_changed", old_stage, _current_stage)

func _on_stage_request_exit(params):
	_next_stage(params)

func _on_request_pause():
	Events.emit_signal("game_paused")
	get_tree().paused = true

func _on_request_resume():
	get_tree().paused = false
	Events.emit_signal("game_resumed")

func _on_request_main_menu():
	pass