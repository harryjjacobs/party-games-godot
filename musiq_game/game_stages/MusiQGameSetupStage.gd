extends "res://core/game_stages/common/GameStage.gd"

const MusiQTrackPlayer = preload("res://musiq_game/track_player/MusiQTrackPlayer.cs")
const PlayableSearchResult = preload("res://musiq_game/game_stages/PlaylistSearchResult.tscn")
const PlaylistItem = preload("res://musiq_game/game_stages/PlaylistItem.tscn")
const LoadingDialog = preload("res://musiq_game/ui/dialogs/MusiqLoadingDialog.tscn")

const _MIN_PLAYLISTS = 1
const _MAX_SEARCH_RESULTS = 10

onready var _play_button = $SetupOptionsContainer/PlayButton
onready var _play_button_disabled_explanation_label = $SetupOptionsContainer/PlayButtonDisabledExplanationLabel
onready var _playlist_search_edit = $SetupOptionsContainer/PlaylistsSearch/LineEdit
onready var _search_results_container = $SetupOptionsContainer/PlaylistsSearch/SearchResultsScrollContainer/SearchResults
onready var _chosen_playlists_container = $SetupOptionsContainer/ChosenPlaylistsScrollContainer/ChosenPlaylistsContainer
onready var _game_duration_profile_slider = $SetupOptionsContainer/VBoxContainer/GameDurationProfileHSlider

var _track_player_auth_helper
var _track_player
var _search_task

var _selected_playlists
var _game_duration_profile = MusiQRoundGenerator.GameDurationProfile.MEDIUM

func enter(params):
	.enter(params)
	for player in Room.players:
		player.reset()
	_play_button.disabled = true
	_play_button_disabled_explanation_label.visible = _play_button.disabled
	_game_duration_profile_slider.value = _game_duration_profile
	_selected_playlists = []
	_track_player = MusiQTrackPlayer.new()
	_track_player.connect("ready_to_play", self, "_on_track_player_ready")
	_track_player_auth_helper = MusiQPlayerAuthHelper.new(_track_player)

func exit():
	_track_player.disconnect("ready_to_play", self, "_on_track_player_ready")
	return .exit()

func _populate_playlist_search_results(results):
	NodeUtils.remove_children(_search_results_container)
	var combined_results = []
	for i in range(_MAX_SEARCH_RESULTS):
		if i < len(results.Playlists):
			combined_results.push_back(results.Playlists[i])
		if i < len(results.Albums):
			combined_results.push_back(results.Albums[i])
	for result in combined_results:
		var item = PlayableSearchResult.instance()
		_search_results_container.add_child(item)
		item.init(result)
		item.connect("pressed", self, "_on_search_result_pressed", [result])

func _add_item_to_chosen_playlists(item):
	_selected_playlists.push_back(item)
	var item_node = PlaylistItem.instance()
	_chosen_playlists_container.add_child(item_node)
	item_node.init(item)
	item_node.connect("request_remove", self, "_on_remove_chosen_playlist", [item_node, item])
	_check_play_button_enable()
	
func _remove_item_from_chosen_playlists(item_node, item):
	_selected_playlists.erase(item)
	item_node.queue_free()
	_check_play_button_enable()

func _check_play_button_enable():
	var device_connection = yield(_track_player.CheckDeviceConnection(), "completed")
	_play_button.disabled = (len(_selected_playlists) < _MIN_PLAYLISTS) or not device_connection
	_play_button_disabled_explanation_label.visible = _play_button.disabled

func _cancel_search():
	if _search_task and _search_task.is_connected("completed", self, "_populate_playlist_search_results"):
		_search_task.disconnect("completed", self, "_populate_playlist_search_results")

func _on_track_player_ready():
	_check_play_button_enable()

func _on_playlist_search_text_changed(text):
	_cancel_search()
	if text.empty():
		NodeUtils.remove_children(_search_results_container)
		return
	_search_task = _track_player.SearchPlaylistsAndAlbums(text)
	_search_task.connect("completed", self, "_populate_playlist_search_results")

func _on_search_result_pressed(item):
	_playlist_search_edit.text = ""
	NodeUtils.remove_children(_search_results_container)
	_cancel_search()
	_add_item_to_chosen_playlists(item)

func _on_remove_chosen_playlist(item_node, item):
	_remove_item_from_chosen_playlists(item_node, item)

func _on_play_button_pressed():
	var dialog = LoadingDialog.instance()
	Events.emit_signal("show_dialog", dialog)
	var contest_builder = MusiQContestBuilder.new(_selected_playlists, _track_player)
	yield(contest_builder, "initialized")
	Events.emit_signal("hide_dialog", dialog)		
	emit_signal("request_exit", {
		"round_generator": MusiQRoundGenerator.new(contest_builder, _game_duration_profile),
		"current_round": null,
		"round_history": [],
		"track_player": _track_player,
		"auth_helper": _track_player_auth_helper
	})

func _on_game_duration_profile_slider_value_changed(value):
	_game_duration_profile = int(value)
