extends "res://core/game_stages/common/GameStage.gd"

const Message = preload("res://core/comms/Message.gd")

export(int) var max_players = 10
export(int) var min_players = 2
export(Resource) var player_color_palette
onready var player_icon_display = $PlayerIconDisplay
onready var join_info_label: Label = $JoinInformationLabel

var _begin_game_prompt_id
var _sent_begin_game_prompt
var _player_color_generator

func enter(params):
	.enter(params)
	_begin_game_prompt_id = ""
	_sent_begin_game_prompt = false
	_player_color_generator = ColorGenerator.new(player_color_palette)
	NetworkInterface.connect_to_server()
	var _err = Events.connect("room_created", self, "_on_room_created")
	Room.init(max_players)
	Room.unlock()
	BackgroundMusic.play()

func exit():
	.exit()
	Room.lock()
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_prompt_response")
	Events.disconnect("player_joined_room", self, "_on_player_joined_room")
	BackgroundMusic.skip_track()

func _on_room_created(code):
	join_info_label.text = "Go to %s\nEnter code %s to join" % ["localhost:3000", code]
	var _err = Events.connect("player_joined_room", self, "_on_player_joined_room")

func _on_player_joined_room(player):
	Log.info("Player %s joined the lobby" % player.username)
	# assign additional information to the player
	player.color = _player_color_generator.next()
	# display the player
	player_icon_display.add_player(player)
	if not _sent_begin_game_prompt and len(Room.players) >= min_players:
		_begin_game_prompt_id = preload("res://core/util/uuid/uuid.gd").v4()
		var message = Message.create(Message.REQUEST_INPUT, {
			"promptType": "button",
			"promptData": {
				"prompt": "BEGIN GAME",
				"id": _begin_game_prompt_id
			}
		})
		NetworkInterface.send_player(Room.players[0].client_id, message)
		NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_prompt_response")
		_sent_begin_game_prompt = true

func _on_prompt_response(_client_id, message):
	if message.data.id == _begin_game_prompt_id:
		emit_signal("request_exit", {})
