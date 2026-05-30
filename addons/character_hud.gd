extends CanvasLayer

@onready var panel_node = $Panel

# Szintezés és Szabad pontok mezői
@onready var level_label = $Panel/LevelLabel
@onready var xp_label = $Panel/XpLabel
@onready var next_level_xp_label = $Panel/NextLevelXpLabel
@onready var points_label = $Panel/PointsLabel

# Alap tulajdonságok és gombok mezői
@onready var str_label = $Panel/StrLabel
@onready var str_button = $Panel/StrButton

@onready var mag_label = $Panel/MagLabel
@onready var mag_button = $Panel/MagButton

@onready var dex_label = $Panel/DexLabel
@onready var dex_button = $Panel/DexButton

@onready var vit_label = $Panel/VitLabel
@onready var vit_button = $Panel/VitButton

# Különválasztott élet és mana mezők (a karakterlapon)
@onready var current_hp_label = $Panel/CurrentHPLabel
@onready var max_hp_label = $Panel/MaxHPLabel
@onready var current_mana_label = $Panel/CurrentManaLabel
@onready var max_mana_label = $Panel/MaxManaLabel

@onready var gold_label = $Panel/GoldLabel

# Harci statisztikák mezői
@onready var defense_label = $Panel/DefenseLabel
@onready var hit_chance_label = $Panel/HitChanceLabel
@onready var damage_label = $Panel/DamageLabel

# === 🛠️ ABSZOLÚT ÚTVONALAK A HUDLAYER-HEZ ===
# Élet és Mana gömbök (TextureProgressBar)
@onready var hp_progress_bar = get_node_or_null("/root/Main/HudLayer/HpProgressBar")
@onready var mana_progress_bar = get_node_or_null("/root/Main/HudLayer/ManaProgressBar")

# A gömbökön megjelenő azonnali szövegek (Label)
@onready var hp_text_label = get_node_or_null("/root/Main/HudLayer/HpTextLabel")
@onready var mana_text_label = get_node_or_null("/root/Main/HudLayer/ManaTextLabel")

# Tesztgombok
@onready var sebzodes_gomb = get_node_or_null("/root/Main/HudLayer/SebzodesGomb")
@onready var gyogyulas_gomb = get_node_or_null("/root/Main/HudLayer/GyogyulasGomb")
@onready var manatolto_gomb = get_node_or_null("/root/Main/HudLayer/Manatolto")
@onready var manafogyo_gomb = get_node_or_null("/root/Main/HudLayer/Manafogyo")


func _ready():
	# Gombok összekötése a karakterlapon
	str_button.pressed.connect(_on_stat_button_pressed.bind("strength"))
	mag_button.pressed.connect(_on_stat_button_pressed.bind("magic"))
	dex_button.pressed.connect(_on_stat_button_pressed.bind("dexterity"))
	vit_button.pressed.connect(_on_stat_button_pressed.bind("vitality"))
	
	# Globális változások követése
	GlobalData.stat_changed.connect(update_stat_ui)
	
	# Szignál bekötések közvetlenül a progress barokra
	if is_instance_valid(hp_progress_bar):
		hp_progress_bar.mouse_entered.connect(_on_hp_mouse_entered)
		hp_progress_bar.mouse_exited.connect(_on_hp_mouse_exited)
		hp_progress_bar.mouse_filter = Control.MOUSE_FILTER_STOP

	if is_instance_valid(mana_progress_bar):
		mana_progress_bar.mouse_entered.connect(_on_mana_mouse_entered)
		mana_progress_bar.mouse_exited.connect(_on_mana_mouse_exited)
		mana_progress_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Tesztgombok összekötése
	if is_instance_valid(sebzodes_gomb):
		sebzodes_gomb.pressed.connect(_on_sebzodes_gomb_pressed)
	if is_instance_valid(gyogyulas_gomb):
		gyogyulas_gomb.pressed.connect(_on_gyogyulas_gomb_pressed)
	if is_instance_valid(manatolto_gomb):
		manatolto_gomb.pressed.connect(_on_manatolto_gomb_pressed)
	if is_instance_valid(manafogyo_gomb):
		manafogyo_gomb.pressed.connect(_on_manafogyo_gomb_pressed)
	
	# Kezdő láthatósági állapotok beállítása
	if is_instance_valid(hp_progress_bar): hp_progress_bar.visible = true
	if is_instance_valid(mana_progress_bar): mana_progress_bar.visible = true
	if is_instance_valid(panel_node): panel_node.visible = false 
	if is_instance_valid(hp_text_label): hp_text_label.visible = false
	if is_instance_valid(mana_text_label): mana_text_label.visible = false

	update_stat_ui()

func _input(event):
	# A 'C' gomb nyitja/csukja a karakterlapot
	if event.is_action_pressed("character_menu") or (event is InputEventKey and event.pressed and event.keycode == KEY_C):
		if is_instance_valid(panel_node):
			panel_node.visible = !panel_node.visible
			if panel_node.visible:
				update_stat_ui()

# === HOVER FUNKCIÓK ===
func _on_hp_mouse_entered():
	print("EGÉR A HP GÖMBÖN!")
	if is_instance_valid(hp_text_label): hp_text_label.visible = true

func _on_hp_mouse_exited():
	print("EGÉR ELMENT A HP GÖMBRŐL!")
	if is_instance_valid(hp_text_label): hp_text_label.visible = false

func _on_mana_mouse_entered():
	print("EGÉR A MANA GÖMBÖN!")
	if is_instance_valid(mana_text_label): mana_text_label.visible = true

func _on_mana_mouse_exited():
	print("EGÉR ELMENT A MANA GÖMBRŐL!")
	if is_instance_valid(mana_text_label): mana_text_label.visible = false

func _on_stat_button_pressed(stat_name: String) -> void:
	if GlobalData.available_stat_points > 0:
		GlobalData.available_stat_points -= 1
		
		match stat_name:
			"strength":
				GlobalData.stat_strength += 1
			"magic":
				GlobalData.stat_magic += 1
				GlobalData.max_mana += 2
				GlobalData.current_mana += 2
			"dexterity":
				GlobalData.stat_dexterity += 1
			"vitality":
				GlobalData.stat_vitality += 1
				GlobalData.max_hp += 2
				GlobalData.current_hp += 2
				
		update_stat_ui()

# === JAVÍTOTT TESZTGOMB FUNKCIÓK EMIT-TEL ===
func _on_sebzodes_gomb_pressed() -> void:
	GlobalData.current_hp -= 5
	if GlobalData.current_hp < 0:
		GlobalData.current_hp = 0
	GlobalData.stat_changed.emit()

func _on_gyogyulas_gomb_pressed() -> void:
	GlobalData.current_hp += 5
	if GlobalData.current_hp > GlobalData.max_hp:
		GlobalData.current_hp = GlobalData.max_hp
	GlobalData.stat_changed.emit() # 🛠️ FIX: Ez hiányzott!

func _on_manatolto_gomb_pressed() -> void:
	GlobalData.current_mana += 5
	if GlobalData.current_mana > GlobalData.max_mana:
		GlobalData.current_mana = GlobalData.max_mana
	GlobalData.stat_changed.emit() # 🛠️ FIX: Ez hiányzott!
		
func _on_manafogyo_gomb_pressed() -> void:
	GlobalData.current_mana -= 5
	if GlobalData.current_mana < 0:
		GlobalData.current_mana = 0
	GlobalData.stat_changed.emit()


# === AZ ÉRTÉKEK DINAMIKUS FRISSÍTÉSE ===
func update_stat_ui() -> void:
	# 1. Gömbök méretének frissítése
	if is_instance_valid(hp_progress_bar) and is_instance_valid(mana_progress_bar):
		hp_progress_bar.max_value = GlobalData.max_hp
		hp_progress_bar.value = GlobalData.current_hp

		mana_progress_bar.max_value = GlobalData.max_mana
		mana_progress_bar.value = GlobalData.current_mana

	# 2. A felugró Label-ek szövegének aktualizálása
	if is_instance_valid(hp_text_label):
		hp_text_label.text = str(GlobalData.current_hp) + " / " + str(GlobalData.max_hp)
		
	if GlobalData.current_hp < GlobalData.max_hp:
		current_hp_label.modulate = Color.RED
	else:
		current_hp_label.modulate = Color.WHITE
		
	if is_instance_valid(mana_text_label):
		mana_text_label.text = str(GlobalData.current_mana) + " / " + str(GlobalData.max_mana)

	if GlobalData.current_mana < GlobalData.max_mana:
		current_mana_label.modulate = Color.RED
	else:
		current_mana_label.modulate = Color.WHITE

	if not is_instance_valid(panel_node) or not panel_node.visible:
		return

	# 3. Szöveges mezők frissítése a karakterlapon (Panel)
	level_label.text = str(GlobalData.current_level)
	xp_label.text = str(GlobalData.current_xp)
	
	var next_lvl = GlobalData.current_level + 1
	if GlobalData.XP_TABLE.has(next_lvl):
		next_level_xp_label.text = str(GlobalData.XP_TABLE[next_lvl])
	else:
		next_level_xp_label.text = "MAX"
		
	points_label.text = str(GlobalData.available_stat_points)
	
	str_label.text = str(GlobalData.get_total_strength())
	
	if GlobalData.bonus_strength > 0:
		str_label.modulate = Color.CORNFLOWER_BLUE
	else:
		str_label.modulate = Color.WHITE
		
	mag_label.text = str(GlobalData.stat_magic)
	dex_label.text = str(GlobalData.stat_dexterity)
	vit_label.text = str(GlobalData.stat_vitality)
	
	current_hp_label.text = str(GlobalData.current_hp)
	max_hp_label.text = str(GlobalData.max_hp)
	current_mana_label.text = str(GlobalData.current_mana)
	max_mana_label.text = str(GlobalData.max_mana)
	
	gold_label.text = str(GlobalData.total_inventory_gold)
	
	defense_label.text = str(GlobalData.get_total_defense())
	hit_chance_label.text = str(GlobalData.get_total_hit_chance()) + "%"
	damage_label.text = str(GlobalData.get_min_damage()) + " - " + str(GlobalData.get_max_damage())
	
	# Plusz gombok láthatósága a karakterlapon
	var has_points = GlobalData.available_stat_points > 0
	str_button.visible = has_points
	mag_button.visible = has_points
	dex_button.visible = has_points
	vit_button.visible = has_points
