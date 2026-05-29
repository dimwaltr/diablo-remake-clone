extends StaticBody2D

@onready var sprite = $Sprite2D  # Ha AnimatedSprite2D-d van, írd át arra!
@onready var fade_area = $FadeArea

@export var transparent_alpha := 0.8
@export var fade_duration := 0.2

func _ready() -> void:
	if fade_area == null:
		print("[WALL_DEBUG] HIBA: Nem találom a 'FadeArea' nevű Area2D-t!")
		return
	
	fade_area.body_entered.connect(_on_body_entered)
	fade_area.body_exited.connect(_on_body_exited)
	
	# 🆕 ÚJ TESZT: Figyeljük azt is, ha az egérrel mész rá!
	fade_area.mouse_entered.connect(func(): print("[WALL_DEBUG] Az EGÉR belépett a fal zónájába!"))
	
	print("[WALL_DEBUG] Fal sikeresen elindult, figyelem a belépőket...")


func _on_body_entered(body: Node2D) -> void:
	# KIÍRJUK A KIMENETRE, HOGY EGYÁLTALÁN ÉRZÉKEL-E VALAMIT
	print("[WALL_DEBUG] Valami belépett a zónába: ", body.name, " (Típus: ", body.get_class(), ")")
	
	# Lazább ellenőrzés: ha CharacterBody2D vagy benne van a "speed" változó (ami a játékosodban van)
	if "speed" in body or body.name.to_lower().contains("player"):
		print("[WALL_DEBUG] >>> Játékos felismerve! Halványítás indítása... <<<")
		fade_to(transparent_alpha)

func _on_body_exited(body: Node2D) -> void:
	print("[WALL_DEBUG] Valami kilépett a zónából: ", body.name)
	if "speed" in body or body.name.to_lower().contains("player"):
		fade_to(1.0)

func fade_to(target_alpha: float) -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", target_alpha, fade_duration)
