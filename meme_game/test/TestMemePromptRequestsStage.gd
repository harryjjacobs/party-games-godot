extends Node

onready var meme_prompts_requests_stage = $MemePromptRequestsStage
onready var mock_server = $MockMemeGameServer

var _response_delay_time = 2
var _test_round
var _default_contest_image: Texture
var _requests_sent = 0
var _exit_requested = false

func _ready():
	_default_contest_image = load("res://meme_game/meme/textures/Change-My-Mind.jpg")
	mock_server.connect("message_received", self, "_server_message_handler")
	yield(get_tree().create_timer(0.1), "timeout")
	NetworkInterface.reconnect = false
	NetworkInterface.server_url = 'ws://localhost:%d' % mock_server.PORT
	NetworkInterface.connect_to_server()
	yield(get_tree().create_timer(1.0), "timeout")
	var player_a = Player.new("0000-0000", "Player a")
	var player_b = Player.new("1111-1111", "Player b")
	Room.players = [player_a, player_b]
	_test_round = Round.new()
	_test_round.contests = [
		_build_contest(player_a, player_b),
		_build_contest(player_b, player_a)
	]
	meme_prompts_requests_stage.connect("request_exit", self, "_on_exit_requested")
	meme_prompts_requests_stage.enter({
		"current_round": _test_round,
		"round_history": Array(),
		"round_generator": null
	})
	var expected_requests = 0
	for contest in _test_round.contests:
		expected_requests += len(contest.players)
		Log.info("delaying for %s s" % _response_delay_time)
		yield(get_tree().create_timer(_response_delay_time), "timeout")
		assert(_requests_sent == expected_requests)
	yield(get_tree().create_timer(5.0), "timeout")
	assert(_exit_requested == true)
	for contest in _test_round.contests:
		assert(len(contest.responses) == len(contest.players))
	Log.info("TEST PASSED")

func _server_message_handler(conn_id, message):
	# mock player responses
	assert(message.data.payload.type == Message.REQUEST_INPUT)
	assert(message.data.payload.data.promptType == "meme")
	assert(message.data.payload.data.promptData.template.image == Marshalls.raw_to_base64(
		_default_contest_image.get_data().save_png_to_buffer()))
	_requests_sent += 1
	# delay before sending responses
	yield(get_tree().create_timer(_response_delay_time), "timeout")
	var captions = Array()
	for _i in message.data.payload.data.promptData.template.captions:
		captions.append("example caption")
	mock_server.send_message(conn_id, Message.create(Message.PLAYER_TO_HOST, {
		"clientId": message.data.playerClientId,
		"payload": {
			"type": Message.PROMPT_RESPONSE,
			"data": {
				"contestId": message.data.payload.data.promptData.id,
				"captions": captions
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
	contest.meme_template.image = _default_contest_image
	contest.responses = Array()
	contest.votes = Array()
	return contest
