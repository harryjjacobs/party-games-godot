extends Resource
class_name MemeCaption

export(int) var x
export(int) var y
export(int) var width
export(int) var height
export(float) var rotation
export(String) var text
export(String) var font_family = ''
export(bool) var uppercase = true
export(bool) var autosize = true
export(int) var font_size
export(bool) var center_h
export(bool) var center_v
export(Color) var text_color = Color.black
export(Color) var background_color = Color.transparent
export(bool) var outline_text
export(int) var outline_size = 3
export(Color) var outline_color = Color.black

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
		"fontFamily": font_family,
		"uppercase": uppercase,
		"fontSize": font_size,
		"centerH": center_h,
		"centerV": center_v,
		"color": _color_to_json(text_color),
		"backgroundColor": _color_to_json(background_color),
		"outlineText": outline_text,
		"outlineSize": outline_size,
		"outlineColor": _color_to_json(outline_color),
	}

func _color_to_json(color):
	return {
		"r": color.r,
		"g": color.g,
		"b": color.b,
		"a": color.a
	}
