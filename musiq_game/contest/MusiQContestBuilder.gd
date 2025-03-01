extends Object
class_name MusiQContestBuilder

signal initialized

var _track_player
var _playlists = []
var _playlist_tracks = {}
var _used_tracks = []
var _playlist_index = 0

func _init(playlists, track_player):
	if len(playlists) == 0:
		push_error("playlists is empty")
	_track_player = track_player
	_playlists = playlists.duplicate()
	_playlist_index = 0
	for playlist in _playlists:
		var tracks = yield(_track_player.FetchPlayableItemCollectionTracks(playlist), "completed")
		_playlist_tracks[playlist] = tracks
	emit_signal("initialized")

func build(players, point_weight, contest_type):
	var contest = MusiQContest.new()
	contest.players = players
	contest.type = contest_type
	contest.point_weight = point_weight
	match contest_type:
		MusiQContest.ContestType.ALLVALL:
			contest.track = _get_next_track()
		MusiQContest.ContestType.HEAD2HEAD:
			contest.track = _get_next_track()
		_:
			Log.error("Invalid ContestType: %s" % contest_type)
	return contest

func _get_next_track():
	var track
	var MAX_ITER = 1000
	var iter = 0
	while not track and iter < MAX_ITER:
		var playlist = _playlists[_playlist_index]
		var tracks = _playlist_tracks[playlist]
		if tracks.empty():
			continue
		var track_i = randi() % len(tracks)
		if not tracks[track_i] in _used_tracks:
			track = tracks[track_i]
		iter += 1
		# cycle through each playlist
		_playlist_index = (_playlist_index + 1) % len(_playlists)
	_used_tracks.push_back(track)
	return track
