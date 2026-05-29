extends CanvasLayer

@onready var inventory_ui = $InventoryUI
@onready var inventory_button = $InventoryButton

var open := false

func _ready():
	inventory_ui.visible = false

	if inventory_button:
		inventory_button.pressed.connect(toggle_inventory)

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			toggle_inventory()

	if event is InputEventMouseButton and event.pressed:
		# opcionális: jobb klikk is nyithatja
		if event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_inventory()

func toggle_inventory():
	open = !open
	inventory_ui.visible = open
