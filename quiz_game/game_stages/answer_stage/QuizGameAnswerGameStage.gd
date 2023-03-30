extends "res://core/game_stages/common/GameStage.gd"

const PlayerAnswerScene = preload("res://quiz_game/game_stages/answer_stage/QuizGamePlayerAnswer.tscn")

onready var _question_label = $VBoxContainer/Question
onready var _answer_label = $VBoxContainer/CorrectAnswer
onready var _player_icon_display = $VBoxContainer/PlayerIconDisplay

var _current_question
var _options

func enter(params):
	.enter(params)
	_current_question = params.current_round.questions[params.question_index]
	_options = QuizTrivia.get_answers_as_options(_current_question.trivia.answers)
	
	_question_label.text = _current_question.trivia.question
	
	if is_inside_tree():
		yield(get_tree().create_timer(2.0), "timeout")
		_display_player_answers()
	
	if is_inside_tree():
		yield(get_tree().create_timer(2.0), "timeout")
		_display_correct_answer()
	
	if is_inside_tree():
		yield(_display_player_results(), "completed")
	
	if is_inside_tree():
		yield(get_tree().create_timer(4), "timeout")
	
	params.question_index += 1
	emit_signal("request_exit", params)

func exit():
	.exit()
	_question_label.text = ""
	_answer_label.text = ""
	_player_icon_display.clear()
	if _parameters.question_index == len(_parameters.current_round.questions):
		return StageExitTransition.NEXT_STAGE
	else:
		return StageExitTransition.REPEAT_GROUP
		
func get_group_name():
	return "q_and_a"

func _display_player_answers():
	for player in Room.players:
		var player_icon = _player_icon_display.add_player(player)
		var player_answer_display = PlayerAnswerScene.instance()
		player_icon.add_child(player_answer_display)
		var response = _find_response_by_player(player)
		if response:
			player_answer_display.init(_options[response.choice])

func _display_correct_answer():
	var correct_option = _options[_current_question.trivia.correct_answer_index]
	_answer_label.text = correct_option

func _display_player_results():
	for player in Room.players:
		var player_icon = _player_icon_display.get_player_icon(player)
		var player_answer_display = NodeUtils.find_child_of_type(player_icon, QuizGamePlayerAnswer)
		var response = _find_response_by_player(player)
		var correct_index = _current_question.trivia.correct_answer_index
		var is_correct = (response and response.choice == correct_index)
		if is_correct:
			var points_group = str(len(_parameters.round_history))
			player.update_points(_current_question.points, points_group)
			player_icon.animate_point_award(_current_question.points)
		player_answer_display.show_result(is_correct)
		if is_inside_tree():
			yield(get_tree().create_timer(0.5), "timeout")
		else:
			return

func _find_response_by_player(player):
	for response in _current_question.responses:
		if response.player == player:
			return response
	return null
