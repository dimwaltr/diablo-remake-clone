extends Area2D

# Húzd be ide a nyitott ajtó textúráját az Inspector-ból (Preload)
const NYITOTT_TEXTURA = preload("res://bground sheet/ajto_nyitva_ok.png")
const ZART_TEXTURA = preload("res://bground sheet/ajto_zarva.png")
const HANG_NYITAS = preload("res://sounds/items/dooropen.wav")
const HANG_CSUKAS = preload("res://sounds/items/doorclos.wav")

var nyitva = false
@onready var sprite = $Sprite2D

func _ready():
	# Összekötjük az egér eseményt a saját függvényünkkel
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered():
	sprite.material.set_shader_parameter("outline_enabled", true)
	

func _on_mouse_exited():
	sprite.material.set_shader_parameter("outline_enabled", false)
	
	
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int):
	# Ellenőrizzük, hogy a bal egérgombot nyomták-e meg
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		ajto_nyitas_csukas()

func ajto_nyitas_csukas():
	nyitva = !nyitva # Átváltjuk az állapotot
	
	if nyitva:
		$Sprite2D.texture = NYITOTT_TEXTURA
		# Opcionális: Ha van külön fizikai ütközője (StaticBody2D), itt kikapcsolhatod
		# Beállítjuk a nyitás hangot és lejátsszuk
		$ajtohang.stream = HANG_NYITAS
		$ajtofal/CollisionShape2D.disabled = true
		$ajtohang.play()
	else:
		$Sprite2D.texture = ZART_TEXTURA
		# Opcionális: Itt visszakapcsolhatod a fizikai ütközőt
		# Beállítjuk a csukás hangot és lejátsszuk
		$ajtohang.stream = HANG_CSUKAS
		$ajtofal/CollisionShape2D.disabled = false
		$ajtohang.play()
