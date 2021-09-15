extends Node

# development key - change in production before building
const API_KEY = "development-key";

const WS_PROTOCOL = 'ws'
const WSS_PROTOCOL = 'wss'
const HTTP_PROTOCOL = 'http'
const DEVELOPMENT_SERVER_URL = 'localhost:8080'
const PRODUCTION_SERVER_URL = 'party-games-310323.ew.r.appspot.com'

const HOSTS_ENDPOINT_NAME = "hosts"

const PLAYERS_CLIENT_APP_URL = "play.jacobs.software"

enum ConnectionState { CONNECTING, CONNECTED, DISCONNECTED }

const _GAMEPLAY_INDEPENDENT_MESSAGE_TYPES = [
	Message.HEARTBEAT_PING, 
	Message.HEARTBEAT_PONG,
	Message.REQUEST_REJOIN,
	Message.ACCEPT_REJOIN,
	Message.REJECT_REJOIN
]

export var reconnect = true
# use production server even in debug build
export var force_production_server = false

onready var _reconnection_timer = $ReconnectionTimer
var hosts_endpoint_url
var connection_state
var _client = WebSocketClient.new()
var _message_handlers = {}
var _outgoing_message_queue = []
var _incoming_message_queue = []
var _client_id

func _ready():
	hosts_endpoint_url = _get_server_endpoint_url(HOSTS_ENDPOINT_NAME)
	_client.connect("connection_closed", self, "_closed")
	_client.connect("connection_error", self, "_closed")
	_client.connect("connection_established", self, "_opened")
	_client.connect("data_received", self, "_on_data")
	_reconnection_timer.connect("timeout", self, "_connect")

func _connect():
	_update_state(ConnectionState.CONNECTING)
	Log.info("Attempting to connect to %s" % hosts_endpoint_url)
	_client.connect_to_url(hosts_endpoint_url)
	_reconnection_timer.stop()

func _disconnect():
	_client.disconnect_from_host()

func _closed(was_clean = false):
	Log.info("Connection to server closed, clean: %s" % was_clean)
	_update_state(ConnectionState.DISCONNECTED)
	if reconnect:
		_reconnection_timer.start()

func _opened(_proto = ""):
	Log.info("Connection to server opened")
	_update_state(ConnectionState.CONNECTED)
	_reconnection_timer.stop()

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
	if "clientId" in message:
		_client_id = message.clientId
	_incoming_message_queue.push_back(message)
	
func _process(_delta):
	_client.poll()
	if not _incoming_message_queue.empty():
		if not get_tree().paused or _incoming_message_queue.front().type in _GAMEPLAY_INDEPENDENT_MESSAGE_TYPES:
			_handle_message(_incoming_message_queue.pop_front())
	if connection_state == ConnectionState.CONNECTED and not _outgoing_message_queue.empty():
		if not get_tree().paused or _outgoing_message_queue.front().type in _GAMEPLAY_INDEPENDENT_MESSAGE_TYPES:
			var message = _outgoing_message_queue.pop_front()
			message.data["apiKey"] = API_KEY
			var message_str = JSON.print(message)
			Log.info("Sending message: %s" % message_str)
			_client.get_peer(1).put_packet(message_str.to_utf8())

func _handle_message(message):
	if not message.type:
		Log.info("Invalid message received %s: (type not specified)" % message)
	if not "data" in message:
		Log.info("Invalid message received %s (data not specified)" % message)
	if message.type == Message.PLAYER_TO_HOST:
		var handlers = _message_handlers.get(message.data.payload.type)
		if not handlers:
			Log.info("No handlers registered for message type %s" % message.data.payload.type)
			return
		for handler in handlers:
			handler.funcref.call_func(message.data.clientId, message.data.payload)
	elif message.type == Message.HEARTBEAT_PING:
		send_server(Message.create(Message.HEARTBEAT_PONG, {}))
	else:
		var handlers = _message_handlers.get(message.type)
		if handlers:
				for handler in handlers:
					handler.funcref.call_func(message)

func connect_to_server():
	_connect()

func disconnect_from_server():
	_disconnect()

func get_player_client_url():
	return PLAYERS_CLIENT_APP_URL

func send_player(target, message):
	var client_id
	if target is Player:
		client_id = target.client_id
	else:
		client_id = target
	var host_to_player_message = Message.create(Message.HOST_TO_PLAYER, {
		"playerClientId": client_id, 
		"payload": message
	})
	_outgoing_message_queue.push_back(host_to_player_message)

func send_players(targets, message):
	for target in targets:
		send_player(target, message)

func send_server(message):
	_outgoing_message_queue.push_back(message)

func on_player(message_type: String, target: Object, method: String):
	var handlers = _message_handlers.get(message_type)
	if not handlers:
		_message_handlers[message_type] = []
		_message_handlers[message_type].push_back(_funcref_wrapper(target, method))

func off_player(message_type: String, target: Object, method: String):
	_off(message_type, target, method)

func on_server(message_type: String, target: Object, method: String):
	var handlers = _message_handlers.get(message_type)
	if not handlers:
		_message_handlers[message_type] = []
		_message_handlers[message_type].push_back(_funcref_wrapper(target, method))

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

func _update_state(new_state):
	connection_state = new_state
	Events.emit_signal("server_connection_state_changed", connection_state)

func _funcref_wrapper(target: Object, method: String):
	return {
		"funcref": funcref(target, method),
		"target": target,
		"method": method
	}

func _get_server_endpoint_url(name):
	if OS.is_debug_build() and not force_production_server:
		return PoolStringArray(['ws://' + DEVELOPMENT_SERVER_URL, name]).join("/")
	else:
		return PoolStringArray(['wss://' + PRODUCTION_SERVER_URL, name]).join("/")
