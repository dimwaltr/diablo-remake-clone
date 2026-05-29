extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player = null
var picked := false
var gold_amount: int = 0
var mouse_inside := false

func _ready():
	set_as_top_level(false)
	
	# 👑 KÉNYSZERÍTETT EGÉR BEÁLLÍTÁSOK FIXE
	input_pickable = true
	# JAVÍTÁS: Nem kell a hibás MouseFilter sor, az input_pickable kezeli az Area2D egerét!
	
	# 👑 SHADER DUPLIKÁLÁS FIXEN
	if sprite and sprite.material:
		sprite.material = sprite.material.duplicate()
	
	# Biztonságos jelzés összekötés (ha az Editorban elfelejtetted volna)
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	
	y_sort_enabled = true
	player = get_tree().get_first_node_in_group("player")
	print("[GOLD_DROP_DEBUG] Új aranyhalom aktív! Értéke: ", gold_amount, " | Pozíciója: ", global_position)
	
	if sprite:
		sprite.y_sort_enabled = true
		sprite.play("drop_anim")
		set_aura_active(false)

# 🟡 EGÉR RÁKERÜL
func _on_mouse_entered() -> void:
	print("[GOLD_DROP_DEBUG] >>> EGÉR RÁMENT AZ ARANYRA! Aura indítása... <<<")
	mouse_inside = true
	set_aura_active(true)

# ⚫ EGÉR LEKERÜL
func _on_mouse_exited() -> void:
	print("[GOLD_DROP_DEBUG] Egér lekerült az aranyról.")
	mouse_inside = false
	set_aura_active(false)

# 👑 SHADER VEZÉRLÉS
func set_aura_active(active: bool) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("is_active", active)
		sprite.material.set_shader_parameter("aura_width", 1.5)

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
		
		# Ha a hover jelzett, VAGY nagyon közel van az egér, felvehető
		if mouse_inside or distance_to_mouse <= 30.0:
			if is_player_in_radius():
				get_viewport().set_input_as_handled()
				pickup()

func is_player_in_radius() -> bool:
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= 180.0: 
			return true
	return false

func pickup():
	if picked:
		return

	var inventory = get_tree().get_first_node_in_group("inventory_group") as Inventory
	if inventory:
		var total_potential_gold = GlobalData.total_inventory_gold + gold_amount
		if total_potential_gold > 100:
			print("[GOLD_DROP] FELVÉTEL BLOKKOLVA: A táska arany limitje betelt!")
			return

		GlobalData.total_inventory_gold = total_potential_gold

		var existing_gold_slot = null
		for item in inventory.get_items():
			var item_image_path = item.get_property("image", "")
			if "arany" in str(item_image_path).to_lower() or "gold" in str(item_image_path).to_lower():
				existing_gold_slot = item
				break

		if existing_gold_slot != null:
			existing_gold_slot.set_property("name", "Arany (" + str(GlobalData.total_inventory_gold) + "g)")
		else:
			var uj_arany_item = inventory.create_and_add_item("gold_coin")
			if uj_arany_item:
				uj_arany_item.set_property("name", "Arany (" + str(GlobalData.total_inventory_gold) + "g)")
			else:
				GlobalData.total_inventory_gold -= gold_amount
				return 

		picked = true
		set_aura_active(false)
		await get_tree().create_timer(0.1).timeout
		queue_free()
