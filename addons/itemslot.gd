extends CanvasLayer

# 👑 ELLENŐRIZD a saját node-jaid pontos nevét a jelenetfában!
@onready var ctrl_grid = $InventoryGUI/CtrlInventoryGrid      # A 4x10-es rács UI node-ja
@onready var weapon_slot_logic = $InventoryGUI/WeaponSlot       # A logikai ItemSlot node-od
@onready var weapon_slot_ui = $InventoryGUI/FegyverSlotUI       # A vizuális CtrlItemSlot node-od

# Ebbe mentjük el az éppen kézben lévő fegyver ID-ját a karakter frissítéséhez
var last_checked_weapon_id: String = ""

func _ready() -> void:
	print("[BUTTON_EQUIP_DEBUG] HUD elindult. Karakter fegyver-figyelője aktív.")
	pass

# FOLYAMATOS INTELLIGENS FIGYELÉS: Ez élőben nézi a slotot, és azonnal átöltözteti a karaktert!
func _process(_delta: float) -> void:
	if weapon_slot_logic == null:
		return
		
	var current_item = weapon_slot_logic.get_item()
	var current_weapon_id := ""
	
	# 👑 FIX JAVÍTÁS: Nem közvetlen tulajdonságként érjük el, hanem biztonságos get() lekérdezéssel!
	if current_item != null:
		if current_item.get("prototype_id") != null:
			current_weapon_id = current_item.prototype_id
		else:
			current_weapon_id = current_item.get_property("prototype_id", "")
		
	# Csak akkor szólunk a hősnek, ha TÉNYLEG megváltozott a slot tartalma
	if current_weapon_id != last_checked_weapon_id:
		last_checked_weapon_id = current_weapon_id
		
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("update_equipped_weapon"):
			if current_weapon_id != "":
				print("[BUTTON_EQUIP_DEBUG] HUD ÉSZLELÉS: Új fegyver a slotban! Karakter frissítése: ", current_weapon_id)
				player.update_equipped_weapon(current_weapon_id)
			else:
				print("[BUTTON_EQUIP_DEBUG] HUD ÉSZLELÉS: A fegyverhely kiürült! Visszaállás alapállapotba.")
				player.update_equipped_weapon("")
