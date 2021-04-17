const _MAX_LOG_LENGTH = 450

static func debug(msg):
	print_debug('[DEBUG]' + _concat(msg))

static func info(msg):
	print('[INFO]' + _concat(msg))

static func warn(msg):
	print('[WARN]' + _concat(msg))

static func error(msg):
	printerr('[ERROR]' + _concat(msg))

static func _concat(msg):
	if len(msg) > _MAX_LOG_LENGTH:
		msg = msg.left(_MAX_LOG_LENGTH) + "... (concatenated)"
	return msg