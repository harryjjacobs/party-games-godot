extends Node2D

const MusiQTrackPlayer = preload("res://musiq_game/track_player/MusiQTrackPlayer.cs")

onready var stage = $MusiQRoundBeginStage

var _track_player = MusiQTrackPlayer.new()

func _ready():
	Room.players = [
		Player.new("0", "Player 1"),
		Player.new("1", "Player 2"),
		Player.new("2", "Player 3")
	]

	var _track_player_auth_helper = MusiQPlayerAuthHelper.new(_track_player)

	yield(_track_player, "authorization_succeeded")

	var playable_collections = yield(_track_player.SearchPlaylistsAndAlbums("pop"), "completed")

	var playlists = [
		playable_collections.Playlists[0],
		playable_collections.Playlists[1]
	]
	var contest_builder = MusiQContestBuilder.new(playlists, _track_player)
	yield(contest_builder, "initialized")
	var params = {
		"round_generator": MusiQRoundGenerator.new(contest_builder, MusiQRoundGenerator.GameDurationProfile.SHORT),
		"current_round": null,
		"round_history": Array(),
	}
	stage.connect("request_exit", self, "_on_stage_exit")
	stage.enter(params)

func _on_stage_exit(params):
	assert(len(params.current_round.contests) > 0)
	var first_track = params.current_round.contests[0].track
	assert(!first_track.Title.empty())
	print(first_track.Title + " - " + first_track.Artists[0])
	Log.info("TEST PASSED")