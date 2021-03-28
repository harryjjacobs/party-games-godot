tool
extends EditorPlugin

const dock_scene = preload("res://addons/meme_template_plugin/MemeTemplateEditorPanel.tscn")

# Hold the dock during the plugin life cycle.
var dock

# Store currently edited object
var current_object

func handles(object):
	return object is MemeTemplate

func edit(object):
	current_object = object
	dock.edit_template(current_object)

func make_visible(visible: bool):
	if visible and current_object:
		make_bottom_panel_item_visible(dock)
		dock.edit_template(current_object)
	else:
		hide_bottom_panel()

func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instance it.
	dock = dock_scene.instance()
	var editor_viewport = get_editor_interface().get_editor_viewport()
	yield(get_tree(), 'idle_frame')
	dock.rect_min_size.y = editor_viewport.rect_size.y * 0.49
	# Add the loaded scene to the bottom panel
	add_control_to_bottom_panel(dock, "Meme Template")
	
func _exit_tree():
	remove_control_from_bottom_panel(dock)
	dock.queue_free()
