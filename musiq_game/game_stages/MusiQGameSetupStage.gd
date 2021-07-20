extends "res://core/game_stages/common/GameStage.gd"

const MusiQTrackPlayer = preload("res://musiq_game/track_player/MusiQTrackPlayer.cs")
const PlayableSearchResult = preload("res://musiq_game/game_stages/PlaylistSearchResult.tscn")
const PlaylistItem = preload("res://musiq_game/game_stages/PlaylistItem.tscn")

const _MIN_PLAYLISTS = 1

onready var _play_button = $SetupOptionsContainer/PlayButton
onready var _playlist_search_edit = $SetupOptionsContainer/PlaylistsSearch/LineEdit
onready var _search_results_container = $SetupOptionsContainer/PlaylistsSearch/SearchResultsScrollContainer/SearchResults

var _track_player_auth_helper
var _track_player

var _selected_playlists

func enter(params):
	.enter(params)
	_play_button.visible = false
	_selected_playlists = []
	BackgroundMusic.play()
	_track_player = MusiQTrackPlayer.new()
	_track_player_auth_helper = MusiQPlayerAuthHelper.new(_track_player)
	_track_player.connect("ready_to_play", self, "_on_track_player_ready")
	# emit_signal("request_exit", {
	# 	"round_generator": round_generator,
	# 	"current_round": null,
	# 	"round_history": []
	# })


func exit():
	.exit()

func _populate_playlist_search_results(results):
	NodeUtils.remove_children(_search_results_container)
	for result in results.Playlists + results.Albums:
		var item = PlayableSearchResult.instance()
		_search_results_container.add_child(item)
		item.init(result)
		item.connect("pressed", self, "_on_search_result_pressed", [result])

func _add_item_to_chosen_playlists(item):
	pass

func _check_play_button_enable():
	var device_connection = yield(_track_player.CheckDeviceConnection(), "completed")
	_play_button.visible = (len(_selected_playlists) > _MIN_PLAYLISTS) and device_connection

func _on_track_player_ready():
	_check_play_button_enable()

func _on_playlist_search_text_changed(text):
	var results = yield(_track_player.SearchPlaylistsAndAlbums(text), "completed")
	_populate_playlist_search_results(results)

func _on_search_result_pressed():
	_playlist_search_edit.text = ""


func _on_play_button_pressed():
	pass
