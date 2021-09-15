extends "res://core/configuration/GameBuilder.gd"

export(Array, NodePath) var _stages 
export(Array, AudioStreamSample) var _background_music

func init(_gameplay_controller):
	pass

func build_stages() -> Array:
	var stages = []
	if _stages.empty():
		Log.debug("Warning: %s stage_stack is empty" % name)
	for stage in _stages:
		stages.append(get_node(stage))
	return stages

func build_background_music():
	return _background_music