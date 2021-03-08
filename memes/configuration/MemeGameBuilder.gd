extends GameBuilder

export(Array, NodePath) var _stages 

func build_stages():
	var stages = []
	if _stages.empty():
		print_debug("Warning: %s stage_stack is empty" % name)
	for stage in _stages:
		stages.append(get_node(stage))
	return stages
