extends Node2D
class_name QuizGamePlayerAnswer

onready var _answer_label = $Panel/HBoxContainer/AnswerLabel
onready var _correct_sprite = $CorrectSprite
onready var _incorrect_sprite = $IncorrectSprite

var _answer

func _ready():
	_correct_sprite.visible = false
	_incorrect_sprite.visible = false
	init(_answer)
	
func init(answer):
	if answer:
		_answer = answer
		if _answer_label:
			_answer_label.text = answer
		
func show_result(correct_answer: bool):
	if (correct_answer):
		_correct_sprite.visible = true
		$AnimationPlayer.play("CorrectAnswer")
	else:
		_incorrect_sprite.visible = true
		$AnimationPlayer.play("IncorrectAnswer")
