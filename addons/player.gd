extends CharacterBody2D

@export var speed := 100.0
@export var acceleration := 12.0

# === LÉPÉSHANG BEÁLLÍTÁSOK ===
@export var base_step_delay := 0.65  # Alap lépésköz másodpercben, Alignment speed_scale = 1.0
@onready var sfx_walk = $lepeshang
@onready var footstep_timer = $FootstepTimer
# ============================

@onready var nav_agent = $NavigationAgent2D
@onready var sprite = $AnimatedSprite2D

# === 🆕 LIGHTNING VARÁZSLAT BEÁLLÍTÁSOK ===
const LIGHTNING_SCENE = preload("res://objects/lightning.tscn")
@export var lightning_mana_cost := 4  # A villám ára 4 mana pont

# === 🆕 ÚJ: HALÁL ÉS IRÁNY VÁLTOZÓK ===
var is_dead := false
var last_direction_suffix := "_s" # Alapértelmezett déli irány, ha mozdulatlanul halna meg indításkor
@onready var sfx_death = get_node_or_null("SfxDeath") # A játékos alá rendelt halálhang node


func _ready():
	nav_agent.path_desired_distance = 6.0
	nav_agent.target_desired_distance = 8.0
	nav_agent.avoidance_enabled = true
	nav_agent.velocity_computed.connect(_on_velocity_computed)

func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead: return # Halottan nem számolunk új sebességet
	if not nav_agent.is_navigation_finished():
		velocity = safe_velocity

func _unhandled_input(event: InputEvent) -> void:
	if is_dead: return # 🆕 ÚJ: Halottan teljesen letiltjuk az inputot!
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var inventory_ui = get_node_or_null("/root/Main/CanvasLayer") as CanvasLayer
			if inventory_ui and inventory_ui.visible:
				var texture_rect = inventory_ui.get_node_or_null("InventoryGUI/TextureRect")
				if texture_rect == null:
					texture_rect = inventory_ui.get_node_or_null("TextureRect")
				
				if texture_rect:
					var mouse_pos = texture_rect.get_local_mouse_position()
					var rect = Rect2(Vector2.ZERO, texture_rect.size)
					
					if rect.has_point(mouse_pos):
						return 
			nav_agent.target_position = get_global_mouse_position()

	# === JOBB EGÉRGOMB - VILLÁM VARÁZSLAT ===
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GlobalData.current_mana >= lightning_mana_cost:
			GlobalData.current_mana -= lightning_mana_cost
			GlobalData.stat_changed.emit() # Azonnal frissül a kék managömböd!
			
			shoot_lightning()
		else:
			print("Nincs elég mana a villámhoz!")


func _physics_process(delta):
	# 👑 🛠️ JAVÍTÁS / KIEGÉSZÍTÉS: 
	# Megnézzük, hogy az életerőnk elfogyott-e. Ha igen, és még élünk, elindítjuk a halált!
	if not is_dead and GlobalData.current_hp <= 0:
		player_die()
		return
		
	if is_dead: return # 🆕 ÚJ: Halottan leállítjuk a teljes fizikai folyamatot!
	
	var final_target = nav_agent.target_position
	var distance_to_target = global_position.distance_to(final_target)
	
	if nav_agent.is_navigation_finished() or distance_to_target <= nav_agent.target_desired_distance:
		velocity = Vector2.ZERO
		if sprite:
			sprite.stop()
			sprite.frame = 0
		footstep_timer.stop() # Leállítjuk az időzítőt, ha megállt a karakter
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	var target_velocity = direction * speed
	
	velocity = velocity.lerp(target_velocity, acceleration * delta)
	
	move_and_slide()
	nav_agent.velocity = velocity

	# ===== ANIMÁCIÓ ÉS LÉPÉSHANG IDŐZÍTÉS =====
	if velocity.length() > 5.0:
		var anim_speed = velocity.length() / 30.0
		sprite.speed_scale = clamp(anim_speed, 1.8, 4.0)
		update_animation(velocity.normalized())
		
		# Ha az időzítő lejárt vagy még el sem indult, lejátszunk egy lépést
		if footstep_timer.is_stopped():
			play_footstep()
			# A lépésközt elosztjuk az animáció sebességével, így gyorsabb futásnál sűrűbben lép
			var dynamic_delay = base_step_delay / sprite.speed_scale
			footstep_timer.start(dynamic_delay)
	else:
		velocity = Vector2.ZERO
		if sprite:
			sprite.stop()
			sprite.frame = 0
		footstep_timer.stop() # Ha teljesen megáll, azonnal lője le az időzítőt

func update_animation(direction):
	if is_dead: return # Halottan nem frissítjük a séta animációkat!
	
	var angle = rad_to_deg(direction.angle())
	if angle < 0:
		angle += 360

	# 🆕 JAVÍTVA: Minden irány elmenti a saját egyedi szuffixumát a halálhoz!
	if angle >= 337.5 or angle < 22.5:
		sprite.play("walk_e")
		last_direction_suffix = "_e"
	elif angle < 67.5:
		sprite.play("walk_se")
		last_direction_suffix = "_se"
	elif angle < 112.5:
		sprite.play("walk_s")
		last_direction_suffix = "_s"
	elif angle < 157.5:
		sprite.play("walk_sw")
		last_direction_suffix = "_sw"
	elif angle < 202.5:
		sprite.play("walk_w")
		last_direction_suffix = "_w"
	elif angle < 247.5:
		sprite.play("walk_nw")
		last_direction_suffix = "_nw"
	elif angle < 292.5:
		sprite.play("walk_n")
		last_direction_suffix = "_n"
	else:
		sprite.play("walk_ne")
		last_direction_suffix = "_ne"

# ===== LÉPÉSHANG LEJÁTSZÁSA PITCH RANDOMIZÁLÁSSAL =====
func play_footstep():
	if sfx_walk:
		# Diablo stílusú hangmagasság-ingadozás (0.9 és 1.1 között)
		# Ez megszünteti a gépies, ismétlődő géppuska-hatást
		sfx_walk.pitch_scale = randf_range(0.9, 1.1)
		sfx_walk.play()

func shoot_lightning() -> void:
	if LIGHTNING_SCENE == null:
		return
		
	var lightning_instance = LIGHTNING_SCENE.instantiate()
	
	# 1. Kiszámoljuk az irányt és a rotációt
	var target_pos = get_global_mouse_position()
	var attack_direction = (target_pos - global_position).normalized()
	
	lightning_instance.direction = attack_direction
	lightning_instance.rotation = attack_direction.angle()
	
	# 2. Hozzáadjuk a jelenethez (FONTOS: a pozíciót az add_child UTÁN adjuk meg!)
	get_parent().add_child(lightning_instance)
	
	# 3. Kényszerítjük a pontos globális pozíciót a karakter közepére
	lightning_instance.global_position = global_position
	
	# Megállítjuk a karaktert varázslás közben
	velocity = Vector2.ZERO
	nav_agent.target_position = global_position 
	if sprite:
		sprite.stop()

# === 🆕 ÚJ: JÁTÉKOS HALÁL FÜGGVÉNY ===
func player_die() -> void:
	if is_dead: return
	is_dead = true
	
	print("[PLAYER] A karakter elesett a harcban!")
	velocity = Vector2.ZERO
	if is_instance_valid(footstep_timer):
		footstep_timer.stop()
	
	# 1. Elindítjuk a halálhörgést
	if is_instance_valid(sfx_death):
		sfx_death.play()
		
	# 2. Elindítjuk a pontos irányú halál animációt (pl: warrior_death_s)
	if is_instance_valid(sprite):
		sprite.speed_scale = 1.0 # Visszaállítjuk normál sebességre a halált
		var death_anim = "warrior_death" + last_direction_suffix
		if sprite.sprite_frames.has_animation(death_anim):
			sprite.play(death_anim)
		else:
			print("[PLAYER_WARNING] Hiányzik az animáció: ", death_anim)
			sprite.stop()
			
	# 3. Bekapcsoljuk és lágyan beúsztatjuk a vörös képernyőt a HudLayer-ről
	var death_screen = get_node_or_null("/root/Main/HudLayer/DeathScreen")
	if death_screen:
		death_screen.visible = true
		death_screen.modulate.a = 0.0 # Átlátszóról indítunk
		
		# 1 másodperc alatt fokozatosan beúsztatjuk a vörös halál-ködöt (Tween)
		var tween = create_tween()
		tween.tween_property(death_screen, "modulate:a", 0.4, 1.0)
