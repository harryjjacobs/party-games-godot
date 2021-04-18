extends Node

const PORT = 6541
var _server = WebSocketServer.new()

signal message_received(client_id, message)

func _ready():
	# Connect base signals to get notified of new client connections,
	# disconnections, and disconnect requests.
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	_server.connect("data_received", self, "_on_data")
	# Start listening on the given port.
	var err = _server.listen(PORT)
	if err != OK:
			Log.info("Unable to start server")
			set_process(false)

func _connected(id, proto):
		# This is called when a new peer connects, "id" will be the assigned peer id,
		# "proto" will be the selected WebSocket sub-protocol (which is optional)
		Log.info("Client %d connected with protocol: %s" % [id, proto])

func _close_request(id, code, reason):
		# This is called when a client notifies that it wishes to close the connection,
		# providing a reason string and close code.
		Log.info("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason])

func _disconnected(id, was_clean = false):
		# This is called when a client disconnects, "id" will be the one of the
		# disconnecting client, "was_clean" will tell you if the disconnection
		# was correctly notified by the remote peer before closing the socket.
		Log.info("Client %d disconnected, clean: %s" % [id, str(was_clean)])

func _on_data(conn_id):
		var pkt = _server.get_peer(conn_id).get_packet()
		var data_str = pkt.get_string_from_utf8()
		Log.info("[%s] Received data from client %d: %s" % [name, conn_id, data_str])
		var parse_result = JSON.parse(pkt.get_string_from_utf8())
		assert(parse_result.error == OK)
		emit_signal("message_received", conn_id, parse_result.result)

func _process(_delta):
		# Data transfer, and signals emission will only happen when calling this function.
		_server.poll()

func send_message(conn_id, message):
	_server.get_peer(conn_id).put_packet(JSON.print(message).to_utf8())