extends "res://core/game_stages/common/GameStage.gd"

onready var _leaderboard = $PlayerIconDisplay

func enter(params):
	.enter(params)
	yield(get_tree().create_timer(0.5), "timeout")
	yield(_show_initial_positions(), "completed")
	yield(get_tree().create_timer(0.5), "timeout")
	_show_point_changes()
	yield(get_tree().create_timer(2.0), "timeout")
	yield(_rearrange_leaderboard(), "completed")
	# new parameters for next round
	_parameters.round_history.append(_parameters.current_round)
	_parameters.current_round = null
	set_timeout(2.0, _parameters)

func _show_initial_positions():
	# show the points achieved in the previous round first
	var players = Room.players.duplicate()
	var points_group = str(len(_parameters.round_history))
	var previous_points = []
	for player in players:
		var points_this_round = player.get_point_change_by_group(points_group)
		var original_points = player.points - points_this_round
		previous_points.append(_PointSnapshot.new(player, original_points))
	# show player icons in correct order according to the points gained before this round
	previous_points.sort_custom(self, "_sort_descending_by_points")
	for snapshot in previous_points:
		_leaderboard.add_player(snapshot.player, true)
		var icon = _leaderboard.get_player_icon(snapshot.player)
		icon.show_points(true, snapshot.points)
		yield(get_tree().create_timer(0.4), "timeout")

func _show_point_changes():
	# show the points gained in this round
	var points_group = str(len(_parameters.round_history))
	for player in Room.players:
		var points_this_round = player.get_point_change_by_group(points_group)
		var original_points = player.points - points_this_round
		_leaderboard.add_player(player, true)
		var icon = _leaderboard.get_player_icon(player)
		icon.animate_points_change(original_points, player.points)
	# TODO: maybe play point increase sound

func _rearrange_leaderboard():
	yield(get_tree(), "idle_frame")
	var ordered_players = Room.players.duplicate()
	ordered_players.sort_custom(self, "_sort_descending_by_points")
	for player in ordered_players:
		var i = _leaderboard.get_player_icon(player).get_position_in_parent()
		var new_index = i - 1
		while new_index >= 0:
			var player_icons = _leaderboard.get_player_icons()	# get updated icons
			var player_to_beat = player_icons[new_index]._player
			if player_to_beat.points >= player.points:
				break
			yield(get_tree(), "idle_frame")
			yield(_leaderboard.swap_players(player, player_to_beat, true), "completed")
			new_index -= 1

class _PointSnapshot:
	var player
	var points
	func _init(_player, _points):
		player = _player
		points = _points

static func _sort_descending_by_points(a, b):
	return b.points < a.points
