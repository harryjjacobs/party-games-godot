tool
extends "res://core/ui/WordWrapLabel.gd"

export(int) var min_font_size = 5
export(int) var max_font_size = 80
export(int) var font_size_resolution = 5
export (bool) var debug_mode = false
export(Color) var background_color := Color(1, 1, 1, 1) setget set_background_color

onready var _reference_rect = $ReferenceRect

var original_size
var old_text

var _font_size_to_width_k

func _enter_tree():
	_calculate_font_size_width_relationship()
	_fit_in_rect()
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

func _set(property, _value):
	if property == "text":
		_fit_in_rect()

func _calculate_font_size_width_relationship():
	var font = get_font("font")
	var min_font = font.duplicate()
	min_font.size = max(min_font_size, 1)
	var max_font = font.duplicate()
	max_font.size = max_font_size
	var test_str = "abcdefghijklmnopqrstuvqxwzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.,#"
	var test_len = len(test_str)
	var width_at_min = (min_font.get_string_size(test_str).x / test_len)
	var width_at_max = (max_font.get_string_size(test_str).x / test_len)
	var k_at_min = width_at_min / min_font.size
	var k_at_max = width_at_max / max_font.size
	_font_size_to_width_k = (k_at_min + k_at_max) / 2.0

func _fit_in_rect():
	if _reference_rect:
		_reference_rect.editor_only = not debug_mode
	var font = get_font("font")
	if not font:
		return
	font.size = max_font_size;
	regenerate_word_cache()
	var longest_line_count = len(get_longest_line())
	if longest_line_count == 0:
		return
	# initial estimate
	font.size = int(min(get_size().x / (_font_size_to_width_k * longest_line_count) + font_size_resolution, max_font_size))
	if autowrap:
		visible = false
		while get_visible_line_count() < get_line_count() or get_longest_line_width() > get_size().x:
			font.size -= font_size_resolution;
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
