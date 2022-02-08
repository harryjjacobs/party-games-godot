extends Object
class_name QuizQuestion

var id: String
var trivia: QuizTrivia
var responses: Array
var points: int

func _init(p_trivia: QuizTrivia, p_points: int = 1):
	id = UUID.v4()
	trivia = p_trivia
	points = p_points
