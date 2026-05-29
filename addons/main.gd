extends Node2D

@onready var inventory: Inventory = $Inventory
@onready var inventory_ui: CanvasLayer = $CanvasLayer
@onready var ctrl_grid: CtrlInventoryGrid = $CanvasLayer/InventoryGUI/CtrlInventoryGrid
@onready var gold_info_label: Label = $CanvasLayer/GoldInfoLabel
@onready var sfx_weapon_drop: AudioStreamPlayer = $fegyver_kidobas_hang
var current_selected_ui_item: TextureRect = null # Ebbe mentjük el a kijelölt tárgy képét


var player = null

const fegyver_scene = preload("res://ground_item.tscn")
const arany_drop_scene = preload("res://gold_drop.tscn") 

const JSON_PROTOSET_FILE = preload("res://inventory/item_prototypes.json") 

# === A TE EGYEDI MENTÉSI ÚTVONALAD ÉS A FÁJL NEVE ===
const SAVE_FOLDER_PATH = "C:/Users/Huncut/Documents/diablo-clone/save/"
const SAVE_FILE_PATH = "C:/Users/Huncut/Documents/diablo-clone/save/inventory_save.json"

func _ready() -> void:
	inventory_ui.visible = false
	if inventory and inventory.get_prototree():
		inventory.get_prototree().deserialize(JSON_PROTOSET_FILE)
		print("[MAIN_DEBUG] GLoot adatbázis sikeresen szinkronizálva.")
	
	# === KORÁBBI MENTÉS BETÖTLÉSE INDULÁSKOR ===
	load_inventory_from_file()
	
	await get_tree().process_frame
	print("[MAIN_DEBUG] Játék elindult, tiszta ARANY drop rendszer kész.")
	
	if gold_info_label:
		gold_info_label.visible = false
		
	setup_gold_hover_info()
	player = get_tree().get_first_node_in_group("player")
	
	# AUTOMATIKUS MENTÉS ÖSSZEKÖTÉSE (felvételkor és kidobáskor is lefut)
	if inventory:
		inventory.item_added.connect(_on_inventory_changed)
		inventory.item_removed.connect(_on_inventory_changed)
		
	# 🆕 ÚJ: AUTOMATIKUS MENTÉS PONTOSZTÁSKOR ÉS STAT VÁLTOZÁSKOR
	GlobalData.stat_changed.connect(_on_stat_changed_save)
	
	#=== Na itt lehet tesztelni az xp-t ===
	#GlobalData.gain_xp(600)

func _on_inventory_changed(_item: InventoryItem) -> void:
	save_inventory_to_file()

# 🆕 ÚJ: Statisztika változásakor automatikusan mentünk
func _on_stat_changed_save() -> void:
	save_inventory_to_file()

# === 🛠️ KÜLÖNVÁLASZTOTT, BŐVÍTETT FÁJLMENTÉS: TULAJDONSÁGOK IS KIMENTÉSRE KERÜLNEK ===
func save_inventory_to_file() -> void:
	if inventory == null:
		return
		
	if not DirAccess.dir_exists_absolute(SAVE_FOLDER_PATH):
		DirAccess.make_dir_recursive_absolute(SAVE_FOLDER_PATH)
		print("[SAVE_SYSTEM] A megadott save mappa nem létezett, sikeresen létrehozva!")
		
	# Létrehozunk egy saját mentési csomagot (Dictionary)
	var full_save_data = {
		"inventory_contents": inventory.serialize(),            # Elmentjük a GLoot rácsot
		"saved_gold_amount": GlobalData.total_inventory_gold,   # Elmentjük a táska aranyát
		
		# 🆕 ÚJ: DIABLO TULAJDONSÁGOK ÉS SZINTEK MENTÉSE
		"current_level": GlobalData.current_level,
		"current_xp": GlobalData.current_xp,
		"available_stat_points": GlobalData.available_stat_points,
		
		"stat_strength": GlobalData.stat_strength,
		"stat_magic": GlobalData.stat_magic,
		"stat_dexterity": GlobalData.stat_dexterity,
		"stat_vitality": GlobalData.stat_vitality,
		
		"current_hp": GlobalData.current_hp,
		"max_hp": GlobalData.max_hp,
		"current_mana": GlobalData.current_mana,
		"max_mana": GlobalData.max_mana
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(full_save_data)
		file.store_string(json_string)
		file.close()
		print("[SAVE_SYSTEM] Táska, Arany és KARAKTER STATOK sikeresen elmentve!")
	else:
		print("[SAVE_SYSTEM] HIBA: Nem sikerült írni a megadott mappába!")

func load_inventory_from_file() -> void:
	if inventory == null:
		return
		
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SAVE_SYSTEM] Nem található mentés, tiszta lappal indul a játék.")
		return
		
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var full_save_data = json.get_data()
			
			# Visszatöltjük a GLoot rácsot a helyére
			if "inventory_contents" in full_save_data:
				inventory.deserialize(full_save_data["inventory_contents"])
				
			# Visszatöltjük a kimentett aranyat
			if "saved_gold_amount" in full_save_data:
				GlobalData.total_inventory_gold = int(full_save_data["saved_gold_amount"])
				
			# 🆕 ÚJ: DIABLO TULAJDONSÁGOK ÉS SZINTEK VISSZATÖLTÉSE (Bolyongás elleni védelemmel)
			if "current_level" in full_save_data: GlobalData.current_level = int(full_save_data["current_level"])
			if "current_xp" in full_save_data: GlobalData.current_xp = int(full_save_data["current_xp"])
			if "available_stat_points" in full_save_data: GlobalData.available_stat_points = int(full_save_data["available_stat_points"])
			
			if "stat_strength" in full_save_data: GlobalData.stat_strength = int(full_save_data["stat_strength"])
			if "stat_magic" in full_save_data: GlobalData.stat_magic = int(full_save_data["stat_magic"])
			if "stat_dexterity" in full_save_data: GlobalData.stat_dexterity = int(full_save_data["stat_dexterity"])
			if "stat_vitality" in full_save_data: GlobalData.stat_vitality = int(full_save_data["stat_vitality"])
			
			if "max_hp" in full_save_data: GlobalData.max_hp = int(full_save_data["max_hp"])
			if "current_hp" in full_save_data: GlobalData.current_hp = int(full_save_data["current_hp"])
			if "max_mana" in full_save_data: GlobalData.max_mana = int(full_save_data["max_mana"])
			if "current_mana" in full_save_data: GlobalData.current_mana = int(full_save_data["current_mana"])
			
			# Értesítjük a HUD-ot, hogy rajzolja újra a gömböket és pontokat a betöltött adatokkal
			GlobalData.stat_changed.emit()
				
			print("[SAVE_SYSTEM] Táska, Arany és karakter statisztikák sikeresen betöltve!")
		else:
			print("[SAVE_SYSTEM] HIBA: A mentési JSON fájl sérült!")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		toggle_inventory_window()

	# 👑 BIZTONSÁGOS RESTART: Csak akkor reagál az R betűre, ha a játékos halott!
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		# Megkeressük a játékost a csoport alapján
		var p = get_tree().get_first_node_in_group("player")
		
		# Szigorúan ellenőrizzük, hogy a hős valóban meghalt-e
		if p and p.get("is_dead") == true:
			print("[RESTART_SYSTEM] A játékos halott, az 'R' betű megnyomva! Pálya újraindítása...")
			
			# 🩸 KÖTELEZŐ MEGOLDÁS: Csordultig feltöltjük az életet és manát a GlobalData-ban!
			# Ez felülbírálja a nullás értéket, így az újratöltéskor a HUD gömbjeid azonnal teli állapotban indulnak.
			GlobalData.current_hp = GlobalData.max_hp
			GlobalData.current_mana = GlobalData.max_mana
			
			# 🧠 BELSŐ KAPCSOLÓ RESET: Biztonság kedvéért a játékos node-on is lekapcsoljuk a halál-tiltást,
			# hogy az újratöltés utáni legelső képkockában a mozgási és beviteli kódok azonnal működjenek.
			p.set("is_dead", false)
			
			# Értesítjük a HUD-ot a változásról a biztonság kedvéért
			GlobalData.stat_changed.emit()
			
			# Újraindítjuk a jelenetet (a statok és tárgyak megmaradnak a mentésből!)
			get_tree().reload_current_scene()
		else:
			print("[RESTART_SYSTEM] Elutasítva: Nem indíthatod újra a pályát, amíg életben vagy!")



# 👑 ÚJ: Ezt hívja meg az inventory.gd kattintáskor, hogy a Main tudja, mi van kijelölve
func set_current_selection(ui_item: TextureRect) -> void:
	current_selected_ui_item = ui_item
	if ui_item and ui_item.has_meta("item_data"):
		var item = ui_item.get_meta("item_data")
		var item_name = item.get("id", item.get("name", "Ismeretlen"))
		print("[MAIN_DEBUG] A Main node sikeresen regisztrálta a kijelölést: ", item_name)


func toggle_inventory_window() -> void:
	inventory_ui.visible = !inventory_ui.visible
	if !inventory_ui.visible and gold_info_label:
		gold_info_label.visible = false

func _on_inventory_button_pressed() -> void:
	toggle_inventory_window()

func _on_teszt_gomb_pressed() -> void:
	print("[MAIN_DEBUG] >>> KIDOBÁS INDUL!")
	if inventory == null or ctrl_grid == null:
		return
		
	var selected_items = ctrl_grid.get_selected_inventory_items()
	var target_item = null
	
	if selected_items.size() > 0:
		target_item = selected_items[0]
		print("[MAIN_DEBUG] Sikeresen azonosítva a kijelölt tárgy a rácsról!")
	else:
		var items = inventory.get_items()
		if items.size() > 0:
			target_item = items[0]
			print("[MAIN_DEBUG] Nincs kijelölt tárgy, biztonsági mentsvárként az első elemet dobjuk ki.")

	if target_item != null:
		var item_image_path = target_item.get_property("image", "")
		var is_gold_coin: bool = false
		
		var real_item_id = ""
		if target_item.get("prototype_id") != null:
			real_item_id = target_item.prototype_id
		else:
			var img_path_str = str(item_image_path).to_lower()
			if "sword01" in img_path_str:
				real_item_id = "sword01"
			elif "sword02" in img_path_str:
				real_item_id = "sword02"
		
		if "arany" in str(item_image_path).to_lower() or "gold" in str(item_image_path).to_lower():
			is_gold_coin = true
			real_item_id = "gold_coin"
			
		print("[MAIN_DEBUG] Tárgy sikeresen azonosítva! ID: ", real_item_id)
		
		var drop_clone = null
		
		if is_gold_coin:
			drop_clone = arany_drop_scene.instantiate()
			print("[MAIN_DEBUG] Kiválasztva a tiszta gold_drop jelenet.")
			
			if "gold_amount" in drop_clone:
				drop_clone.gold_amount = GlobalData.total_inventory_gold
				
			GlobalData.total_inventory_gold = 0
			save_inventory_to_file()
		else:
			drop_clone = fegyver_scene.instantiate()
			if drop_clone.has_method("setup_dropped_item"):
				drop_clone.setup_dropped_item(str(real_item_id))
		
			if sfx_weapon_drop:
				sfx_weapon_drop.pitch_scale = randf_range(0.9, 1.1)
				sfx_weapon_drop.volume_db = -8.0 
				sfx_weapon_drop.play()
		
		if player != null and drop_clone != null:
			drop_clone.position = Vector2.ZERO
			player.get_parent().add_child(drop_clone) 
			drop_clone.global_position = player.global_position 
		
		if gold_info_label:
			gold_info_label.visible = false
			
		inventory.remove_item(target_item)
		print("[MAIN_DEBUG] >>> SIKER! A tárgy kikerült az inventory-ból! <<<")
	else:
		print("[MAIN_DEBUG] A hátizsák teljesen üres, nincs mit kidobni.")

func setup_gold_hover_info() -> void:
	if ctrl_grid:
		ctrl_grid.item_mouse_entered.connect(_on_grid_item_mouse_entered)
		ctrl_grid.item_mouse_exited.connect(_on_grid_item_mouse_exited)

func _on_grid_item_mouse_entered(item: InventoryItem) -> void:
	if item:
		var item_image_path = item.get_property("image", "")
		if "arany" in str(item_image_path).to_lower() or "gold" in str(item_image_path).to_lower():
			if gold_info_label:
				gold_info_label.text = "A kupac értéke: " + str(GlobalData.total_inventory_gold) + " Arany"
				gold_info_label.visible = true
			item.set_property("name", "Arany (" + str(GlobalData.total_inventory_gold) + "g)")

func _on_grid_item_mouse_exited(item: InventoryItem) -> void:
	if item:
		var item_image_path = item.get_property("image", "")
		if "arany" in str(item_image_path).to_lower() or "gold" in str(item_image_path).to_lower():
			if gold_info_label:
				gold_info_label.visible = false
			item.set_property("name", "Arany")


func _on_fegyver_gomb_pressed() -> void:
	print("\n[MAIN_DEBUG] ========= FELSZERELÉS GOMB MEGNYOMVA! =========")
	
	var weapon_slot_logic = get_node_or_null("CanvasLayer/InventoryGUI/WeaponSlot")
	
	if ctrl_grid == null:
		print("[MAIN_DEBUG] LEÁLLÍTÁS: A rács (ctrl_grid) nem található!")
		return
	if weapon_slot_logic == null:
		print("[MAIN_DEBUG] LEÁLLÍTÁS: A logikai WeaponSlot nem található a megadott útvonalon!")
		return

	# 1. FELVÉTEL LOGIKA: Lekérjük a kijelölt fegyvert pontosan a kidobás mintájára
	var selected_items = ctrl_grid.get_selected_inventory_items()
	var target_item = null
	
	if selected_items.size() > 0:
		target_item = selected_items[0]
		print("[MAIN_DEBUG] Sikeresen azonosítva a kijelölt fegyver a rácsról!")

	# 2. HA VAN KIJELÖLT TÁRGY -> GLoot ÁTHELYEZÉS
	if target_item != null:
		var real_item_id = ""
		if target_item.get("prototype_id") != null:
			real_item_id = target_item.prototype_id
		else:
			var item_image_path = target_item.get_property("image", "")
			var img_path_str = str(item_image_path).to_lower()
			if "sword01" in img_path_str:
				real_item_id = "sword01"
			elif "sword02" in img_path_str:
				real_item_id = "sword02"
				
		print("[MAIN_DEBUG] Tárgy sikeresen azonosítva! ID: ", real_item_id)
		
		if "sword" in real_item_id.to_lower() or "kard" in real_item_id.to_lower():
			
			# Ha már volt fegyver a slotban, azt tisztán visszatesszük a táskába
			var regi_fegyver = weapon_slot_logic.get_item()
			if regi_fegyver != null:
				print("[MAIN_DEBUG] A slot foglalt! Régi fegyver kivétele...")
				weapon_slot_logic.clear()
				if inventory:
					inventory.add_item(regi_fegyver)
			
			print("[MAIN_DEBUG] >>> GLoot ÁTHELYEZÉS INDUL! <<<")
			
			# 👑 🛠️ ATOMBIZTOS MEGOLDÁS: 
			# Nem .remove_item()-et használunk, mert az megsemmisíti a tárgyat!
			# A .equip() függvény a GLoot-ban beépítetten áthelyezi a tárgyat az inventoryból a slotba, 
			# de ha a rács nem frissül, kézzel kell kényszerítenünk a leválasztást a táska rácsáról.
			
			if weapon_slot_logic.equip(target_item):
				print("[MAIN_DEBUG] 1. Lépés: A slot sikeresen befogadta a tárgyat.")
				
				# 👑 KÉNYSZERÍTETT TÖRLÉS A 4x10-ES RÁCSBÓL:
				# Ha a tárgy még vizuálisan a rácsban maradt, ezzel a paranccsal fellazítjuk és töröljük a pozícióját a táskából
				if inventory and inventory.has_method("remove_item"):
					# Biztonsági ellenőrzés: ha az equip már áttette, de a rács még mutatja, 
					# a GLoot-ban az inventory-ból való manuális leválasztás vagy az újrarajzolás segít:
					if "grid" in inventory:
						for r in range(inventory.ROWS):
							for c in range(inventory.COLS):
								if inventory.grid[r][c] != null and inventory.grid[r][c]["item"] == target_item:
									inventory.grid[r][c] = null # Kitisztítjuk a cellát a saját rendszeredben!
				
				# 👑 C: KÉNYSZERÍTETT FRISSÍTÉS ÉS ÚJRARAJZOLÁS
				if inventory and inventory.has_signal("inventory_updated"):
					inventory.inventory_updated.emit()
				elif inventory and "inventory_updated" in inventory:
					inventory.inventory_updated.emit()
				
				print("[MAIN_DEBUG] 2. Lépés: >>> SIKER: A fegyver átugrott a slotba, és eltűnt a táskából! <<<")
				
				if player == null:
					player = get_tree().get_first_node_in_group("player")
				if player and player.has_method("update_equipped_weapon"):
					player.update_equipped_weapon(real_item_id)
				
				save_inventory_to_file()
			else:
				print("[MAIN_DEBUG] HIBA: A logikai slot (.equip) elutasította az áthelyezést!")
		else:
			print("[MAIN_DEBUG] Elutasítva: Ez a kijelölt tárgy nem fegyver!")
		return

	# 3. LEVÉTEL LOGIKA: Ha üres kézzel kattintasz a gombra, leveszi a bent lévő fegyvert
	var jelenlegi_fegyver = weapon_slot_logic.get_item()
	if jelenlegi_fegyver != null:
		print("[MAIN_DEBUG] Nincs kijelölve semmi. Kísérlet a felszerelt fegyver levételére...")
		weapon_slot_logic.clear()
		
		if inventory and inventory.add_item(jelenlegi_fegyver):
			print("[MAIN_DEBUG] >>> LEVÉTEL SIKER: A fegyver visszakerült a táskába! <<<")
			if player and player.has_method("update_equipped_weapon"):
				player.update_equipped_weapon("")
			save_inventory_to_file()
		else:
			print("[MAIN_DEBUG] >>> LEVÉTEL HIBA: Nem sikerült visszatenni a táskába! <<<")
	else:
		print("[MAIN_DEBUG] Nincs semmi kijelölve, és a fegyverhely is üres.")
		
	print("[MAIN_DEBUG] =============================================\n")
