extends Control

@onready var slots = $SlotContainer
@onready var items = $ItemContainer

var inventory

const CELL_SIZE := 32

func setup(inv):
	inventory = inv

	draw_grid()
	refresh()

func draw_grid():

	for y in range(inventory.ROWS):
		for x in range(inventory.COLS):

			var panel = Panel.new()

			panel.custom_minimum_size = Vector2(32, 32)

			panel.position = Vector2(
				x * CELL_SIZE,
				y * CELL_SIZE
			)

			slots.add_child(panel)

func refresh():

	for child in items.get_children():
		child.queue_free()

	for item in inventory.items:

		var item_ui = preload("res://ui/Slot.tscn").instantiate()

		item_ui.set_item(item)

		item_ui.position = Vector2(
			item.grid_x * CELL_SIZE,
			item.grid_y * CELL_SIZE
		)

		items.add_child(item_ui)
