extends "res://core/game_stages/common/GameStage.gd"
class_name LobbyStage

const Message = preload("res://core/comms/Message.gd")

const QR_CODE_SIZE = 512
const PROMPT_RESEND_INTERVAL = 1

export(int) var max_players = 10
export(int) var min_players = 2
export(Resource) var player_color_palette
onready var player_icon_display = $PlayerIconDisplay
onready var join_info_label = $JoinInformationLabel
onready var qr_code_texture_rect = $QrCodeTextureRect
onready var qr_code_service = $QrCodeService

var _begin_game_prompt_ids = []
var _sent_begin_game_prompt
var _last_sent_begin_game_prompt_time
var _player_color_generator

func enter(params):
	.enter(params)
	_begin_game_prompt_ids = []
	_sent_begin_game_prompt = false
	_last_sent_begin_game_prompt_time = 0
	_player_color_generator = ColorGenerator.new(player_color_palette)
	if NetworkInterface.connection_state != NetworkInterface.ConnectionState.DISCONNECTED:
		NetworkInterface.disconnect_from_server()
	NetworkInterface.connect_to_server()
	var _err = Events.connect("room_created", self, "_on_room_created")
	_err = Events.connect("server_connection_state_changed", self, "on_server_connection_state_changed")
	_err = NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_prompt_response")
	Room.init(max_players)	# requests the server to create a room
	Room.unlock()
	BackgroundMusic.play()

func exit():
	Room.lock()
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_prompt_response")
	if Events.is_connected("room_created", self, "_on_room_created"):	
		Events.disconnect("room_created", self, "_on_room_created")
	if Events.is_connected("server_connection_state_changed", self, "on_server_connection_state_changed"):
		Events.disconnect("server_connection_state_changed", self, "on_server_connection_state_changed")	
	if Events.is_connected("player_joined_room", self, "_on_player_joined_room"):
		Events.disconnect("player_joined_room", self, "_on_player_joined_room")
	BackgroundMusic.skip_track()
	return .exit()

func _process(_delta):
	if _sent_begin_game_prompt and (OS.get_unix_time() - _last_sent_begin_game_prompt_time) > PROMPT_RESEND_INTERVAL:
		# resend prompt in case the player accidentally refreshed and the prompt didn't reload for them
		_send_begin_game_prompt_to_first_player()

func on_server_connection_state_changed(state):
	if state == NetworkInterface.ConnectionState.DISCONNECTED:
		Events.emit_signal("request_main_menu", "Disconnected from server")

func _generate_qr_code(url):
	if qr_code_service.request_qr_code(url, QR_CODE_SIZE):
		var texture = yield(qr_code_service, "request_completed")
		if texture:
			qr_code_texture_rect.texture = texture

func _on_room_created(code):
	var url = NetworkInterface.get_player_client_url()
	join_info_label.text = "Go to %s\nEnter code %s to join" % [url, code]
	var _err = Events.connect("player_joined_room", self, "_on_player_joined_room")
	url += "?room=" + code
	_generate_qr_code(url)

func _on_player_joined_room(player):
	Log.info("Player %s joined the lobby" % player.username)
	# assign additional information to the player
	player.color = _player_color_generator.next()
	# display the player
	player_icon_display.add_player(player)
	
	if not _sent_begin_game_prompt and len(Room.players) >= min_players:
		_send_begin_game_prompt_to_first_player()
		_sent_begin_game_prompt = true

func _send_begin_game_prompt_to_first_player():
	var id = UUID.v4()
	_begin_game_prompt_ids.push_back(id)
	var message = Message.create(Message.REQUEST_INPUT, {
		"promptType": "button",
		"promptData": {
			"prompt": "BEGIN GAME",
			"id": id
		}
	})
	NetworkInterface.send_player(Room.players[0].client_id, message)
	_last_sent_begin_game_prompt_time = OS.get_unix_time()
	
func _on_prompt_response(_client_id, message):
	if not "id" in message.data:
		Log.error("Invalid prompt response received from %s (missing prompt id)" % _client_id)
		return
	if message.data.id in _begin_game_prompt_ids:
		NetworkInterface.send_player(_client_id, Message.create(Message.HIDE_PROMPT, {}))
		emit_signal("request_exit", _parameters)
