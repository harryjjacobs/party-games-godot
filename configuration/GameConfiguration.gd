class_name GameConfiguration
extends Node

export(Array, NodePath) var _state_stack

func get_state_stack():
  var state_stack = []
  if _state_stack.empty():
    print_debug("Warning: %s state_stack is empty" % name)
  for state_path in _state_stack:
    state_stack.push_back(get_node(state_path))
  return state_stack