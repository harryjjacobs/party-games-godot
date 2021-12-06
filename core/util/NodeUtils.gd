class_name NodeUtils

static func remove_children(node):
	for n in node.get_children():
		n.queue_free()

static func find_child_of_type(node, T):
	for n in node.get_children():
		if n is T:
			return n

