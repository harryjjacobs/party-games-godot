tool
extends Control

export(PackedScene) var caption_control
export(PackedScene) var caption_visualisation_control

export(Array, Color) var item_colors = [
	Color.red,
	Color.green,
	Color.blue,
	Color.yellow,
	Color.purple,
	Color.turquoise,
	Color.orange,
	Color.pink
]
var color_pool: Array

onready var captions_container = $HBoxContainer/ItemEditContainer/ItemsScrollContainer/MemeCaptions
onready var caption_visualisations_container = $HBoxContainer/VisualisationContainer/Preview/MemeCaptionVisualisation
onready var add_button = $HBoxContainer/ItemEditContainer/AddButton
onready var save_button = $HBoxContainer/ItemEditContainer/SaveButton

var template: MemeTemplate

func _ready():
	color_pool = item_colors.duplicate()

func edit_template(meme_template):
	template = meme_template
	_populate_captions()

func _populate_captions():
	for n in captions_container.get_children():
		n.queue_free()
	color_pool = item_colors.duplicate()
	for tti in template.captions:
		_create_new_item_control(tti)
	_update_item_visualisations()

func _create_new_item_control(caption):
	var control = caption_control.instance()
	if color_pool.empty():
		color_pool = item_colors.duplicate()
	control.set_caption(caption)
	control.set_color(color_pool.pop_front())
	control.connect("on_change", self, "_on_item_control_changed")
	control.connect("on_delete", self, "_on_item_control_delete")
	captions_container.add_child(control)
	_update_item_visualisations()

func _on_add_button_pressed():
	if not template:
		return
	var tti = MemeCaption.new()
	template.captions.append(tti)
	_create_new_item_control(tti)
	template.property_list_changed_notify()
	_update_item_visualisations()

func _on_item_control_changed(control):
	var item = control.caption
	template.captions[control.get_index()] = item
	template.property_list_changed_notify()
	_update_item_visualisations()

func _on_item_control_delete(control):
	template.captions.remove(control.get_index())
	control.queue_free()
	template.property_list_changed_notify()
	_update_item_visualisations()

func _update_item_visualisations():
	var vis_children = caption_visualisations_container.get_children().duplicate()
	for child in vis_children:
		child.queue_free()
	for capt_control in captions_container.get_children():
		var vis_control = caption_visualisation_control.instance()
		vis_control.set_caption(capt_control.caption, capt_control.color)
		caption_visualisations_container.add_child(vis_control)

func _on_save_button_pressed():
	ResourceSaver.save(template.resource_path, template)
	template.property_list_changed_notify()