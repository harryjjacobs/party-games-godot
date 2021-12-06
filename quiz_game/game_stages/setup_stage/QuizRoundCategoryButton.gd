tool
extends Button

var category

func init(p_category: QuizTriviaCategory):
	category = p_category
	$CategoryLabel.text = category.name
