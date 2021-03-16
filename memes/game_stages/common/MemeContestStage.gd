extends "res://core/game_stages/common/GameStage.gd"

export(float) var vote_timeout = 15
export(float) var time_between_contests = 4.0
export(float) var display_contest_result_duration = 5.0
export(AudioStreamSample) var vote_prompt_audio
export(Array, NodePath) var contest_response_display_paths

onready var _countdown_display = $CountdownDisplay
onready var _voting_timer = $VotingTimer
var _contest_response_displays: Array
var _waiting_for_votes = false

var current_contest: MemeContest

enum _VoteValidity {
	OK,
	INVALID_PLAYER,
	INVALID_CHOICE,
	ALREADY_VOTED
}

func enter(params):
	.enter(params)
	_initialise_response_displays()
	for contest in params.current_round.contests:
		print("[%s] Contest begin" % name)
		current_contest = contest
		_show_contest_response_displays(contest)
		# record votes
		yield(_voting_process(), "completed")
		yield(get_tree().create_timer(1.0), "timeout")
		yield(_show_voting_results(), "completed")
		yield(get_tree().create_timer(1.0), "timeout")
		_update_points()
		yield(get_tree().create_timer(display_contest_result_duration), "timeout")
		_hide_all_contest_response_displays()
		yield(get_tree().create_timer(time_between_contests), "timeout")
		
func exit():
	.exit()

func _initialise_response_displays():
	assert(contest_response_display_paths)
	_contest_response_displays.clear()
	for display_path in contest_response_display_paths:
		_contest_response_displays.append(get_node(display_path))
	_hide_all_contest_response_displays()
	
func _show_contest_response_displays(contest):
	for i in len(contest.responses):
		var response = contest.responses[i]
		var display = _contest_response_displays[i]
		display.open(response.player, contest.meme_template, response.captions)

func _hide_all_contest_response_displays():
	for display in _contest_response_displays:
		display.close()
		# TODO: add a delay between each one?
		# also add an exit tween

func _show_voting_results():
	for i in len(current_contest.responses):
		var display = _contest_response_displays[i]
		var response = current_contest.responses[i]
		display.show_player_icon(true)
		var voters = Array()
		for vote in current_contest.votes:
			if vote.choice == response:
				voters.append(vote.voter)
		display.show_votes(voters)
	yield(get_tree().create_timer(1.0), "timeout")
	var winners = _get_winning_responses()
	for i in len(current_contest.responses):
		var display = _contest_response_displays[i]
		var response = current_contest.responses[i]
		if response in winners:
			display.emphasise(true)

func _update_points():
	var votes_per_player = {}
	for vote in current_contest.votes:
		if not vote.choice.player in votes_per_player:
			votes_per_player[vote.choice.player] = 0
		votes_per_player[vote.choice.player] += 1
	for player in votes_per_player:
		player.update_points(votes_per_player[player])
	for i in len(current_contest.responses):
		var display = _contest_response_displays[i]
		var response = current_contest.responses[i]
		if response.player in votes_per_player:
			display.show_point_change(votes_per_player[response.player])

func _get_winning_responses():
	var responses = []
	var vote_table = {}
	var highest = 0
	for vote in current_contest.votes:
		if not vote.choice in vote_table:
			vote_table[vote.choice] = 0
		vote_table[vote.choice] += 1
		if vote_table[vote.choice] > highest:
			responses = [vote.choice]
			highest = vote_table[vote.choice]
		elif vote_table[vote.choice] == highest:
			responses.append(vote.choice)
	return responses

func _voting_process():
	print("[%s] Voting begin" % name)
	._play_audio(vote_prompt_audio)
	NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_vote_received")
	_countdown_display.start(vote_timeout)
	_send_vote_prompts()
	_waiting_for_votes = true
	_voting_timer.wait_time = vote_timeout
	_voting_timer.start()
	while _waiting_for_votes:
		yield(get_tree(), "idle_frame")
	_voting_timer.stop()
	_countdown_display.stop()
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_vote_received")
	print("[%s] Voting end" % name)

func _on_voting_timeout():
	_waiting_for_votes = false

func _send_vote_prompts():
	for player in Room.players:
		if player in current_contest.players:
			continue
		var options = []
		for response in current_contest.responses:
			var caption_list = ""
			for caption in response.captions:
				caption_list += caption + "\n"
			options.append(caption_list)
		var message = Message.create(Message.REQUEST_INPUT, {
			"promptType": "multichoice",
			"promptData": {
				"contestId": current_contest.id,
				"prompt": "Vote for your favourite",
				"options": options
			}
		})
		NetworkInterface.send_player(player.client_id, message)

func _on_vote_received(client_id, message):
	if current_contest.id == message.data.contestId:
		var result = _check_vote_validity(client_id, message)
		if result != _VoteValidity.OK:
			print("Invalid vote received from %s. Reason: %s" % [client_id, _VoteValidity.keys()[result]])
			return
		var player = Room.find_player_by_id(client_id)
		var choice = current_contest.responses[message.data.choice]
		var vote = MemeContestVote.new(choice, player)
		current_contest.votes.append(vote)
		if len(current_contest.votes) == len(Room.players) - len(current_contest.players):
			_waiting_for_votes = false

func _check_vote_validity(client_id, message) -> int:
	var player = Room.find_player_by_id(client_id)
	if not player:
		return _VoteValidity.INVALID_PLAYER
	# a player cannot vote in a two-player contest involving themselves
	if current_contest.type == MemeContest.ContestType.TWO_PLAYER:
		for p in current_contest.players:
			if p.client_id == client_id:
				return _VoteValidity.INVALID_PLAYER
	# check message structure validity
	var choice = message.data.choice
	if not (choice is int or choice is float):
		return _VoteValidity.INVALID_CHOICE
	choice = int(choice)
	# choice index must be in range of responses
	if choice < 0 or choice >= len(current_contest.responses):
		return _VoteValidity.INVALID_CHOICE
	# a player cannot vote twice
	for vote in current_contest.votes:
		if vote.voter == player:
			return _VoteValidity.ALREADY_VOTED
	return _VoteValidity.OK
