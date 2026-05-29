extends Node

const COLS = 10
const ROWS = 4

# A rács: null = üres, vagy az InvItem referenciája
var grid = []

signal inventory_updated

func _ready():
	# Inicializáljuk a 4x10-es üres rácsot
	for r in range(ROWS):
		var row = []
		row.resize(COLS)
		row.fill(null)
		grid.append(row)

# Megnézi, hogy a tárgy elfér-e egy adott (sor, oszlop) pozíciótól kezdve
func can_place_item(item: Item, start_r: int, start_c: int) -> bool:
	if start_r + item.height > ROWS or start_c + item.width > COLS:
		return false # Kilógna a hátizsákból
		
	for r in range(start_r, start_r + item.height):
		for c in range(start_c, start_c + item.width):
			if grid[r][c] != null:
				return false # Már foglalt a cella
	return true

# Megkeresi az első szabad helyet, és berakja a tárgyat
func add_item(item: Item) -> bool:
	for r in range(ROWS):
		for c in range(COLS):
			if can_place_item(item, r, c):
				# Lefoglaljuk a cellákat a tárgynak
				for ir in range(r, r + item.height):
					for ic in range(c, c + item.width):
						# Mentjük a tárgyat és a kezdőpozícióját a kirajzoláshoz
						grid[ir][ic] = {"item": item, "start_r": r, "start_c": c}
				inventory_updated.emit()
				return true
	print("Nincs elég hely a tárgynak!")
	return false
