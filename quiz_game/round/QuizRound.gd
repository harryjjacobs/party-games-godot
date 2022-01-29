extends Object
class_name QuizRound

var category: QuizTriviaCategory
var questions: Array = []

func _init(p_category: QuizTriviaCategory, p_trivia: Array):
	category = p_category
	for trivia in p_trivia:
		questions.push_back(QuizQuestion.new(trivia))
