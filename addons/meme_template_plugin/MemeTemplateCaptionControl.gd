tool
extends PanelContainer
class_name MemeCaptionControl

signal on_change(instance)
signal on_delete(instance)

onready var color_rect = $ColorRect
onready var position_x_field = $Fields/PositionXField/SpinBox
onready var position_y_field = $Fields/PositionYField/SpinBox
onready var width_field = $Fields/WidthField/SpinBox
onready var height_field = $Fields/HeightField/SpinBox
onready var rotation_field = $Fields/RotationField/SpinBox
onready var text_field = $Fields/PlaceholderTextField/TextEdit
onready var text_color_field = $Fields/TextColorField/ColorPickerButton
onready var background_color_field = $Fields/BackgroundColorField/ColorPickerButton
onready var outline_text_field = $Fields/OutlineTextField/CheckBox
onready var center_h = $Fields/HAlignmentField/CheckBox
onready var center_v = $Fields/VAlignmentField/CheckBox

var caption: MemeCaption
var color: Color

func _ready():
	_update_fields()
	position_x_field.connect("value_changed", self, "_on_field_changed")
	position_y_field.connect("value_changed", self, "_on_field_changed")
	width_field.connect("value_changed", self, "_on_field_changed")
	height_field.connect("value_changed", self, "_on_field_changed")
	rotation_field.connect("value_changed", self, "_on_field_changed")
	text_field.connect("text_changed", self, "_on_field_changed")
	text_color_field.connect("color_changed", self, "_on_field_changed")
	background_color_field.connect("color_changed", self, "_on_field_changed")
	outline_text_field.connect("toggled", self, "_on_field_changed")
	center_h.connect("toggled", self, "_on_field_changed")
	center_v.connect("toggled", self, "_on_field_changed")

func set_caption(_caption: MemeCaption):
	caption = _caption
	_update_fields()

func set_color(_color: Color):
	color = _color
	_update_fields()

func _update_caption():
	if is_inside_tree():
		caption.x = int(position_x_field.value)
		caption.y = int(position_y_field.value)
		caption.width = int(width_field.value)
		caption.height = int(height_field.value)
		caption.rotation = rotation_field.value
		caption.text = text_field.text
		caption.center_h = center_h.pressed
		caption.center_v = center_v.pressed
		caption.text_color = text_color_field.color
		caption.background_color = background_color_field.color
		caption.outline_text = outline_text_field.pressed

func _update_fields():
	if is_inside_tree():
		position_x_field.value = caption.x
		position_y_field.value = caption.y
		width_field.value = caption.width
		height_field.value = caption.height
		rotation_field.value = caption.rotation
		text_field.text = caption.text
		text_color_field.color = caption.text_color
		center_h.pressed = caption.center_h
		center_v.pressed = caption.center_v
		background_color_field.color = caption.background_color
		outline_text_field.pressed = caption.outline_text
		
		color_rect.color = color

func _on_delete_button_pressed():
	emit_signal("on_delete", self)

func _on_field_changed(_value = null):
	_update_caption()
	emit_signal("on_change", self)
