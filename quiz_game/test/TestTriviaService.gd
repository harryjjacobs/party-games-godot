extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var trivia = yield($TriviaService.fetch_trivia(10, QuizTrivia.Type.ANY, QuizTrivia.Difficulty.ANY, -1), "completed")
	assert(len(trivia) == 10)

	print("TEST SUCCEEDED")
