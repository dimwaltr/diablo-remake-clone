extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var outline: Sprite2D = $Sprite2D

var opened := false


func _ready():

	# kezdetben nincs kijelölés
	outline.visible = false

	# zárt állapot
	sprite.play("closed")

	# signal kötés (fontos!)
	sprite.animation_finished.connect(_on_animation_finished)


func _input_event(viewport, event, shape_idx):

	if opened:
		return

	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_LEFT:

			on_select()


func on_select():

	# Diablo-s highlight
	outline.visible = true
	outline.modulate = Color(1, 1, 0)

	# kis késleltetés = “click súly”
	await get_tree().create_timer(0.05).timeout

	open_chest()


func open_chest():

	if opened:
		return

	opened = true

	sprite.play("open")


func _on_animation_finished():

	# ha az open anim véget ért → highlight eltűnik
	if sprite.animation == "open":

		outline.visible = false
