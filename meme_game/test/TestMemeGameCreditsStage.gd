extends Node2D

export(Array, Resource) var meme_templates

onready var _stage = $MemeGameCreditsStage
onready var _meme_renderer = $MemeGameCreditsStage/HBoxContainer/MemeRendererContainer/MemeRenderer

func _ready():
	var players = [
		Player.new("0", "Player 1"),
		Player.new("1", "Player 2"),
		Player.new("2", "Player 3"),
		Player.new("3", "Player 4"),
		Player.new("4", "Player 5"),
	]
	Room.players = players
	var params = {
		"round_generator": null,
		"current_round": null,
		"round_history": [_mock_round()],
	}
	_stage.connect("request_exit", self, "_on_stage_exit")
	_stage.enter(params)

func _on_stage_exit(_params):
	pass

func _mock_round():
	var r = Round.new()
	for template in meme_templates:
		var player_a_index = randi() % len(Room.players)
		var player_b_index = (player_a_index + 1) % len(Room.players)
		r.contests.push_back(_build_contest(template, Room.players[player_a_index], Room.players[player_b_index]))
	return r

func _build_contest(template, player_a, player_b):
	var contest = MemeContest.new()
	contest.type = MemeContest.ContestType.BASIC
	contest.players = [player_a, player_b]
	contest.meme_template = template.duplicate()
	assert(contest.meme_template)
	var player_a_response = MemeContestResponse.new()
	player_a_response.player = player_a
	player_a_response.captions = generate_sentences(len(contest.meme_template.captions))
	var player_b_response = MemeContestResponse.new()
	player_b_response.player = player_b
	player_b_response.captions = generate_sentences(len(contest.meme_template.captions))
	contest.responses = [
		player_a_response,
		player_b_response
	]
	for player in Room.players:
		if player == player_a or player == player_b:
			continue
		var vote = MemeContestVote.new(contest.responses[randi() % len(contest.responses)], player)
		contest.votes.push_back(vote)
	return contest

func generate_sentences(count):
	var chars = "abcdefghijklmnopqrstuvwxyz"
	var sentences = []
	for _s in range(count):
		var sentence = ""
		for _w in range(2, randi() % 13):
			var word = ""
			var n_char = len(chars)
			for _c in range(3, randi() % 15):
				word += chars[randi() % n_char]
			sentence += word + " "
		sentences.push_back(sentence)
	return sentences
