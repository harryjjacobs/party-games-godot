extends Node

onready var meme_contest_stage = $MemeContestStage
onready var mock_server = $MockMemeGameServer

var _test_round
var _default_contest_image
var _vote_prompts_sent = 0
var _exit_requested = false

func _ready():
	_default_contest_image = load("res://memes/meme/textures/Change-My-Mind.jpg")
	mock_server.connect("message_received", self, "_server_message_handler")
	yield(get_tree().create_timer(0.1), "timeout")
	NetworkInterface.reconnect = false
	NetworkInterface.server_url = 'ws://localhost:%d' % mock_server.PORT
	NetworkInterface.connect_to_server()
	yield(get_tree().create_timer(1.0), "timeout")
	var player_a = Player.new("0000-0000", "Player a")
	var player_b = Player.new("1111-1111", "Player b")
	var player_c = Player.new("2222-2222", "Player c")
	Room.players = [player_a, player_b, player_c]
	_test_round = Round.new()
	_test_round.contests = [
		_build_contest(player_a, player_b),
		_build_contest(player_b, player_a)
	]
	for contest in _test_round.contests:
		contest.responses = [
			_build_response(player_a),
			_build_response(player_b)
		]
	meme_contest_stage.connect("request_exit", self, "_on_exit_requested")
	meme_contest_stage.enter({
		"current_round": _test_round,
		"round_history": Array(),
		"round_generator": null
	})
	for i in len(_test_round.contests):
		yield(get_tree().create_timer(5.0), "timeout")
		assert(_vote_prompts_sent == (i + 1) * (len(Room.players) - 2))
		yield(get_tree().create_timer(meme_contest_stage.vote_timeout), "timeout")
	# for contest in _test_round.contests:
	# 	assert(len(contest.responses) == len(contest.players))
	print("TEST PASSED")

func _server_message_handler(conn_id, message):
	# mock player responses
	assert(message.type == Message.HOST_TO_PLAYER)
	assert(message.data.payload.type == Message.REQUEST_INPUT)
	assert(message.data.payload.data.promptType == "multichoice")
	assert(message.data.payload.data.promptData.options)
	_vote_prompts_sent += 1
	# delay before sending responses
	yield(get_tree().create_timer(2.0), "timeout")
	mock_server.send_message(conn_id, Message.create(Message.PLAYER_TO_HOST, {
		"clientId": message.data.playerClientId,
		"payload": {
			"type": Message.PROMPT_RESPONSE,
			"data": {
				"contestId": message.data.payload.data.promptData.contestId,
				"choice": len(message.data.payload.data.promptData.options) - 1
			}
		}
	}))

func _on_exit_requested(params):
	assert(params.current_round == _test_round)
	_exit_requested = true

func _build_contest(player_a, player_b):
	var contest = MemeContest.new()
	contest.type = MemeContest.ContestType.BASIC
	contest.players = [player_a, player_b]
	contest.meme_template = MemeTemplate.new()
	assert(_default_contest_image)
	contest.meme_template.image = _default_contest_image
	var caption = MemeCaption.new()
	caption.width = 100
	caption.height = 100
	contest.meme_template.captions = [caption]
	contest.responses = Array()
	contest.votes = Array()
	return contest

func _build_response(player):
	var response = MemeContestResponse.new()
	response.player = player
	response.captions = ["An example caption for testing. abcdefghijklmnopqrstuvwxyz0123456789"]
	return response
