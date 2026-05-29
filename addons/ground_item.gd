extends Area2D
class_name GroundItem

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var player = null
var picked := false
var mouse_inside := false

# Ebbe menti el a kód, hogy EZ a konkrét földi tárgy kicsoda
var item_id: String = ""

# 👑 ÚJ: Ide mentjük el a láda által kért pozíciót, ha ládából esik ki
var spawn_at_position: Vector2 = Vector2.ZERO

func _ready():
	print("[GROUND_DEBUG] Földi tárgy Area2D node _ready() elindult.")
	input_pickable = true
	
	# Ha kaptunk egy konkrét pozíciót a ládától, akkor oda ugrunk a szórás előtt
	if spawn_at_position != Vector2.ZERO:
		global_position = spawn_at_position
	
	# 👑 A pozíció beállítása UTÁN kapcsoljuk be a top_level-t, így nem csúszik el!
	set_as_top_level(true)

	# 👑 JAVÍTVA: Az egér mozgásra be- és kikapcsoljuk a fehér aurát
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)

	# Véletlenszerű szórás a megadott bázispont körül
	global_position += Vector2(
		randf_range(-8, 8),
		randf_range(-4, 4)
	)

	y_sort_enabled = true
	player = get_tree().get_first_node_in_group("player")
	
	if sprite:
		sprite.y_sort_enabled = true
		sprite.speed_scale = 3.5
		sprite.play("kard_ground")
		
		# Shader egyedivé tétele példányosításkor
		if sprite.material:
			sprite.material = sprite.material.duplicate()
		set_aura_active(false)

func setup_dropped_item(real_id: String) -> void:
	item_id = real_id
	print("[GROUND_DEBUG] >>> A KARD ANIMÁCIÓJA A FÖLDÖN MEGJELENT! Tárgy ID: ", item_id, " | Helye: ", global_position)

# 🟡 EGÉR RÁKERÜL
func _on_mouse_entered() -> void:
	mouse_inside = true
	set_aura_active(true)

# ⚫ EGÉR LEKERÜL
func _on_mouse_exited() -> void:
	mouse_inside = false
	set_aura_active(false)

# 👑 SEGÉDFÜGGVÉNY AZ AURA SHADER VEZÉRLÉSÉHEZ
func set_aura_active(active: bool) -> void:
	if sprite and sprite.material:
		sprite.material.set_shader_parameter("is_active", active)

# 🖱️ KATTINTÁS AZ AREA2D-N KÖZVETLENÜL
func _input_event(viewport, event, shape_idx):
	if picked:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_player_in_radius():
			get_viewport().set_input_as_handled()
			pickup()
		else:
			print("[GROUND_DEBUG] SIKERTELEN KATTINTÁS: A játékos túl messze van a fegyvertől!")

# GLOBÁLIS EGÉRFIGYELÉS A CANVASLAYER / UI BLOKKOLÁS MEGKERÜLÉSÉRE
func _unhandled_input(event: InputEvent) -> void:
	if picked:
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if mouse_inside:
			if is_player_in_radius():
				print("[GROUND_DEBUG] >>> SIKERES KATTINTÁS ÉSZLELVE! pickup() indul.")
				get_viewport().set_input_as_handled()
				pickup()
			else:
				print("[GROUND_DEBUG] Kattintottál a fegyverre, de a játékos túl messze van a felvételhez!")

# === SEGÉDFÜGGVÉNY A TÁVOLSÁG ELLENŐRZÉSÉHEZ ===
func is_player_in_radius() -> bool:
	if player != null:
		var distance_to_player = global_position.distance_to(player.global_position)
		if distance_to_player <= 80.0:
			return true
	return false

# ⚔️ FELVÉTELI LOGIKA
func pickup():
	if picked or item_id == "":
		return

	var inventory = get_tree().get_first_node_in_group("inventory_group") as Inventory
	
	if inventory:
		print("[GROUND_DEBUG] Megpróbáljuk visszatennen a fegyvert a GLoot hátizsákba... ID: ", item_id)
		var uj_item = inventory.create_and_add_item(item_id)
		
		if uj_item:
			picked = true
			set_aura_active(false)
			await get_tree().create_timer(0.1).timeout
			queue_free()
		else:
			print("[GROUND_DEBUG] SIKERTELEN FELVÉTEL: Nincs elég szabad hely a hátizsák rácsán!")
			var main_node = get_node_or_null("/root/Main")
			if main_node:
				var error_sfx = main_node.get_node_or_null("ErrorSound") as AudioStreamPlayer
				if error_sfx:
					error_sfx.play()
