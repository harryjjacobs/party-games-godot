extends Resource
class_name MemeCaption

export(int) var x
export(int) var y
export(int) var width
export(int) var height
export(float) var rotation
export(Color) var text_color = Color.black
export(bool) var center_h
export(bool) var center_v
export(String) var text

func to_json():
  return {
    "area": {
      "x": x,
      "y": y,
      "width": width,
      "height": height
    },
    "rotation": rotation,
    "color": text_color.to_html(false),
    "center_h": center_h,
    "center_v": center_v
  }