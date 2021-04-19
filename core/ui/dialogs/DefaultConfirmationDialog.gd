extends PopupDialog

onready var _title = $Title
onready var _subtitle = $Subtitle
onready var _yes_btn = $HBoxContainer/Yes
onready var _no_btn = $HBoxContainer/No

var title setget set_title
var subtitle setget set_subtitle
var yes_text setget set_yes_text
var no_text setget set_no_text

signal finished(result)

func set_title(title_text):
	_title.text = title_text

func set_subtitle(subtitle_text):
	_subtitle.text = subtitle_text

func set_yes_text(text):
	_yes_btn.text = text

func set_no_text(text):
	_no_btn.text = text

func _on_yes_pressed():
	hide()
	emit_signal("finished", true)

func _on_no_pressed():
	hide()
	emit_signal("finished", false)
