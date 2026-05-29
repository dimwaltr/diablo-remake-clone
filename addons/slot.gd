extends Control
class_name Slot

var icon: TextureRect

func _ready():
	icon = get_node("TextureRect")

	if icon == null:
		push_error("TextureRect not found in Slot!")

func set_item(item):
	if icon == null:
		return

	if item == null:
		icon.texture = null
		return

	icon.texture = item.icon
