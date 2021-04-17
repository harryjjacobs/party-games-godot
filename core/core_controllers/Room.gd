extends Node

const Message = preload("res://core/comms/Message.gd")
const Player = preload("res://core/player/Player.gd")

const MAX_USERNAME_LENGTH = 15

var players = []
var code
var _pending_creation = true
var _open = false
var _max_players = 1

func _ready():
	NetworkInterface.on_server(Message.ACCEPT_CREATE_ROOM, self, "_on_accept_create_room")
	NetworkInterface.on_player(Message.REQUEST_JOIN, self, "_on_player_request_join")
	NetworkInterface.on_player(Message.REQUEST_REJOIN, self, "_on_player_request_rejoin")

func init(max_players):
	_max_players = max_players
	players.clear()
	_pending_creation = true
	NetworkInterface.send_server(Message.create(Message.REQUEST_CREATE_ROOM, {"gameType": "memes"}))

func lock():
	_open = false

func unlock():
	_open = true

func find_player_by_id(client_id):
	for player in players:
		if player.client_id == client_id:
			return player
	return null

func _add_player(player):
	players.push_back(player)
	Events.emit_signal("player_joined_room", player)

func _remove_player(player):
	players.erase(player)
	Events.emit_signal("player_left_room", player)

func _on_accept_create_room(message):
	if not _pending_creation:
		Log.info("_on_accept_create_room(): Room already initialised. Use init() to reset")
	if not message.data.roomCode:
		Log.info("_on_accept_create_room(): Invalid room code in message: " + message)
		return
	code = message.data.roomCode
	_pending_creation = false
	Events.emit_signal("room_created", code)
	
func _on_player_request_join(client_id, message):
	if not _open:
		_reject_join(client_id, "Room closed (game may have already started)")
		return
	if not "username" in message.data:
		_reject_join(client_id, "Invalid username")
		return
	if not message.data.username:
		_reject_join(client_id, "Invalid username")
		return
	var username = message.data.username.strip_edges().strip_escapes().to_upper()
	if not username:
		_reject_join(client_id, "Invalid username")
		return
	if len(username) > MAX_USERNAME_LENGTH:
		_reject_join(client_id, "Username too long")
		return
	if _is_existing_username(username):
		_reject_join(client_id, "Username taken")
		return
	var player = Player.new(client_id, username)
	players.push_back(player)
	NetworkInterface.send_server(Message.create(Message.ADD_PLAYER, {
		"roomCode": code,
		"clientId": player.client_id,
		"username": player.username
	}))
	_accept_join(player)
	Events.emit_signal("player_joined_room", player)

func _on_player_request_rejoin(client_id, message):
	if not message.data.oldClientId:
		Log.info("_on_player_request_rejoin() oldClientId not specified")
	var accepted = false
	for player in players:
		if player.client_id == message.data.oldClientId:
			player.client_id = client_id
			NetworkInterface.send_server(Message.create(Message.UPDATE_PLAYER_INFO, {
				"clientId": message.data.oldClientId,
				"newClientId": player.client_id,
				"newName": player.username
			}))
			_accept_rejoin(player)
			accepted = true
			break
		if not accepted:
			NetworkInterface.send_player(client_id, Message.create(Message.REJECT_REJOIN, {}))

func _reject_join(client_id, reason):
	NetworkInterface.send_player(
		client_id,
		Message.create(Message.REJECT_JOIN, {"reason": reason})
	)

func _accept_join(player: Player):
	NetworkInterface.send_player(player.client_id, Message.create(Message.ACCEPT_JOIN, {
		"clientId": player.client_id,
		"roomCode": code
	}))

func _accept_rejoin(player: Player):
	NetworkInterface.send_player(player.client_id, Message.create(Message.ACCEPT_REJOIN, {
		"clientId": player.client_id,
		"roomCode": code
	}))
	
func _is_existing_username(username: String):
	for player in players:
		if player.username == username:
			return true
	return false
