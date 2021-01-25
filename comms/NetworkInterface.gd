extends Node

export var server_url = 'ws://localhost:3000/hosts'

var _client = WebSocketClient.new()
var _message_handlers = {}
var _message_queue = []
var _is_connected = false
var _client_id

func _ready():
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_opened")
	_client.connect("data_received", self, "_on_data")
	_client.connect_to_url(server_url);

func _closed(was_clean = false):
	print("Connection to server closed, clean: ", was_clean)
	_is_connected = false

func _opened(_proto = ""):
	print("Connection to server opened")
	_is_connected = true

func _on_data():
	var data_str = _client.get_peer(1).get_packet().get_string_from_utf8()
	print("Got data from server: ", data_str)
	var parse_result = JSON.parse(data_str)
	if parse_result.error != OK:
		print("Failed to parse message")
		return
	var message = parse_result.result
	if not "type" in message:
		return
	if not "data" in message:
		return
	if "clientId" in message:
		_client_id = message.clientId
	_handle_message(message)
	
func _process(_delta):
	_client.poll()
	if _is_connected and not _message_queue.empty():
		var message = _message_queue.pop_front()
		var message_str = JSON.print(message)
		print("Sending message: ", message_str)
		_client.get_peer(1).put_packet(message_str.to_utf8())

func _handle_message(message):
	if not message.type:
		print("Invalid message received %s: (type not specified)" % message)
	if not message.data:
		print("Invalid message received %s (data not specified)" % message)
	if message.type == 'player_to_host':
		var handlers = _message_handlers.get(message.data.payload.type)
		if not handlers:
			print("no handlers registered for message type %s" % message.data.payload.type)
		for handler in handlers:
			handler.funcref.call_func(message.data.clientId, message.data.payload)
	else:
		var handlers = _message_handlers.get(message.type)
		if handlers:
				for handler in handlers:
					handler.funcref.call_func(message)

func send_player(client_id, message):
	var host_to_player_message = Message.create(Message.HOST_TO_PLAYER, {
		"playerClientId": client_id, 
		"payload": message
	})
	_message_queue.push_back(host_to_player_message)

func send_server(message):
	_message_queue.push_back(message)

func on_player(message_type: String, target: Object, method: String):
	var handlers = _message_handlers.get(message_type)
	if not handlers:
		_message_handlers[message_type] = []
		_message_handlers[message_type].push_back(funcref_wrapper(target, method))

func off_player(message_type: String, target: Object, method: String):
	_off(message_type, target, method)

func on_server(message_type: String, target: Object, method: String):
	var handlers = _message_handlers.get(message_type)
	if not handlers:
		_message_handlers[message_type] = []
		_message_handlers[message_type].push_back(funcref_wrapper(target, method))

func off_server(message_type: String, target: Object, method: String):
	_off(message_type, target, method)

func _off(message_type: String, target: Object, method: String):
	var handlers = _message_handlers.get(message_type)
	if not handlers:
		return
	var to_remove = []
	for handler in handlers:
		if handler.method == method and handler.target == target:
			to_remove.push_back(handler)
	for handler in to_remove:
		handlers.erase(handler)

func funcref_wrapper(target: Object, method: String):
	return {
		"funcref": funcref(target, method),
		"target": target,
		"method": method
	}
