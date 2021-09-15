extends TextureRect
class_name NetworkTextureRect

var _http_request
var _url

func _ready():
	_http_request = HTTPRequest.new()
	_http_request.use_threads = true
	add_child(_http_request)
	_http_request.connect("request_completed", self, "_http_request_completed")
	if _url:
		_fetch_image()

func set_url(url):
	_url = url
	_fetch_image()

func _fetch_image():
	var error = _http_request.request(_url)
	if error != OK:
			push_error("An error occurred in the HTTP request.")

func _http_request_completed(_result, _response_code, _headers, body):
	var image = Image.new()
	var error
	# https://stackoverflow.com/a/12451102
	match Array(body.subarray(0, 3)):
		[137, 80, 78, 71]:
			error = image.load_png_from_buffer(body)
		[255, 216, 255, 224]:
			error = image.load_jpg_from_buffer(body)
		[66, 77, ..]:
			error = image.load_bmp_from_buffer(body)
		_:
			push_error("Unknown image format")
			return

	if error != OK:
			push_error("Couldn't load the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	self.texture = texture
