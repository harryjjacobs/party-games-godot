tool
extends Label

export(int) var min_font_size = 10
export(int) var max_font_size = 80
export(int) var font_size_resolution = 5
var font: DynamicFont
var original_size
var old_text

func _enter_tree():
	font = get("custom_fonts/font")
	fit_in_rect()

func _process(_delta):
	if text != old_text:
		old_text = text
		fit_in_rect()

func _set(property, _value):
	if property == "text":
		fit_in_rect()

func fit_in_rect():
	if not font:
		return
	font.size = max_font_size;
	if autowrap:
		while get_visible_line_count() < get_line_count():
			font.size -= font_size_resolution;
			if font.size <= min_font_size:
				font.size = min_font_size
				break
	else:
		var text = tr(text)
		var text_rect_size = font.get_string_size(text)
		while text_rect_size.y > rect_size.y || text_rect_size.x > rect_size.x:
			text_rect_size = font.get_string_size(text)
			font.size -= font_size_resolution
			if font.size <= min_font_size:
				font.size = min_font_size
				break
