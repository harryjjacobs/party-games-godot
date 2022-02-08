extends "res://core/game_stages/common/GameStage.gd"

const MAX_CAPTION_LENGTH = 75

export(float) var time_per_contest = 30

onready var _player_icon_display = $PlayerIconDisplay
onready var _countdown_display = $CountdownDisplay

var _current_round
var _pending_requests = {}
var _pending_responses = 0

func enter(params):
	.enter(params)
	_current_round = params.current_round
	assert(_current_round.contests)
	var stage_duration = time_per_contest * len(_current_round.contests)
	assert(stage_duration > 0)
	set_timeout(stage_duration, params)
	_countdown_display.start(stage_duration)
	NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_player_prompt_response")
	_begin_contest_sending()

func exit():
	_countdown_display.stop()
	NetworkInterface.send_players(Room.players, Message.create(Message.HIDE_PROMPT, {}))
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_player_prompt_response")
	_player_icon_display.clear()
	return .exit()

func _begin_contest_sending():
	_pending_responses = 0
	for contest in _current_round.contests:
		for player in contest.players:
			if not player in _pending_requests:
				_pending_requests[player] = []
			_pending_requests[player].append(contest)
			_pending_responses += 1
	for player in _pending_requests:
		if not _pending_requests[player].empty():
			_send_prompt_to_player(player, _pending_requests[player].pop_front())

func _send_prompt_to_player(player, contest):
	NetworkInterface.send_player(player.client_id, Message.create(Message.REQUEST_INPUT, {
		"promptType": "meme",	# input type
		"promptData": {	# data that corresponds to input type
			"id": contest.id,
			"maxInputLength": MAX_CAPTION_LENGTH,
			"template": contest.meme_template.to_json()
		}
	}))

func _send_response_rejection_to_player(player, error_message):
		NetworkInterface.send_player(player.client_id, Message.create(Message.REJECT_INPUT, {
		"reason": error_message,
	}))

func _on_player_prompt_response(client_id, message):
	var player = Room.find_player_by_id(client_id)
	if not player:
		return
	Log.info("Prompt response received from %s (%s)" % [client_id, player.username])
	var found = false
	for contest in _current_round.contests:
		if contest.id == message.data.id:
			if not player in contest.players:
				Log.warn("Invalid contest response - player not in this contest")
				return
			var contest_response = MemeContestResponse.new()
			contest_response.player = player
			if not message.data.captions:
				Log.info("Invalid contest response - no captions")
				_send_response_rejection_to_player(player, "Invalid response received")
				return
			contest_response.captions = _sanitise_captions(message.data.captions)
			if _same_response_exists(contest, contest_response):
				Log.info("Invalid contest response - non-unique response")
				_send_response_rejection_to_player(player, 
					"Great minds think alike - an identical response has already been submitted! Try something else.")
				return
			contest.responses.append(contest_response)
			found = true
			break
	if found:
		# response accepted, hide input prompt
		NetworkInterface.send_player(player, Message.create(Message.HIDE_PROMPT, {}))
		_pending_responses -= 1
		if _pending_responses <= 0:
			_pending_responses = 0
			_countdown_display.stop()
			set_timeout(2.0, _parameters)
	else:
		Log.info("Invalid contest response - no matching contest with id %s found" % message.data.id)
	# send next contest for this player
	if player in _pending_requests and not _pending_requests[player].empty():
		_send_prompt_to_player(player, _pending_requests[player].pop_front())
	else:
		_player_icon_display.add_player(player)

func _sanitise_captions(captions):
	var sanitised_captions = []
	for caption in captions:
		sanitised_captions.push_back(caption.to_upper())
	return sanitised_captions

func _same_response_exists(contest, response):
	for existing_response in contest.responses:
		if existing_response.captions == response.captions:
			return true
	return false
