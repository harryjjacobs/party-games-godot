extends "res://core/game_stages/common/GameStage.gd"

onready var _song_playing_spinner = $SongPlayingSpinner
onready var _song_display = $MusiQContestSongDisplay

func enter(params):
	.enter(params)
	_song_display.visible = false
	_play_song_previews()

func exit():
	.exit()
	_parameters.track_player.Stop()

func _play_song_previews():
	while is_inside_tree():
		for r in _parameters.round_history:
			for contest in r.contests:
				yield(_play_track(contest.track), "completed")
				yield(get_tree().create_timer(10), "timeout")
				yield(_stop_track(), "completed")

func _play_track(track):
	_song_display.visible = true
	_song_display.init(track)
	var success = yield(_parameters.track_player.Play(track.Id), "completed")
	_song_playing_spinner.spin(success)
	if success:
		print("Playing track: " + track.Id)
	else:
		print("Failed to play track: " + track.Id)

func _stop_track():
	print("Stopping track")
	yield(_parameters.track_player.Stop(), "completed")
	_song_playing_spinner.spin(false)
	_song_display.visible = false

func _on_play_again_button_pressed():
	Events.emit_signal("request_restart", false)

func _on_play_again_same_players_button_pressed():
	Events.emit_signal("request_restart", true)

func _on_exit_to_main_menu_button_pressed():
	Events.emit_signal("request_main_menu")