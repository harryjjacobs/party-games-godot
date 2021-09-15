extends Node

const _API_URL_BASE = "https://api.qrserver.com/v1/create-qr-code/"

onready var _http_request = $HTTPRequest

signal request_completed(texture)

func _ready():
	_http_request.connect("request_completed", self, "_http_request_completed")

func request_qr_code(data, size = 512):
	var url = _build_params(_API_URL_BASE, { "size": size, "data": data })
	var error = _http_request.request(url)
	var error_msg = ""
	match error:
		OK:
			return true
		ERR_UNCONFIGURED:
			error_msg = "Node not in tree"
			continue
		ERR_INVALID_PARAMETER:
			error_msg = "URL not valid"
			continue
		ERR_CANT_CONNECT:
			error_msg = "Can't connect"
	Log.warn("request_qr_code failed to create http request: %s. URL: %s" % [error_msg, url])
	return false

func _http_request_completed(result, response_code, _headers, body):
	if not is_inside_tree():
		return
	if result != HTTPRequest.RESULT_SUCCESS:
		Log.warn("request_qr_code http request failed: %s" % result)
		emit_signal("request_completed", null)
		return

	if response_code != 200:
		Log.warn("request_qr_code http request returned with non-OK response code: %s" % response_code)
		emit_signal("request_completed", null)
		return

	var image = Image.new()
	var error = image.load_png_from_buffer(body)
	if error != OK:
			push_error("Couldn't load the image.")

	var texture = ImageTexture.new()
	texture.create_from_image(image)

	emit_signal("request_completed", texture)

func _build_params(url, param_dict):
	var first = true
	for key in param_dict:
		url += "?" if first else "&"
		url += ("%s=%s" % [key, String(param_dict[key]).http_escape()])
		first = false
	return url
