extends PanelContainer

onready var texture_rect = $TextureRect
onready var captions_parent = $Captions

const label_scene = preload("res://memes/meme/MemeCaptionLabel.tscn")

var _meme_template: MemeTemplate
var _texture
var _captions: Array

func init(meme_template: MemeTemplate, captions: Array):
	assert(len(meme_template.captions) == len(captions))
	assert(meme_template.image)
	_meme_template = meme_template
	_captions = captions
	_texture = meme_template.image
	texture_rect.texture = _texture
	_create_labels()

func _create_labels():
	yield(get_tree(), "idle_frame")
	for i in len(_meme_template.captions):
		var caption = _meme_template.captions[i]
		var caption_text = _captions[i]
		var label = label_scene.instance()
		captions_parent.add_child(label)
		var scaling_rect = _get_texture_scaling_rect()
		label.rect_position = scaling_rect.position + scaling_rect.size * Vector2(caption.x, caption.y)
		label.rect_size = scaling_rect.size * Vector2(caption.width, caption.height)
		label.rect_rotation = caption.rotation
		label.add_color_override("font_color", caption.text_color)
		label.text = caption_text

func _get_texture_scaling_rect():
	assert(texture_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert(texture_rect.texture.get_size() != Vector2.ZERO)

	var rect = Rect2()
	var orig_texture_size = _texture.get_size()
	var container_size = texture_rect.rect_size
	var tex_width = orig_texture_size.x * container_size.y / orig_texture_size.y
	var tex_height = container_size.y
	if tex_width > container_size.x:
		tex_width = container_size.x
		tex_height = orig_texture_size.y * tex_width / orig_texture_size.x
	
	# offset
	rect.position = Vector2((container_size.x - tex_width) / 2, (container_size.y - tex_height) / 2)
	# scale
	rect.size = Vector2(tex_width / orig_texture_size.x, tex_height / orig_texture_size.y)
	
	return rect
