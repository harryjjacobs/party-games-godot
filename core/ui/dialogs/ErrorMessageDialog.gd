extends PopupDialog

onready var _title = $Title
onready var _subtitle = $Subtitle
onready var _ok_btn = $HBoxContainer/Ok

signal finished(result)

var error_msg = "An unknown error occurred" setget set_error_text

func _ready():
	set_error_text(error_msg)

func set_error_text(p_error_msg):
	error_msg = p_error_msg
	if _subtitle:
		_subtitle.text = error_msg

func _on_about_to_show():
	_title.add_font_override("font", get_font("large", "Fonts").duplicate())
	_subtitle.add_font_override("font", get_font("normal", "Fonts").duplicate())

func _on_ok_pressed():
	hide()
	emit_signal("finished", true)
