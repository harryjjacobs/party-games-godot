extends Node

const _MAX_LOG_LENGTH = 450

func debug(msg):
	print_debug('[DEBUG] ' + _concat(msg))

func info(msg):
	print('[INFO] ' + _concat(msg))

func warn(msg):
	print('[WARN] ' + _concat(msg))

func error(msg):
	printerr('[ERROR] ' + _concat(msg))

func _concat(msg):
	if len(msg) > _MAX_LOG_LENGTH:
		msg = msg.left(_MAX_LOG_LENGTH) + "... (concatenated)"
	return msg