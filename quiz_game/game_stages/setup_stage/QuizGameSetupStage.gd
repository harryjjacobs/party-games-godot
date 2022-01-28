extends "res://core/game_stages/common/GameStage.gd"

enum RoundLength { SHORT, MEDIUM, LONG }

const LoadingDialog = preload("res://quiz_game/ui/dialogs/QuizGameLoadingDialog.tscn")

# short, medium, long -> # questions per round
const ROUND_LENGTH_QUESTIONS_MAP = {
	RoundLength.SHORT: 4,
	RoundLength.MEDIUM: 8,
	RoundLength.LONG: 14
}

onready var _trivia_service = $TriviaService
onready var _categories_selection = $SetupOptionsContainer/QuizCategoriesSelection
onready var _play_button = $SetupOptionsContainer/PlayButton

var _selected_categories = []
var _questions_per_round

func enter(params):
	.enter(params)
	for player in Room.players:
		player.reset()
	_populate_categories()
	_update_playability()
	_update_questions_per_round(RoundLength.MEDIUM)
	_categories_selection.connect("categories_updated", self, "_on_categories_updated")

func exit():
	_categories_selection.disconnect("categories_updated", self, "_on_categories_updated")
	return .exit()

func _populate_categories():
	var dialog = LoadingDialog.instance()	
	Events.emit_signal("show_dialog", dialog)
	var categories = yield(_trivia_service.get_categories(), "completed")
	Events.emit_signal("hide_dialog", dialog)	
	_categories_selection.populate(categories)
	
func _update_playability():
	_play_button.disabled = _selected_categories.empty()

func _update_questions_per_round(length_level: int = RoundLength.MEDIUM):
	_questions_per_round = ROUND_LENGTH_QUESTIONS_MAP[length_level]

func _on_play_button_pressed():
	var dialog = LoadingDialog.instance()
	Events.emit_signal("show_dialog", dialog)
	var rounds = yield(TriviaRoundGenerator.generate_rounds(
		_trivia_service, _selected_categories, _questions_per_round),"completed")
	Events.emit_signal("hide_dialog", dialog)	
	emit_signal("request_exit", {
		"rounds": rounds,
		"current_round": null,
		"round_history": []
	})

func _on_round_length_slider_value_changed(value: float):
	_update_questions_per_round(int(value))

func _on_categories_updated(categories):
	_selected_categories = categories
	_update_playability()
