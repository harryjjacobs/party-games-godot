extends WindowDialog

signal request_refresh
signal finished(result)

onready var _device_list_container = $VBoxContainer/DeviceListScrollContainer/DeviceListContainer

func _ready():
	get_close_button().visible = false

func set_devices(devices):
	NodeUtils.remove_children(_device_list_container)
	for device in devices:
		var button = Button.new()
		button.text = device.Name
		button.connect("pressed", self, "_on_device_chosen", [device])
		_device_list_container.add_child(button)

func _on_device_chosen(device):
	emit_signal("finished", device)
	hide()

func _on_cancel_button_pressed():
	emit_signal("finished")

func _on_refresh_button_pressed():
	emit_signal("request_refresh", self)
