extends Resource
class_name ColorPalette

export(Array, Color) var colors: Array = []

func empty():
	return colors.empty()