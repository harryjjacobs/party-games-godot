extends Resource
class_name MemeCaption

export(int) var x
export(int) var y
export(int) var width
export(int) var height
export(float) var rotation
export(Color) var text_color = Color.black
export(Color) var background_color = Color.transparent
export(bool) var center_h
export(bool) var center_v
export(bool) var outline_text
export(String) var text

func to_json():
	return {
		"area": {
			"x": x,
			"y": y,
			"width": width,
			"height": height
		},
		"rotation": rotation,
		"text": text,
		"text_color": _color_to_json(text_color),
		"background_color": _color_to_json(background_color),
		"outline_text": outline_text,
		"center_h": center_h,
		"center_v": center_v
	}

func _color_to_json(color):
	return {
		"r": color.r,
		"g": color.g,
		"b": color.b,
		"a": color.a
	}
