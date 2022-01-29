extends PopupDialog

onready var _title = $Title
onready var _subtitle = $Subtitle
onready var _yes_btn = $HBoxContainer/Yes
onready var _no_btn = $HBoxContainer/No

var title = "Are you sure?" setget set_title
var subtitle = "" setget set_subtitle
var yes_text = "Yes" setget set_yes_text
var no_text = "No" setget set_no_text

signal finished(result)

func _ready():
	set_title(title)
	set_subtitle(subtitle)
	set_yes_text(yes_text)
	set_no_text(no_text)

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_no_pressed()

func _on_about_to_show():
	_title.add_font_override("font", get_font("large", "Fonts").duplicate())
	_subtitle.add_font_override("font", get_font("normal", "Fonts").duplicate())
	
func set_title(title_text):
	title = title_text
	if _title:
		_title.text = title_text

func set_subtitle(subtitle_text):
	subtitle = subtitle_text
	if _subtitle:
		_subtitle.text = subtitle_text

func set_yes_text(text):
	yes_text = text
	if _yes_btn:
		_yes_btn.text = text

func set_no_text(text):
	no_text = text
	if _no_btn:
		_no_btn.text = text

func _on_yes_pressed():
	hide()
	emit_signal("finished", true)

func _on_no_pressed():
	hide()
	emit_signal("finished", false)
