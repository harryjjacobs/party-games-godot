extends Node
class_name TriviaService

const API_SESSION_TOKEN_URL = "https://opentdb.com/api_token.php"
const API_CATEGORIES_URL = "https://opentdb.com/api_category.php"
const API_QUERY_URL = "https://opentdb.com/api.php"

onready var _http_request = $HTTPRequest
var _session_token

class HttpResponse:
	var result
	var response_code
	var headers
	var body
	func _init(response):
		result = response[0]
		response_code = response[1]
		headers = response[2]
		body = response[3]

	func _to_string():
		return JSON.print({
			"result": result,
			"response_code": response_code, 
			"headers": headers, 
			"body": body, 
		})

func fetch_trivia(count: int, type: int = QuizTrivia.Type.ANY, difficulty: int = QuizTrivia.Difficulty.ANY, category: int = -1):
	yield(get_tree(), 'idle_frame')

	if not _session_token:
		_session_token = yield(_fetch_session_token(), "completed")

	var fields = {}

	if _session_token:
		fields["token"] = _session_token

	fields["encode"] = "url3986"

	fields["amount"] = count

	if category >= 0:
		fields["category"] = category

	match type:
		QuizTrivia.Type.MULTIPLE_CHOICE:
			fields["type"] = "multiple"
		QuizTrivia.Type.TRUE_FALSE:
			fields["type"] = "boolean"

	match difficulty:
		QuizTrivia.Difficulty.EASY:
			fields["difficulty"] = "easy"
		QuizTrivia.Difficulty.MEDIUM:
			fields["difficulty"] = "medium"
		QuizTrivia.Difficulty.HARD:
			fields["difficulty"] = "hard"
	
	var query_string = HTTPClient.new().query_string_from_dict(fields)
	var error = _http_request.request(API_QUERY_URL + "?" + query_string, [], true, HTTPClient.METHOD_GET)
	if error != OK:
		Log.error("Failed to fetch trivia. Error: %d" % error)
		return []

	var response = HttpResponse.new(yield(_http_request, "request_completed"))
	var response_body_json = JSON.parse(response.body.get_string_from_utf8())
	if response_body_json.error != OK:
		Log.error("Failed to parse JSON from response. Error %d" % response_body_json.error)
		return []
	if response_body_json.result.response_code != 0:
		Log.error("Failed to fetch trivia. API response code: " + error)
		return []

	var trivias = []

	for result in response_body_json.result.results:
		trivias.push_back(_trivia_from_json(result))

	return trivias

func get_categories():
	yield(get_tree(), 'idle_frame')
	var error = _http_request.request(API_CATEGORIES_URL, [], true, HTTPClient.METHOD_GET)
	if error != OK:
		Log.error("Failed to fetch categories. Error: %d" % error)
		return []

	var response = HttpResponse.new(yield(_http_request, "request_completed"))
	print(response.body.get_string_from_utf8())
	var response_body_json = JSON.parse(response.body.get_string_from_utf8())
	if response_body_json.error != OK:
		Log.error("Failed to parse JSON from categories response. Error %d" % response_body_json.error)
		return []

	var categories = []

	categories.push_back(QuizTriviaCategory.new(-1, "Any"))

	for category_data in response_body_json.result.trivia_categories:
		categories.push_back(QuizTriviaCategory.new(category_data["id"], category_data["name"]))

	return categories

func _fetch_session_token():
	yield(get_tree(), 'idle_frame')
	var query_string = HTTPClient.new().query_string_from_dict({"command": "request"})
	var error = _http_request.request(API_SESSION_TOKEN_URL + "?" + query_string, [], true, HTTPClient.METHOD_GET)
	if error != OK:
		Log.error("Failed to fetch session token. Error: %d" % error)
		return []
	var response = HttpResponse.new(yield(_http_request, "request_completed"))
	var response_body_json = JSON.parse(response.body.get_string_from_utf8())
	if response_body_json.error != OK:
		Log.error("Failed to parse JSON from response. Error %d" % response_body_json.error)
		return []
	if response_body_json.result.response_code != 0:
		Log.error("Failed to fetch session token. API response code: " + error)
		return []
	return response_body_json.result.token

func _trivia_from_json(json):
	var trivia = QuizTrivia.new()

	trivia.category = json["category"].percent_decode()

	match json["type"]:
		"multiple":
			trivia.type = QuizTrivia.Type.MULTIPLE_CHOICE
		"boolean":
			trivia.type = QuizTrivia.Type.TRUE_FALSE

	match json["difficulty"]:
		"easy":
			trivia.difficulty = QuizTrivia.Difficulty.EASY
		"medium":
			trivia.difficulty = QuizTrivia.Difficulty.MEDIUM
		"hard":
			trivia.difficulty = QuizTrivia.Difficulty.HARD

	trivia.question = json["question"].percent_decode()

	var correct_answer = json["correct_answer"].percent_decode()
	trivia.answers.push_back(correct_answer)
	for answer in json["incorrect_answers"]:
		trivia.answers.push_back(answer.percent_decode())
	trivia.answers.shuffle()
	trivia.correct_answer_index = trivia.answers.find(correct_answer)

	return trivia
