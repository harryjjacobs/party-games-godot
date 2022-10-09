extends Node2D

const MusiQTrackPlayer = preload("res://musiq_game/track_player/MusiQTrackPlayer.cs")

var _track_player
var _track_player_auth_helper

func _ready():
	_track_player = MusiQTrackPlayer.new()
	_track_player_auth_helper = MusiQPlayerAuthHelper.new(_track_player)
	yield(_track_player, "authorization_succeeded")
	print("ACCESS TOKEN:")
	print(_track_player.CurrentAccessToken)
	print("TEST PASSED")
