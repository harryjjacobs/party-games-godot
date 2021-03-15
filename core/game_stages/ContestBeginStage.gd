extends "res://core/game_stages/common/GameStage.gd"

export(float) var duration = 7

onready var _tween = $Tween
onready var _title = $Title
onready var _subtitle = $Subtitle

func _ready():
	pass
	_tween_title()

func enter(params):
	.enter(params)
	set_timeout(duration, params)
	_tween_title()

func _tween_title():
	var tween_duration = 0.5
	var title_tween_delay = 1.0
	var subtitle_tween_delay = 2.0

	_tween.interpolate_property(_title, "rect_scale", 
		Vector2.ZERO, _title.rect_scale, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN, title_tween_delay)
	_tween.interpolate_property(_title, "rect_rotation", 
		_title.rect_rotation - 90, _title.rect_rotation, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN, title_tween_delay)
	_title.rect_scale = Vector2.ZERO

	var subtitle_font_color = _subtitle.get("custom_colors/font_color")
	var transparent_subtitle_font_color = Color(subtitle_font_color.r, 
		subtitle_font_color.g, subtitle_font_color.b, 0)
	_tween.interpolate_property(_subtitle, "custom_colors/font_color", 
		transparent_subtitle_font_color, subtitle_font_color, tween_duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN, subtitle_tween_delay)
	_subtitle.set("custom_colors/font_color", transparent_subtitle_font_color)

	_tween.start()
