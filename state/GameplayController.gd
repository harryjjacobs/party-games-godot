extends Node
class_name GameplayController

const GameState = preload("res://state/GameState.gd")

export (PackedScene) onready var _game_configuration_scene

var _state_stack = []
var _current_state: GameState

func _ready():
	_initialise()
	_begin()

func _exit_tree():
	for state in _state_stack:
		state.queue_free()

func _initialise(configuration = null):
	if not configuration:
		configuration = _game_configuration_scene.instance()
	if configuration:
		for state in configuration.get_state_stack():
			_state_stack.push_back(state)
			var parent = state.get_parent()
			if parent:
				parent.remove_child(state)
		configuration.queue_free()

func _begin():
	_next_state()

func _next_state():
	if _state_stack.empty():
		return
	if _current_state:
		_current_state.exit()
		remove_child(_current_state)
		print("State %s exited" % _current_state.name)
	var old_state = _current_state
	_current_state = _state_stack.pop_front()
	var _err = _current_state.connect("request_exit", self, "_on_state_request_exit")
	add_child(_current_state)
	_current_state.enter()
	print("State %s entered" % _current_state.name)
	Events.emit_signal("gamestate_changed", old_state, _current_state)

func _on_state_request_exit():
	_next_state()