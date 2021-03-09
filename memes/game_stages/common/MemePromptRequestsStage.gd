extends "res://core/game_stages/common/GameStage.gd"

export(float) var time_per_contest = 30

onready var _player_icon_display = $PlayerIconDisplay

var _current_round
var _pending_responses = 0

func enter(params):
	.enter(params)
	_current_round = params.current_round
	assert(_current_round.contests)
	var stage_duration = time_per_contest * len(_current_round.contests)
	assert(stage_duration > 0)
	set_timeout(stage_duration, params)
	NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_player_prompt_response")
	for contest in _current_round.contests:
		for player in contest.players:
			_send_prompt_to_player(player, contest)

func exit():
	.exit()
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_player_prompt_response")
	_player_icon_display.clear()

func _send_prompt_to_player(player, contest):
	NetworkInterface.send_player(player.client_id, Message.create(Message.REQUEST_INPUT, {
		"promptType": "meme",	# input type
		"promptData": {	# data that corresponds to input type
			"id": contest.id,
			"template": contest.meme_template.to_json()
		}
	}))
	_pending_responses += 1

func _on_player_prompt_response(client_id, message):
	var player = Room.find_player_by_id(client_id)
	if not player:
		return
	print("Prompt response received from %s (%s)" % [client_id, player.username])
	_player_icon_display.add_player(player)
	for contest in _current_round.contests:
		if contest.id == message.data.contestId:
			if not player in contest.players:
				return
			var contest_response = MemeContestResponse.new()
			contest_response.player = player
			contest_response.captions = message.data.captions
			contest.responses.append(contest_response)
			break
	_pending_responses -= 1
	if _pending_responses <= 0:
		_pending_responses = 0
		emit_signal("request_exit", _parameters)
