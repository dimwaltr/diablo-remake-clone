extends Node

# --- ARANY ---
var total_inventory_gold: int = 0

# --- SZINTEZÉS ÉS XP ---
var current_level: int = 1
var current_xp: int = 0
var available_stat_points: int = 5

# --- ALAP ALAP TULAJDONSÁGOK ---
var stat_strength: int = 10     # Erő
var stat_magic: int = 10        # Mágia
var stat_dexterity: int = 10    # Ügyesség
var stat_vitality: int = 10     # Életerő (Vitalitás)

# --- SZAHRMAZTATOTT ÉRTÉKEK (Élet és Mana) ---
var max_hp: int = 50
var current_hp: int = 50
var max_mana: int = 20
var current_mana: int = 20
var bonus_strength: int = 0

# --- HARCI STATISZTIKÁK (Pajzs, Ütés, Sebzés) ---
var base_defense: int = 5       # Alap védelmi pajzs
var base_hit_chance: int = 50   # Alap ütési találati esély %-ban
var total_kills := 0           #megölt ellenségek száma

# --- XP TÁBLÁZAT ---
const XP_TABLE = {
	1: 0,
	2: 200,
	3: 500,
	4: 1000,
	5: 2000,
	6: 4000,
	7: 8000,
	8: 16000,
	9: 30000,
	10: 50000
}

# Számított harci értékek (Diablo 1 mechanika alapján az alap tulajdonságokból)
func get_total_strength() -> int:
	return stat_strength + bonus_strength
	
func get_total_defense() -> int:
	# Az Ügyesség (Dexterity) minden 5. pontja növeli a pajzsot / védelmet
	return base_defense + (stat_dexterity / 5)

func get_total_hit_chance() -> int:
	# Az Ügyesség közvetlenül növeli a találati esélyt
	return base_hit_chance + stat_dexterity

func get_min_damage() -> int:
	return 1 + (get_total_strength() / 3)

func get_max_damage() -> int:
	return 4 + (get_total_strength() / 2)

func gain_xp(amount: int) -> void:
	current_xp += amount
	var next_level = current_level + 1
	if XP_TABLE.has(next_level):
		if current_xp >= XP_TABLE[next_level]:
			level_up()

func add_kill() -> void:
	total_kills += 1

	print("[KILLS] Összes ölés:", total_kills)

func level_up() -> void:
	current_level += 1
	available_stat_points += 5
	max_hp += 5
	current_hp = max_hp
	max_mana += 3
	current_mana = max_mana
	emit_signal("stat_changed")

signal stat_changed
