extends Node

const WEBSOCKET_URL = "ws://localhost:8080/players"

signal connection_state(state)
signal message_received(message)

var _client = WebSocketClient.new()

var client_id
var username

func _ready():
	client_id = UUID.v4()
	username = UUID.v4().split("-")[0]
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_connected")
	_client.connect("data_received", self, "_on_data")
	
	var _err = connect("message_received", self, "_on_message_receieved")

	var err = _client.connect_to_url(WEBSOCKET_URL)
	if err != OK:
		print("Client unable to connect")
		emit_signal("connection_state", false)
		set_process(false)

func _closed(_was_clean = false):
	print("Simulation player websocket closed")
	emit_signal("connection_state", false)
	set_process(false)

func _connected(_proto = ""):
	print("Simulation player %s connected to server" % username)
	emit_signal("connection_state", true)	

func _on_data():
	var data_str = _client.get_peer(1).get_packet().get_string_from_utf8()
	var log_msg = data_str
	Log.info("[%s] Received data from server: %s" % [name, log_msg])
	var parse_result = JSON.parse(data_str)
	if parse_result.error != OK:
		Log.info("Failed to parse message")
		return
	var message = parse_result.result
	if not "type" in message:
		return
	if not "data" in message:
		return
	_handle_message(message)

func _process(_delta):
	_client.poll()

func _handle_message(message):
	if not message.type:
		Log.info("Invalid message received %s: (type not specified)" % message)
		return
	if not "data" in message:
		Log.info("Invalid message received %s (data not specified)" % message)
		return
	if not "protocolVersion" in message:
		Log.info("Invalid message recieved %s (protocolVersion not specified)" % message)
		return
	var message_protocol_version = float(message.protocolVersion)
	if message_protocol_version != NetworkInterface.PROTOCOL_VERSION:
		Log.warn("Protocol version mismatch. Received message with protocol version %f but ours is %f" % \
			[message_protocol_version, NetworkInterface.PROTOCOL_VERSION])
		if message_protocol_version > NetworkInterface.PROTOCOL_VERSION:
			Events.emit_signal("outdated_protocol_version")
	emit_signal("message_received", message)
		
func send_message(message):
	message["protocolVersion"] = NetworkInterface.PROTOCOL_VERSION
	message["clientId"] = client_id
	message.data["apiKey"] = NetworkInterface.API_KEY
	
	var message_str = JSON.print(message)
	Log.info("Simulation player (%s) sending message: %s" % [username, message_str])
	_client.get_peer(1).put_packet(message_str.to_utf8())

func _on_message_receieved(message):
	if message.type == Message.HEARTBEAT_PING:
		_handle_heartbeat()

func _handle_heartbeat():
	send_message(Message.create(Message.HEARTBEAT_PONG, {}))

func join():
	send_message(Message.create(Message.REQUEST_JOIN, {
		"username": username,
		"roomCode": Room.code
	}))
	
