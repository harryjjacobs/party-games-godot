tool
extends Node2D

export(bool) var flip_h
export(bool) var disable_inspector_tool
export(Vector2) var speech_bubble_position = Vector2(-400, 0)
export(Vector2) var meme_renderer_position = Vector2(-400, 0)
export(Vector2) var player_icon_position = Vector2(-840, 0)
export(Vector2) var emphasis_scale = Vector2(1.1, 1.1)

onready var _tween = $Tween
onready var _speech_bubble_origin = $Pivot
onready var _speech_bubble_sprite = $Pivot/SpeechBubble
onready var _player_icon_container = $Pivot/PlayerIconContainer
onready var _player_icon = $Pivot/PlayerIconContainer/PlayerIcon
onready var _player_icon_placeholder = $Pivot/PlayerIconContainer/PlayerIconPlaceholder
onready var meme_renderer = $Pivot/SpeechBubble/MemeRenderer
onready var _votes_container = $Pivot/SpeechBubble/VotesContainer
onready var _no_captions_display = $Pivot/SpeechBubble/MemeRenderer/NoCaptionsPanel

var _original_scale

func _ready():
	_original_scale = scale
	_no_captions_display.hide()
	close()

func _process(_delta):
	if not disable_inspector_tool and Engine.editor_hint:
		_update_positions()

func open(player: Player, meme_template: MemeTemplate, captions: Array = []):
	_player_icon.init(player)
	meme_renderer.render(meme_template, captions)
	scale = _original_scale
	_no_captions_display.visible = len(captions) == 0
	show_votes([])
	hide_player_icon()
	_update_positions()
	if not Engine.editor_hint:
		_tween_entry()

func close():
	visible = false
	hide_player_icon()
	_update_positions()

func hide_player_icon():
	_player_icon.visible = false
	_player_icon_placeholder.visible = true

func show_player_icon():
	_player_icon.show()
	_player_icon_placeholder.visible = false

func show_votes(players):
	_votes_container.set_players(players)

func show_point_award(amount):
	_player_icon.animate_point_award(amount)

func emphasise(state):
	_tween_emphasis(state)

func _update_positions():
	if not _speech_bubble_sprite:
		return
	_speech_bubble_sprite.flip_h = flip_h
	if flip_h:
		_speech_bubble_sprite.position = Vector2(-1, 1) * speech_bubble_position
		_player_icon_container.position = Vector2(-1, 1) * player_icon_position
		meme_renderer.rect_position = Vector2(-1, 1) * meme_renderer_position - \
			Vector2(meme_renderer.rect_size.x, 0)
	else:
		_speech_bubble_sprite.position = speech_bubble_position
		_player_icon_container.position = player_icon_position
		meme_renderer.rect_position = meme_renderer_position

func _tween_entry():
	visible = true
#	var duration = 0.2
#	var delay = 0.0
#	var speech_bubble_tween = _speech_bubble_sprite.get_node("Tween")
#	speech_bubble_tween.interpolate_property(_speech_bubble_sprite, "scale", 
#		Vector2(0,0), _speech_bubble_sprite.scale, duration,
#		Tween.TRANS_LINEAR, Tween.EASE_IN, delay)
#	speech_bubble_tween.interpolate_property(_speech_bubble_sprite, "position", 
#		_player_icon.position, _speech_bubble_sprite.position, duration,
#		Tween.TRANS_LINEAR, Tween.EASE_IN, delay)
#	_speech_bubble_sprite.scale = Vector2(0, 0)
#	_speech_bubble_sprite.position = _player_icon.position
#	speech_bubble_tween.start()

func _tween_emphasis(emphasise: bool):
	var duration = 0.1
	var from 
	var to
	if emphasise:
		from = _original_scale
		to = emphasis_scale
	else:
		from = emphasis_scale
		to = _original_scale
	_tween.interpolate_property(self, "scale", from, to, duration,
		Tween.TRANS_LINEAR, Tween.EASE_IN, 0)
	scale = from
	_tween.start()
