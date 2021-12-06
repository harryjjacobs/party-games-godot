extends Object
class_name TriviaRoundGenerator

static func generate_rounds(trivia_service: TriviaService, categories: Array, num_questions: int):
	var rounds = []
	for category in categories:
		var trivia = yield(trivia_service.fetch_trivia(
			num_questions, QuizTrivia.Type.ANY, QuizTrivia.Difficulty.ANY, category.id), "completed")
		rounds.push_back(QuizRound.new(category, trivia))
	return rounds
