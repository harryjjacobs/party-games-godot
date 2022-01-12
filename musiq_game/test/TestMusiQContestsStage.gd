extends Node2D

const MusiQTrackPlayer = preload("res://musiq_game/track_player/MusiQTrackPlayer.cs")

onready var stage = $MusiQContestsStage
onready var mock_game_server = $MockGameServer

var _track_player = MusiQTrackPlayer.new()
var _track_player_auth_helper
var _input_prompts_sent = 0

func _ready():
	mock_game_server.connect("message_received", self, "_on_mock_server_message_received")
	mock_game_server.configure_network_interface_to_use_mocked_server()
	yield(get_tree().create_timer(1.0), "timeout")
	
	Room.players = [
		Player.new("0", "Player 1"),
		Player.new("1", "Player 2"),
		Player.new("2", "Player 3")
	]

	_track_player_auth_helper = MusiQPlayerAuthHelper.new(_track_player)

	yield(_track_player, "authorization_succeeded")
	yield(_track_player, "ready_to_play")

	var playable_collections = yield(_track_player.SearchPlaylistsAndAlbums("pop"), "completed")

	var playlists = [
		playable_collections.Playlists[0],
		playable_collections.Playlists[1]
	]
	var contest_builder = MusiQContestBuilder.new(playlists, _track_player)
	yield(contest_builder, "initialized")
	var round_generator = MusiQRoundGenerator.new(contest_builder, MusiQRoundGenerator.GameDurationProfile.MEDIUM)
	var params = {
		"track_player": _track_player,
		"round_generator": round_generator,
		"current_round": round_generator.next(MusiQContest.ContestType.ALLVALL, Room.players),
		"round_history": Array(),
	}
	stage.connect("request_exit", self, "_on_stage_exit")
	stage.enter(params)
	yield(get_tree().create_timer(5), "timeout")
	assert(_input_prompts_sent == len(Room.players))

func _on_stage_exit(params):
	for contest in params.current_round.contests:
		assert(contest.responses)
	Log.info("TEST PASSED")

func _on_mock_server_message_received(conn_id, message):
	# mock player responses
	if message.type == Message.HOST_TO_PLAYER:
		if message.data.payload.type == Message.HIDE_PROMPT:
			return
		assert(message.data.payload.type == Message.REQUEST_INPUT)
		assert(message.data.payload.data.promptType == "song_search")
		assert(message.data.payload.data.promptData.apiAccessToken)
		_input_prompts_sent += 1
		yield(get_tree().create_timer(5 * randf() + 1), "timeout")

		var response_data =	{
			"id": message.data.payload.data.promptData.id,
		}

		var rand = randf()
		if rand < 0.25:
			response_data["trackId"] = stage._current_contest.track.Id
		elif rand < 0.6:
			response_data["trackId"] = null
		else:
			response_data["trackId"] = "4cOdK2wGLETKBW3PvgPWqT"

		# delay before sending response
		mock_game_server.send_message(conn_id, Message.create(Message.PLAYER_TO_HOST, {
			"clientId": message.data.playerClientId,
			"payload": {
				"type": Message.PROMPT_RESPONSE,
				"data": response_data
			}
		}))
