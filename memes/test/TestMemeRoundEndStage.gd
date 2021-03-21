extends Node2D

onready var _stage = $MemeRoundEndStage
onready var _icons_container = $MemeRoundEndStage/PlayerIconDisplay/PlayerIconContainer

func _ready():
	var players = [
		Player.new("0", "Player 1"),
		Player.new("1", "Player 2"),
		Player.new("2", "Player 3"),
		Player.new("3", "Player 4"),
		Player.new("4", "Player 5"),
	]
	# points awarded in first round
	players[0].update_points(50, 0)
	players[1].update_points(72, 0)
	players[2].update_points(50, 0)
	players[3].update_points(50, 0)
	players[4].update_points(60, 0)
	# points awarded in second round
	players[0].update_points(20, 1)
	players[2].update_points(50, 1)
	players[3].update_points(40, 1)
	players[4].update_points(90, 1)
	Room.players = players
	var params = {
		"round_generator": null,
		"current_round": null,
		"round_history": [Round.new()],
	}
	_stage.connect("request_exit", self, "_on_stage_exit")
	_stage.enter(params)

func _on_stage_exit(_params):
	assert(len(_params.round_history) == 2)
	assert(len(_icons_container.get_children()) == len(Room.players))
	var sorted_players = Room.players.duplicate()
	sorted_players.sort_custom(self, "_sort_descending_by_points")
	var i = 0
	for player_icon in _icons_container.get_children():
		assert(player_icon._player == sorted_players[i])
		i += 1
	print("TEST PASSED")

func _sort_descending_by_points(a, b):
	return b.points < a.points
