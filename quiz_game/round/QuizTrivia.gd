extends Object
class_name QuizTrivia

enum Type { ANY, MULTIPLE_CHOICE, TRUE_FALSE }
enum Difficulty { ANY, EASY, MEDIUM, HARD }

var category: QuizTriviaCategory
var type
var difficulty
var question: String
var answers: Array
var correct_answer_index: int

static func get_answers_as_options(p_answers: Array):
	var options = []
	var alphabet = "ABCDEFG"
	for i in range(len(p_answers)):
		var option = alphabet[i] + ") " + p_answers[i]
		options.push_back(option)
	return options
