extends "res://core/game_stages/CreditsStage.gd"

onready var _song_playing_spinner = $SongPlayingSpinner
onready var _song_display = $MusiQContestSongDisplay

const TRACK_PREVIEW_TIME = 15

func enter(params):
	.enter(params)
	_song_display.visible = false
	var _err = Events.connect("game_paused", self, "_on_game_paused")
	_err = Events.connect("game_resumed", self, "_on_game_resumed")
	_play_song_previews()

func exit():
	Events.disconnect("game_paused", self, "_on_game_paused")
	Events.disconnect("game_resumed", self, "_on_game_resumed")
	_parameters.track_player.Pause()
	return .exit()

func _play_song_previews():
	while is_inside_tree():
		for r in _parameters.round_history:
			for contest in r.contests:
				if not is_inside_tree():
					return
				yield(_play_track(contest.track), "completed")
				if not is_inside_tree():
					return
				if is_inside_tree():
					yield(get_tree().create_timer(TRACK_PREVIEW_TIME), "timeout")
				if not is_inside_tree():
					return
				yield(_stop_track(), "completed")

func _play_track(track):
	_song_display.visible = true
	_song_display.init(track)
	var success = yield(_parameters.track_player.Play(track.Id), "completed")
	_song_playing_spinner.spin(success)
	if success:
		Log.info("Playing track: " + track.Id)
	else:
		Log.info("Failed to play track: " + track.Id)

func _stop_track():
	Log.info("Stopping track")
	yield(_parameters.track_player.Pause(), "completed")
	_song_playing_spinner.spin(false)
	_song_display.visible = false

func _on_game_paused():
	# TODO: check if track is actually playing using API
	_parameters.track_player.Pause()

func _on_game_resumed():
	_parameters.track_player.Resume()
