extends Button

# Beússzuk a szerkesztőből a létrehozott .tres fájlt
@export var teszt_targj: Item 

# Húzd be ide a PlayerInventory csomópontot az Inspectorban
@export var inventory: Node 

func _on_pressed():
	if inventory and teszt_targj:
		inventory.add_item(teszt_targj)
