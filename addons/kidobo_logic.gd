extends Control

var main_node = null

# A Godot beépített UI függvénye: Megengedi, hogy a GLoot tárgyat raddobjuk erre a felületre?
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# Ha a vonszolt adat egy Dictionary és van benne GLoot item, akkor IGENT mondunk (true)
	if data and typeof(data) == TYPE_DICTIONARY and data.has("item"):
		return true
	return false

# A Godot beépített UI függvénye: Ez fut le a szent pillanatban, amikor ELENGEDED az egeret kint!
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if main_node and data and data.has("item"):
		# Átadjuk a megfogott tárgyat a Main scriptnek kidobásra
		main_node.execute_drop_from_zone(data["item"])
