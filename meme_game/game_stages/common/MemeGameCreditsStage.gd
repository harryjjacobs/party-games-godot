extends "res://core/game_stages/common/GameStage.gd"

const MAX_BESTOF = 6
const HIGHLIGHTS_REEL_DURATION = 5.0
const HIGHLIGHTS_REEL_FADE_DURATION = 1.0

onready var _meme_renderer = $HBoxContainer/MemeRendererContainer/MemeRenderer
onready var _player_name_label = $HBoxContainer/MemeRendererContainer/MemeInformationPanel/PlayerNameLabel

var _saved_to_disk = []

func enter(params):
	.enter(params)
	_player_name_label.text = ""
	_highlight_reel()

func _highlight_reel():
	var highlights = _generate_highlights()
	while is_inside_tree():
		for highlight in highlights:
			_meme_renderer.render(highlight.template, highlight.response.captions)
			_player_name_label.text = " - " + highlight.response.player.username
			$Tween.interpolate_method(self, "_set_highlights_reel_alpha", 0.0, 1.0, HIGHLIGHTS_REEL_FADE_DURATION / 2)
			$Tween.start()
			yield($Tween, "tween_completed")
			if not is_inside_tree():
				return
			if not highlight in _saved_to_disk: 
				_save_meme_to_disk(_meme_renderer, highlight.response.player)
				_saved_to_disk.push_back(highlight)
			yield(get_tree().create_timer(HIGHLIGHTS_REEL_DURATION), "timeout")
			$Tween.interpolate_method(self, "_set_highlights_reel_alpha", 1.0, 0.0, HIGHLIGHTS_REEL_FADE_DURATION / 2)
			$Tween.start()
			yield($Tween, "tween_completed")
			if not is_inside_tree():
				return
			
func _generate_highlights():
	var response_vote_count = {}
	for r in _parameters.round_history:
		for contest in r.contests:
			for vote in contest.votes:
				if not response_vote_count.has(vote.choice):
					response_vote_count[vote.choice] = {
						"response": vote.choice,
						"template": contest.meme_template,
						"votes": 0
					}
				response_vote_count[vote.choice].votes += 1
	var highlights = response_vote_count.values()
	highlights.sort_custom(self, "_sort_descending_by_votes")
	if highlights:
		return highlights.slice(0, min(len(highlights) - 1, MAX_BESTOF))
	else:
		return []
		
func _set_highlights_reel_alpha(alpha):
	_meme_renderer.alpha = alpha
	var color = _player_name_label.get_color("font_color")
	color.a = alpha
	_player_name_label.add_color_override("font_color", color)

func _sort_descending_by_votes(a, b):
	return b.votes < a.votes

func _on_play_again_button_pressed():
		Events.emit_signal("request_restart", false)

func _on_play_again_same_players_button_pressed():
	Events.emit_signal("request_restart", true)

func _on_exit_to_main_menu_button_pressed():
	Events.emit_signal("request_main_menu")

func _save_meme_to_disk(meme_renderer, player):
	# save meme to disk
	var path = "user://saved_memes"
	FileUtils.open_user_dir(path, true)
	var img = yield(meme_renderer.capture(), "completed")
	var filename = player.username + "_" + Time.formatted_timestamp() + ".png"
	img.save_png(path + "/" + filename)
