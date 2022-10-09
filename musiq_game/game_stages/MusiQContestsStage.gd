extends "res://core/game_stages/common/GameStage.gd"

const FUZZY_SONG_MATCHING = true	# whether to just compare name and artists or spotify track IDs

const _contest_song_guess_scene = preload("res://musiq_game/contest/MusiQContestSongGuess.tscn")

signal _finish_contest(winning_response)

export(float) var default_contest_timeout = 65.0

onready var _contest_timeout_timer = $ContestTimeoutTimer
onready var _player_icon_display = $PlayerIconDisplay
onready var _song_playing_spinning_indicator = $SongPlayingSpinner
onready var _countdown_display = $CountdownDisplay

var _pending_track
var _current_contest
var _current_contest_timeout
var _accepting_guesses
var _is_currently_playing_track
var _contest_start_time

func enter(params):
	.enter(params)
	var _err = _contest_timeout_timer.connect("timeout", self, "_on_contest_timeout")
	NetworkInterface.on_player(Message.PROMPT_RESPONSE, self, "_on_player_prompt_response")
	_err = Events.connect("game_paused", self, "_on_game_paused")
	_err = Events.connect("game_resumed", self, "_on_game_resumed")
	_err = params.track_player.connect("ready_to_play", self, "_on_player_ready_to_play")
	for contest in params.current_round.contests:
		yield(_do_contest(contest), "completed")
	Log.info("Finished all contests in this round. Requesting round exit")
	emit_signal("request_exit", _parameters)

func exit():
	_stop_track()
	NetworkInterface.send_players(Room.players, Message.create(Message.HIDE_PROMPT, {}))
	NetworkInterface.off_player(Message.PROMPT_RESPONSE, self, "_on_player_prompt_response")
	_contest_timeout_timer.disconnect("timeout", self, "_on_contest_timeout")
	Events.disconnect("game_paused", self, "_on_game_paused")
	Events.disconnect("game_resumed", self, "_on_game_resumed")
	_parameters.track_player.disconnect("ready_to_play", self, "_on_player_ready_to_play")
	return .exit()

func _do_contest(contest):
	_player_icon_display.clear()
	_current_contest = contest
	_contest_start_time = OS.get_unix_time()
	_current_contest_timeout = min(default_contest_timeout, contest.track.DurationMs / 1000)
	_countdown_display.start(_current_contest_timeout)
	_contest_timeout_timer.start(_current_contest_timeout)
	Log.info("Attempting to play track: " + contest.track.Id)
	yield(_play_track(contest.track), "completed")
	# send prompts
	for player in contest.players:
		NetworkInterface.send_player(player, Message.create(Message.REQUEST_INPUT, {
			"promptType": "song_search",	# input type
			"promptData": {	# data that corresponds to input type
				"id": contest.id,
				"apiAccessToken": _parameters.track_player.CurrentAccessToken,
			}
		}))
	_accepting_guesses = true
	var winning_response = yield(self, "_finish_contest")
	NetworkInterface.send_players(Room.players, Message.create(Message.HIDE_PROMPT, {}))
	_accepting_guesses = false
	_countdown_display.stop()
	_stop_track()
	if winning_response:
		var points_group_id = str(len(_parameters.round_history))
		var points = _calculate_winner_points()
		winning_response.player.update_points(points, points_group_id)
		yield(get_tree().create_timer(1.0), "timeout")
		_player_icon_display.emphasise_and_center_player(winning_response.player)
		var player_icon = _player_icon_display.get_player_icon(winning_response.player)
		player_icon.animate_point_award(points)
		# delay before next contest or exit
		yield(get_tree().create_timer(5.0), "timeout")
	else:
		# show correct answer
		yield(get_tree().create_timer(2), "timeout")
		_play_track(contest.track)
		var song_guess_display = _contest_song_guess_scene.instance()
		_player_icon_display.add_child(song_guess_display)
		song_guess_display.init(_current_contest.track)
		yield(get_tree().create_timer(5.0), "timeout")
		_stop_track()
		_player_icon_display.remove_child(song_guess_display)

func _play_track(track):
	var success = yield(_parameters.track_player.Play(track.Id), "completed")
	_song_playing_spinning_indicator.spin(success)
	_is_currently_playing_track = success
	if success:
		Log.info("Playing track: " + track.Id)
		_pending_track = null
	else:
		Log.info("Failed to play track: " + track.Id)
		_pending_track = track

func _stop_track():
	Log.info("Stopping track")
	_parameters.track_player.Pause()
	_song_playing_spinning_indicator.spin(false)
	_is_currently_playing_track = false
	_pending_track = null

func _on_game_paused():
	_parameters.track_player.Pause()

func _on_game_resumed():
	if _is_currently_playing_track:
		_parameters.track_player.Resume()

func _on_player_prompt_response(client_id, message):
	if not _accepting_guesses:
		return
	var player = Room.find_player_by_id(client_id)
	if not player:
		return
	Log.info("Prompt response received from %s (%s)" % [client_id, player.username])

	NetworkInterface.send_player(player, Message.create(Message.HIDE_PROMPT, {}))

	var track
	if "trackId" in message.data and message.data.trackId:
		track = yield(_parameters.track_player.GetTrack(message.data.trackId), "completed")
		if not track.Title:
			Log.warn("Something went wrong then fetching track: " + message.data.trackId)
			return
		if not _accepting_guesses:	# another player may have submitted a correct answer while we fetched the track
			return

	for response in _current_contest.responses:
		if response.player == player:
			Log.warn("Player %s (%s) has already responsed to this contest. Ignoring" % [client_id, player.username])
			return
	
	var response = MusiQContestResponse.new(player, track)
	_current_contest.responses.append(response)
	
	var is_correct_answer = is_same_track(_current_contest.track, track)

	var player_icon = _player_icon_display.add_player(player)
	var song_guess_display = _contest_song_guess_scene.instance()
	player_icon.add_child(song_guess_display)
	
	if is_correct_answer:
		NetworkInterface.send_players(Room.players, Message.create(Message.HIDE_PROMPT, {}))
		emit_signal("_finish_contest", response)
		track = _current_contest.track
	elif len(_current_contest.responses) == len(_current_contest.players):
		emit_signal("_finish_contest", null)

	song_guess_display.init(track)
	yield(get_tree().create_timer(1.0), "timeout")
	song_guess_display.show_result(is_correct_answer)
		
func _on_contest_timeout():
	emit_signal("_finish_contest", null)

func is_same_track(track_a, track_b):
	if not track_a or not track_b:
		return false
	if FUZZY_SONG_MATCHING:
		Log.info("Doing fuzzy song comparison: " + track_a.Title + " == " + track_b.Title)
		return _sanitise_track_title(track_a.Title) == _sanitise_track_title(track_b.Title) and _is_same_artist(track_a, track_b)
	else:
		return track_a.Id == track_b.Id

func _sanitise_track_title(title):
	var PUNCTUATION_TO_REMOVE = "[](){}-.,"
	var PATTERNS_TO_REMOVE = [
		'( -)? Remastered (- )?([0-9]{4})?',
		' (- )?[0-9]{4} (- )?Remaster',
		'\\(Remastered( [0-9]{4})?\\)',
		'Remastered( [0-9]{4})?',
		'([0-9]{4} )?Remaster',
		' - Radio Edit',
		' - Edit',
		' - Single Version',
		' - Album Version'
	]
	for pattern in PATTERNS_TO_REMOVE:
		var regex = RegEx.new()
		regex.compile(pattern)
		title = regex.sub(title, "")
	for punc in PUNCTUATION_TO_REMOVE:
		title = title.replace(punc, "")
	return title.to_upper().strip_edges()

func _is_same_artist(track_a, track_b):
	return PoolStringArray(track_a.Artists).join(",") == PoolStringArray(track_b.Artists).join(",")

func _on_player_ready_to_play():
	if _pending_track:
		_play_track(_pending_track)

func _calculate_winner_points():
	var time_related_points = _contest_timeout_timer.time_left + _current_contest.point_weight
	return time_related_points
