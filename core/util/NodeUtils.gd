class_name NodeUtils

static func remove_children(node):
	for n in node.get_children():
		n.queue_free()
