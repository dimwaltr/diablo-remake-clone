extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var outline: Sprite2D = $Sprite2D
@onready var click_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var click2_sound: AudioStreamPlayer2D = $arany
@onready var click3_sound: AudioStreamPlayer2D = $fegyversongdrop

# === 🛠️ KIEGÉSZÍTÉS: INDULÓ LOOT BEÁLLÍTÁSOK ===
@export var gold_scene: PackedScene
@export var ground_item_scene: PackedScene  # Ide kell behúznod a ground_item.tscn-t az Inspectorban!

# === 🆕 ÚJ: TÁVOLSÁG KORLÁTOZÁS ===
@export var max_interaction_distance := 100.0 # Pixelben mért maximális távolság a nyitáshoz

# A JSON prototípus fájl elérési útja
@export_file("*.json") var item_db_path: String = "res://inventory/item_prototypes.json"
# ===============================================

var opened := false

func _ready():
	outline.visible = false
	sprite.play("closed")
	print("[CHEST_DEBUG] Láda beolvasva. Inspector pozíciója: ", position, " | Globális pozíciója: ", global_position)

# 🟡 HOVER BE
func _on_mouse_entered():
	if not opened:
		outline.visible = true

# ⚫ HOVER KI
func _on_mouse_exited():
	outline.visible = false

# 🖱️ KATTINTÁS
func _input_event(_viewport, event, _shape_idx):
	if opened:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_node_or_null("/root/Main/World/Player")
		if player == null:
			player = get_node_or_null("/root/Main/World/player") # Biztonsági ellenőrzés kisbetűre
			
		if player:
			var distance = sprite.global_position.distance_to(player.global_position)
			
			if distance > max_interaction_distance:
				print("[CHEST_DEBUG] Túl messze vagy a ládától! Távolság: ", distance)
				return # Ha túl messze van, megszakítjuk a függvényt, NEM nyílik ki!
				
		if click_sound:
			click_sound.play()
		open_chest()

# 📦 CHEST OPEN (csak anim indul!)
func open_chest():
	if opened:
		return

	opened = true
	sprite.play("open")
	outline.visible = true

# 🎞️ ANIM VÉGE → ITT SPAWNOLUNK GOLDOT ÉS FEGYVERT
func _on_animated_sprite_2d_animation_finished():
	if sprite.animation == "open":
		spawn_gold()
		spawn_json_weapon() # <--- ÚJ: Fegyver dobása az animáció végén
		outline.visible = false

# 💰 GOLD SPAWN A LÁDA PONTOS HELYÉRE
func spawn_gold():
	if gold_scene == null:
		print("[CHEST_DEBUG] HIBA: Nincs berakva a gold_scene a láda Inspectorába!")
		return

	var gold = gold_scene.instantiate()
	
	if "gold_amount" in gold:
		gold.gold_amount = randi_range(15, 45)
	
	get_parent().add_child(gold)
	
	# Az aranyat a láda közepétől kicsit JOBBRA és LEFELE dobjuk
	var gold_offset = Vector2(24.0, 12.0)
	gold.global_position = sprite.global_position + gold_offset

	if click2_sound:
		click2_sound.play()
	if click3_sound:
		click3_sound.play()
		
	print("[CHEST_DEBUG] >>> FIX SIKER! <<<")
	print("[CHEST_DEBUG] Aranyhalom végleges helye: ", gold.global_position)

# ⚔️ ÚJ FEGYVER DROP: KISORSOLÁS ÉS ÁTADÁS A TE GROUND_ITEM LOGIKÁDNAK
func spawn_json_weapon():
	if ground_item_scene == null:
		print("[CHEST_DEBUG] HIBA: Nincs berakva a ground_item_scene a láda Inspectorába!")
		return

	if not FileAccess.file_exists(item_db_path):
		print("[CHEST_DEBUG] HIBA: Nem található a JSON fájl: ", item_db_path)
		return
		
	var file = FileAccess.open(item_db_path, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("[CHEST_DEBUG] HIBA: Nem sikerült feldolgozni a JSON prototípusokat!")
		return
		
	var item_database = json.get_data()

	var allowed_weapons = ["sword01", "sword02"]
	var random_weapon_id = allowed_weapons.pick_random()
	
	if not random_weapon_id in item_database:
		print("[CHEST_DEBUG] HIBA: A kisorsolt fegyver ID nincs a JSON fájlban: ", random_weapon_id)
		return

	var world_item = ground_item_scene.instantiate()
	
	# 👑 ATOMBIZTOS JAVÍTÁS:
	# 1. Kiszámoljuk az alap eltolást (Balra és lefelé a ládától)
	var base_weapon_offset = Vector2(-24.0, 12.0)
	
	# 2. Hozzáadjuk a fegyver saját belső szórását (pl: max 8 pixel X és 4 pixel Y irányban)
	# Így a fegyver nem pontosan ugyanoda esik minden ládanyitásnál, hanem véletlenszerűen pattan el!
	var random_scatter = Vector2(randf_range(-8, 8), randf_range(-4, 4))
	
	# 3. Még az add_child ELŐTT rárakjuk a fegyverre a végleges pozíciót
	world_item.global_position = sprite.global_position + base_weapon_offset + random_scatter
	
	# 4. Átadjuk az ID-t a fegyvernek
	if world_item.has_method("setup_dropped_item"):
		world_item.setup_dropped_item(random_weapon_id)
		
	# 5. LEGUTOLSÓ LÉPÉSKÉNT adjuk hozzá a jelenetfához, így a _ready() már a tökéletes helyen indul el!
	get_parent().add_child(world_item)
		
	print("[CHEST_DEBUG] Fegyver sikeresen kidobva. ID: ", random_weapon_id, " | Szórt helye: ", world_item.global_position)
