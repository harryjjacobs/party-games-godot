tool
extends PanelContainer
class_name MemeRenderer

export(bool) var debug_mode = false
export(float) var alpha = 1.0 setget _set_alpha, _get_alpha

onready var texture_rect = $TextureRect
onready var captions_parent = $Captions

const label_scene = preload("res://meme_game/meme/MemeCaptionLabel.tscn")

const FONT_LOOKUP = {
	"Anton": {
		400: preload("res://core/ui/fonts/Anton-Regular.tres")
	},
	"Ubuntu": {
		700: preload("res://core/ui/fonts/Ubuntu-Bold.tres")
	}
}

var _meme_template: MemeTemplate
var _texture
var _captions: Array
var _initial_texture

func _ready():
	_initial_texture = texture_rect.texture
	alpha = 1

func render(meme_template: MemeTemplate, captions: Array):
	assert(meme_template.image)
	_meme_template = meme_template
	_captions = captions
	_texture = meme_template.image
	texture_rect.texture = _texture
	yield(_create_labels(), "completed")

func clear():
	for child in captions_parent.get_children():
		child.queue_free()
	_meme_template = null
	_captions = []
	_texture = _initial_texture
	texture_rect.texture = _texture

func capture() -> Image:
	assert(_meme_template)
	var viewport = Viewport.new()
	viewport.usage = viewport.USAGE_2D
	viewport.render_target_update_mode = viewport.UPDATE_ALWAYS
	yield(get_tree(), "idle_frame")
	var displayed_rect = _get_displayed_texture_rect()
	viewport.size = displayed_rect.size
	get_tree().get_root().add_child(viewport)
	var duplicate_meme_renderer = load(filename).instance()
	viewport.add_child(duplicate_meme_renderer)
	viewport.add_child(Camera2D.new())

	duplicate_meme_renderer.set_position(Vector2.ZERO)
	duplicate_meme_renderer.rect_size = displayed_rect.size
	yield(duplicate_meme_renderer.render(_meme_template, _captions), "completed")

	yield(VisualServer, "frame_post_draw")

	var img = viewport.get_texture().get_data()
	img.flip_y()
	img.convert(Image.FORMAT_RGBA8)

	viewport.queue_free()

	return img

func set_editor_label_border_colors(colors: Array):
	var colors_copy = colors.duplicate()
	for label in captions_parent.get_children():
		var color = colors_copy.pop_front()
		if color:
			label.set_editor_border_color(color)

func _create_labels():
	yield(get_tree(), "idle_frame")
	for child in captions_parent.get_children():
		child.queue_free()
	for i in len(_captions):
		var caption = _meme_template.captions[i]
		var caption_text = _captions[i]
		var label = label_scene.instance()
		captions_parent.add_child(label)
		label.debug_mode = debug_mode
		var scaling_rect = _get_texture_scaling_rect()
		label.rect_position = scaling_rect.position + scaling_rect.size * Vector2(caption.x, caption.y)
		label.rect_size = scaling_rect.size * Vector2(caption.width, caption.height)
		label.rect_rotation = caption.rotation
		var modified_font
		if FONT_LOOKUP.has(caption.font_family):
			var weights = FONT_LOOKUP[caption.font_family]
			var font
			if weights.has(caption.font_weight):
				font = weights[caption.font_weight]
			elif weights.has(400):
				font = weights[400]
			else:
				font = weights[0]
			modified_font = font.duplicate()
		else:
			modified_font = label.get_font("font").duplicate()
		modified_font.outline_size = caption.outline_size if caption.outline_text else 0
		var outline_color = caption.text_color.inverted()
		label.add_color_override("font_outline_modulate", outline_color)
		label.add_font_override("font", modified_font)
		label.color = caption.text_color
		label.background_color = caption.background_color
		if caption.center_h:
			label.align = Label.ALIGN_CENTER
		if caption.center_v:
			label.valign = Label.VALIGN_CENTER
		label.text = caption_text

func _get_texture_scaling_rect():
	assert(texture_rect.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert(texture_rect.texture.get_size() != Vector2.ZERO)

	var orig_texture_size = _texture.get_size()
	
	var rect = _get_displayed_texture_rect()
	rect.size /= Vector2(orig_texture_size.x, orig_texture_size.y)

	return rect

func _get_displayed_texture_rect():
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
		
	rect.position = Vector2((container_size.x - tex_width) / 2, (container_size.y - tex_height) / 2)
	rect.size = Vector2(tex_width, tex_height)
	return rect

func _set_alpha(a):
	if texture_rect:
		texture_rect.material.set_shader_param("alpha", a)
		for caption_label in captions_parent.get_children():
			var color = caption_label.color
			color.a = a
			caption_label.color = color

func _get_alpha():
	if texture_rect:
		return texture_rect.material.get_shader_param("alpha")
	else:
		return 1
