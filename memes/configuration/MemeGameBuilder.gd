extends GameBuilder

export(Array, NodePath) var _stages 
export(Array, AudioStreamSample) var _background_music

func build_background_music():
	return _background_music

func build_stages():
	var stages = []
	if _stages.empty():
		print_debug("Warning: %s stage_stack is empty" % name)
	for stage in _stages:
		stages.append(get_node(stage))
	return stages
