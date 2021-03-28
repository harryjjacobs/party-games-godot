tool
extends Control

export(PackedScene) var caption_control

const item_colors = [
	Color.red,
	Color.green,
	Color.blue,
	Color.yellow,
	Color.purple,
	Color.turquoise,
	Color.orange,
	Color.pink,
	Color.brown
]
var color_pool: Array

onready var captions_container = $HBoxContainer/ItemEditContainer/ItemsScrollContainer/MemeCaptions
onready var meme_renderer = $HBoxContainer/VisualisationContainer/MemeRenderer
onready var add_button = $HBoxContainer/ItemEditContainer/AddButton
onready var save_button = $HBoxContainer/ItemEditContainer/SaveButton

var template: MemeTemplate

func _ready():
	color_pool = item_colors.duplicate()

func edit_template(meme_template):
	#print("caption width: ", meme_template.captions[0].width)
	template = meme_template
	color_pool = item_colors.duplicate()
	_populate_captions()
	_update_meme_renderer()

func _populate_captions():
	for n in captions_container.get_children():
		n.queue_free()
	color_pool = item_colors.duplicate()
	for tti in template.captions:
		_create_new_item_control(tti)

func _create_new_item_control(caption):
	var control = caption_control.instance()
	if color_pool.empty():
		color_pool = item_colors.duplicate()
	control.set_caption(caption)
	control.set_color(color_pool.pop_front())
	control.connect("on_change", self, "_on_item_control_changed")
	control.connect("on_delete", self, "_on_item_control_delete")
	captions_container.add_child(control)

func _on_add_button_pressed():
	if not template:
		return
	var tti = MemeCaption.new()
	template.captions.append(tti)
	_create_new_item_control(tti)
	template.property_list_changed_notify()
	_update_meme_renderer()

func _on_item_control_changed(control):
	var item = control.caption
	template.captions[control.get_index()] = item
	template.property_list_changed_notify()
	_update_meme_renderer()

func _on_item_control_delete(control):
	template.captions.remove(control.get_index())
	control.queue_free()
	template.property_list_changed_notify()
	_update_meme_renderer()

func _update_meme_renderer():
	var captions_text = []
	for caption in template.captions:
		captions_text.append(caption.text)
	meme_renderer.init(template, captions_text)
	# label border colors editor visualisation 
	var label_border_colors = []
	for caption_control in captions_container.get_children():
		label_border_colors.append(caption_control.color)
	meme_renderer.set_editor_label_border_colors(label_border_colors)

func _on_save_button_pressed():
	ResourceSaver.save(template.resource_path, template)
	template.property_list_changed_notify()