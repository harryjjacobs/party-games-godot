extends Object
class_name ColorGenerator

export(Resource) var palette

var _current = 0

func _init(color_palette: ColorPalette):
	palette = color_palette

func next():
	if palette.empty():
		return
	if _current >= len(palette.colors):
		_current = 0
	var color = palette.colors[_current]
	_current += 1
	return color