extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player = null
var picked := false
var gold_amount: int = 0
var mouse_inside := false # 🆕 ÚJ: Figyeli, hogy az egér az arany felett van-e

func _ready():
	player = get_tree().get_first_node_in_group("player")
	
	# 🆕 ÚJ: Összekötjük a hover (egér be/ki) jelzéseket az aurához
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
	if gold_amount == 0:
		gold_amount = randi_range(20, 40)
		print("[GOLD_DEBUG] Új láda aranykupac megszületett. Értéke: ", gold_amount)
		set_as_top_level(false)
		global_position += Vector2(randf_range(-15, 15), randf_range(-8, 8))
	else:
		set_as_top_level(false)
		if player != null:
			global_position = player.global_position

	input_pickable = true
	y_sort_enabled = true
	if sprite:
		sprite.y_sort_enabled = true
		sprite.play("arany_anim")
		set_aura_active(false) # Induláskor kikapcsoljuk az aurát

# 🟡 EGÉR RÁKERÜL
func _on_mouse_entered() -> void:
	mouse_inside = true
	set_aura_active(true) # Aura bekapcsolása

# ⚫ EGÉR LEKERÜL
func _on_mouse_exited() -> void:
	mouse_inside = false
	set_aura_active(false) # Aura kikapcsolása

# 👑 SEGÉDFÜGGVÉNY AZ AURA SHADER VEZÉRLÉSÉHEZ
func set_aura_active(active: bool) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("is_active", active)

func _input_event(_viewport, event, _shape_idx):
	if picked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_player_in_radius():
			get_viewport().set_input_as_handled()
			pickup()

func _unhandled_input(event: InputEvent) -> void:
	if picked:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var distance_to_mouse = global_position.distance_to(mouse_pos)
		
		# 👑 JAVÍTÁS: Ha a 25 pixelen belül van VAGY a hover érzékeli az egeret, felveheti!
		if mouse_inside or distance_to_mouse <= 25.0:
			if is_player_in_radius():
				get_viewport().set_input_as_handled()
				pickup()

func is_player_in_radius() -> bool:
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= 180.0:
			return true
	return false

# 💰 AUTOMATIKUS ÖSSZEADÁS FIXEN EGYETLEN SLOTBA (PROPERTY ALAPÚ FIX, MAX 100 LIMIT)
func pickup():
	if picked:
		return

	var inventory = get_tree().get_first_node_in_group("inventory_group") as Inventory
	if inventory:
		var total_potential_gold = GlobalData.total_inventory_gold + gold_amount
		
		if total_potential_gold > 1000:
			print("[GOLD_DEBUG] FELVÉTEL BLOKKOLVA: A táska arany limitje (100) betelt! Jelenleg van: ", GlobalData.total_inventory_gold)
			
			var main_node = get_node_or_null("/root/Main")
			if main_node:
				var error_sfx = main_node.get_node_or_null("ErrorSound") as AudioStreamPlayer
				if error_sfx:
					error_sfx.play()
			return

		GlobalData.total_inventory_gold = total_potential_gold

		var existing_gold_slot = null
		for item in inventory.get_items():
			var item_image_path = item.get_property("image", "")
			if "arany" in str(item_image_path).to_lower() or "gold" in str(item_image_path).to_lower():
				existing_gold_slot = item
				break 

		if existing_gold_slot != null:
			print("[GOLD_DEBUG] >>> AUTOMATA ÖSSZEADÁS SIKER! Meglévő kupachoz adva. Új érték: ", GlobalData.total_inventory_gold)
			existing_gold_slot.set_property("name", "Arany (" + str(GlobalData.total_inventory_gold) + "g)")
		else:
			var uj_arany_item = inventory.create_and_add_item("gold_coin")
			if uj_arany_item:
				print("[GOLD_DEBUG] >>> ELSŐ ARANY FELVÉVE! Új tiszta slot nyitva: ", GlobalData.total_inventory_gold)
				uj_arany_item.set_property("name", "Arany (" + str(GlobalData.total_inventory_gold) + "g)")
			else:
				GlobalData.total_inventory_gold -= gold_amount
				return 

		var main_node = get_node_or_null("/root/Main")
		if main_node and main_node.has_method("save_inventory_to_file"):
			main_node.save_inventory_to_file()
			print("[GOLD_DEBUG] Arany miatti külső fájlmentés sikeresen kikényszerítve!")

		picked = true
		set_aura_active(false) # Eltüntetjük a fehér kiemelést felvételkor
		if sprite:
			sprite.play("arany_anim")
		await get_tree().create_timer(0.1).timeout
		queue_free()
