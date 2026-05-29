extends Control

@export var player_inventory: Node
@onready var grid_container = $GridContainer
@onready var item_container = $ItemContainer

const CELL_SIZE = 25 # Egy cella mérete pixelben

func _ready():
	setup_background_grid()
	if player_inventory:
		player_inventory.inventory_updated.connect(update_hud)
		update_hud()

# Legyártja a 4x10-es szürke rácsot a háttérben
func setup_background_grid():
	var empty_tex = PlaceholderTexture2D.new()
	empty_tex.size = Vector2(CELL_SIZE, CELL_SIZE)
	
	for i in range(40):
		var slot = TextureRect.new()
		slot.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		grid_container.add_child(slot)
		slot.texture = empty_tex

# Frissíti a tárgyak megjelenését
func update_hud():
	# Kitakarítjuk a korábbi tárgyakat a képernyőről
	for child in item_container.get_children():
		child.queue_free()
		
	# Nyomon követjük, mit rajzoltunk már ki, hogy a többcellás tárgyakat ne duplázzuk
	var drawn_items = []
	
	for r in range(player_inventory.ROWS):
		for c in range(player_inventory.COLS):
			var slot_data = player_inventory.grid[r][c]
			
			if slot_data != null:
				var item = slot_data["item"]
				var start_r = slot_data["start_r"]
				var start_c = slot_data["start_c"]
				
				# Ha ezt a tárgyat ezen a kezdőpozíción még nem rajzoltuk ki
				if not [item, start_r, start_c] in drawn_items:
					drawn_items.append([item, start_r, start_c])
					
					# === 🛠️ ATOMBIZTOS JAVÍTÁS: EGÉSZ SZÁMMÁ KÉNYSZERÍTJÜK A MÉRETEKET ===
					# Az int() függvény letöri a Godot által generált ".0" kiterjesztést!
					# Így az 1.0-ból tiszta 1 lesz, a 3.0-ból pedig tiszta 3 cella szélesség/magasság.
					var clean_width: int = int(item.width)
					var clean_height: int = int(item.height)
					
					# Új textúra létrehozása a tárgynak
					var item_pic = TextureRect.new()
					item_pic.texture = item.texture
					
					# Kényszerítjük a megfelelő méretet pixelben a letisztított egész számok alapján
					var target_size = Vector2(clean_width * CELL_SIZE, clean_height * CELL_SIZE)
					item_pic.custom_minimum_size = target_size
					item_pic.size = target_size
					item_pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					item_pic.stretch_mode = TextureRect.STRETCH_SCALE
					
					# Pozicionálás a rácson belül a kezdőcella alapján
					item_pic.position = Vector2(start_c * CELL_SIZE, start_r * CELL_SIZE)
					
					item_container.add_child(item_pic)
