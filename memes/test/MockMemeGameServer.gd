extends Node

const PORT = 6541
const MAX_LOG_LENGTH = 300
var _server = WebSocketServer.new()

signal message_received(client_id, message)

func _ready():
	# Connect base signals to get notified of new client connections,
	# disconnections, and disconnect requests.
	_server.connect("client_connected", self, "_connected")
	_server.connect("client_disconnected", self, "_disconnected")
	_server.connect("client_close_request", self, "_close_request")
	# This signal is emitted when not using the Multiplayer API every time a
	# full packet is received.
	# Alternatively, you could check get_peer(PEER_ID).get_available_packets()
	# in a loop for each connected peer.
	_server.connect("data_received", self, "_on_data")
	# Start listening on the given port.
	var err = _server.listen(PORT)
	if err != OK:
			print("Unable to start server")
			set_process(false)

func _connected(id, proto):
		# This is called when a new peer connects, "id" will be the assigned peer id,
		# "proto" will be the selected WebSocket sub-protocol (which is optional)
		print("Client %d connected with protocol: %s" % [id, proto])

func _close_request(id, code, reason):
		# This is called when a client notifies that it wishes to close the connection,
		# providing a reason string and close code.
		print("Client %d disconnecting with code: %d, reason: %s" % [id, code, reason])

func _disconnected(id, was_clean = false):
		# This is called when a client disconnects, "id" will be the one of the
		# disconnecting client, "was_clean" will tell you if the disconnection
		# was correctly notified by the remote peer before closing the socket.
		print("Client %d disconnected, clean: %s" % [id, str(was_clean)])

func _on_data(conn_id):
		# Print the received packet, you MUST always use get_peer(id).get_packet to receive data,
		# and not get_packet directly when not using the MultiplayerAPI.
		var pkt = _server.get_peer(conn_id).get_packet()
		var data_str = pkt.get_string_from_utf8()
		var log_msg = data_str
		if len(log_msg) > MAX_LOG_LENGTH:
			log_msg = log_msg.left(MAX_LOG_LENGTH) + "... (concatenated)"
		print("[%s] Received data from client %d: %s" % [name, conn_id, log_msg])
		var parse_result = JSON.parse(pkt.get_string_from_utf8())
		assert(parse_result.error == OK)
		emit_signal("message_received", conn_id, parse_result.result)

func _process(_delta):
		# Call this in _process or _physics_process.
		# Data transfer, and signals emission will only happen when calling this function.
		_server.poll()

func send_message(conn_id, message):
	_server.get_peer(conn_id).put_packet(JSON.print(message).to_utf8())