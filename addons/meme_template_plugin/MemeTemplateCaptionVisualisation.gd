tool
extends ReferenceRect
class_name MemeCaptionVisualisation

var _item: MemeCaption
var _color: Color

func _ready():
  rect_position.x = _item.x
  rect_position.y = _item.y
  rect_size.x = _item.width
  rect_size.y = _item.height
  rect_rotation = _item.rotation
  border_color = _color

func set_caption(item: MemeCaption, color: Color):
  _item = item
  _color = color
