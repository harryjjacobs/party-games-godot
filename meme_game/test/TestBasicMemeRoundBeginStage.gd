extends Node2D

onready var stage = $BasicMemeRoundBeginStage

func _ready():
	var players = [
		Player.new("0", "Player 1"),
		Player.new("1", "Player 2"),
		Player.new("2", "Player 3"),
		Player.new("4", "Player 4"),
		Player.new("5", "Player 5"),
		Player.new("6", "Player 6"),
	]
	var params = {
		"round_generator": MemeRoundGenerator.new(players, $MemeContestBuilder),
		"current_round": null,
		"round_history": Array(),
	}
	stage.connect("request_exit", self, "_on_stage_exit")
	stage.enter(params)

func _on_stage_exit(params):
	assert(len(params.current_round.contests) > 0)
	var player_frequencies = {}
	for contest in params.current_round.contests:
		var players = ""
		for player in contest.players:
			if player in player_frequencies:
				player_frequencies[player] += 1
			else:
				player_frequencies[player] = 1
			players += "%s, " % player.username
		print(players)
	var freq_vals = player_frequencies.values()
	for i in range(1, len(freq_vals)):
		if freq_vals[i] != freq_vals[i - 1]:
			Log.error("TEST FAILED. PLAYER CONTEST COUNT NOT EQUAL")
	Log.info("TEST PASSED")