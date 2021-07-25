tool
extends "res://core/ui/WordWrapLabel.gd"

export(int) var min_font_size = 5
export(int) var max_font_size = 80
export (bool) var debug_mode = false
export(Color) var background_color := Color(1, 1, 1, 1) setget set_background_color

const font_size_resolution = 4

onready var _reference_rect = $ReferenceRect

var original_size
var old_text

func _enter_tree():
	theme.set_color("font_color_shadow", "Control", Color.transparent)

func set_editor_border_color(color: Color):
	_reference_rect.border_color = color

func set_background_color(bg_color: Color):
	var stylebox_override = theme.get("/styles/default").duplicate()
	stylebox_override.set_bg_color(bg_color)
	add_stylebox_override("normal", stylebox_override)

func _process(_delta):
	if text != old_text:
		old_text = text
		_fit_in_rect()

func _fit_in_rect():
	if _reference_rect:
		_reference_rect.editor_only = not debug_mode
	var font = get_font("font")
	if not font:
		return
	font.size = max_font_size
	regenerate_word_cache()
	var longest_line_count = len(get_longest_line())
	if longest_line_count == 0:
		return
	# initial estimate
	var max_text_width = get_longest_line_width()
	var max_text_height = get_line_count() * font.size
	var initial_font_estimate = min(font.size * max(get_size().x / max_text_width, get_size().y / max_text_height), font.size)
	font.size = initial_font_estimate
	if autowrap:
		visible = false
		while get_visible_line_count() < get_line_count() or get_longest_line_width() > get_size().x:
			font.size -= font_size_resolution
			if font.size <= min_font_size:
				font.size = min_font_size
				break
			regenerate_word_cache()
		visible = true
	else:
		var text = tr(text)
		var text_rect_size = font.get_string_size(text)
		while text_rect_size.y > rect_size.y || text_rect_size.x > rect_size.x:
			text_rect_size = font.get_string_size(text)
			font.size -= font_size_resolution
			if font.size <= min_font_size:
				font.size = min_font_size
				break		
	regenerate_word_cache()
