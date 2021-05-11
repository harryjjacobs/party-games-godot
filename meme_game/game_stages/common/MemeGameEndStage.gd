extends "res://core/game_stages/common/GameStage.gd"

const _celebration_delay = 0.3

export var _celebratory_sound_effect: AudioStreamSample

onready var _title = $Title
onready var _icon_display = $PlayerIconDisplay

func enter(params):
	.enter(params)
	var winners = _get_winners()
	_show_winners(winners)
	set_timeout(10.0, _parameters)

func _get_winners():
	var ordered_players = Room.players.duplicate()
	ordered_players.sort_custom(self, "_sort_descending_by_points")
	var winners = []
	var highest_points = ordered_players[0].points
	for player in ordered_players:
		if player.points == highest_points:
			winners.append(player)
		else:
			break
	return winners

func _show_winners(winners):
	if len(winners) > 1:
		_title.text = "And the winners are..."
	else:
		_title.text = "And the winner is..."
	_icon_display.add_players(winners)
	yield(get_tree().create_timer(_celebration_delay), "timeout")
	_play_audio(_celebratory_sound_effect)

static func _sort_descending_by_points(a, b):
	return b.points < a.points
