extends "res://core/game_stages/RoundBeginStage.gd"

const explosion_audio_stream = preload("res://musiq_game/audio/explosion.mp3")

onready var _title = $Title
onready var _player_icon_display = $PlayerIconDisplay

func enter(params):
	.enter(params)
	_title.text = "Round %d" % (len(params.round_history) + 1)
	$AnimationPlayer.play("h2h_entrance")
	var players = _get_top_players_from_last_round()
	params.current_round = params.round_generator.next(MusiQContest.ContestType.HEAD2HEAD, players)
	if is_inside_tree():
		yield(get_tree().create_timer(2.0), "timeout")
	yield(_display_players_on_contest(players), "completed")
	set_timeout(duration, params)

func _display_players_on_contest(players):
	for player in players:
		_play_audio(explosion_audio_stream)
		_player_icon_display.add_player(player)
		if is_inside_tree():
			yield(get_tree().create_timer(1.0), "timeout")

func _get_top_players_from_last_round():
	var ordered_players = Player.sort_players_descending_by_points(Room.players.duplicate())
	var winners = []
	var highest_points = ordered_players[0].points
	for player in ordered_players:
		# add top 2 players OR if there are more than 2 players with the same highest score, add them
		if len(winners) < 2 or player.points == highest_points:
			winners.push_back(player)
		else:
			break
	return winners
