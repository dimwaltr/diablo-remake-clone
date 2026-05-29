extends CharacterBody2D

# Szörny alaptulajdonságai
@export var max_hp := 100
@export var speed := 40.0
@export var damage := 4            # Mennyit sebez a szörny a játékoson
@export var attack_cooldown := 1.2 # Két csapás közötti várakozás másodpercben

# AI beállítások
@export var detection_radius := 180.0 
@export var attack_radius := 38.0     
@export var wander_radius := 150.0  
@export var wait_time_min := 1.0    
@export var wait_time_max := 3.0    
@export var xp_reward := 75

# AI állapotok (State machine)
enum State { WANDER, CHASE, ATTACK }
var current_state: State = State.WANDER

var current_hp : int
var is_dead := false
var is_waiting := false
var spawn_position := Vector2.ZERO
var player_node: CharacterBody2D = null
var can_attack := true # Támadási időzítő kapcsolója

var last_direction_suffix := "_del"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

# Hangcsatornák beolvasása
@onready var sfx_attack: AudioStreamPlayer2D = $SfxAttack
@onready var sfx_death: AudioStreamPlayer2D = $SfxDeath

func _ready() -> void:
	current_hp = max_hp
	spawn_position = global_position
	
	if is_instance_valid(sprite):
		sprite.flip_h = false
		
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(nav_agent):
		var kulso_terkep = get_world_2d().get_navigation_map()
		NavigationServer2D.agent_set_map(nav_agent.get_navigation_map(), kulso_terkep)
		
	# Megkeressük a játékost a csoport alapján
	player_node = get_tree().get_first_node_in_group("player") as CharacterBody2D
		
	_get_next_wander_position()

func _physics_process(delta: float) -> void:
	if is_dead or nav_agent == null:
		return

	# 👑 🛠️ JAVÍTÁS / VÉDELEM: 
	# Megvizsgáljuk, hogy a játékos létezik-e és meghalt-e (is_dead == true a Player.gd-ben)
	if is_instance_valid(player_node) and player_node.get("is_dead") == true:
		# Ha a szörny éppen üldözte vagy ütötte a játékost, azonnal leállítjuk!
		if current_state == State.CHASE or current_state == State.ATTACK:
			print("[ENEMY_AI] A játékos meghalt. A szörny visszatér a bolyongáshoz.")
			current_state = State.WANDER
			_get_next_wander_position() # Keres egy új őrjárat-pontot a saját területén
		
		# Ezután lejátsszuk a normál bolyongási logikát, és átugorjuk a játékos távolságának mérését
		_handle_state_logic()
		return

	# FOLYAMATOS TÁVOLSÁG ELLENŐRZÉS A JÁTÉKOSHOZ (Csak ha a játékos még ÉL!)
	if is_instance_valid(player_node):
		var distance_to_player = global_position.distance_to(player_node.global_position)
		
		# Állapotgép kezelése a távolság alapján
		if distance_to_player <= attack_radius:
			current_state = State.ATTACK
		elif distance_to_player <= detection_radius:
			current_state = State.CHASE
			is_waiting = false 
		else:
			if current_state == State.CHASE or current_state == State.ATTACK:
				current_state = State.WANDER
				_get_next_wander_position()

	# Lefuttatjuk az aktuális állapot mozgási logikáját
	_handle_state_logic()

# Külön függvénybe szerveztük az állapotok végrehajtását a tisztább kódért
func _handle_state_logic() -> void:
	match current_state:
		State.WANDER:
			if is_waiting: return
			if nav_agent.is_navigation_finished():
				_start_waiting()
				return
			_move_along_path()
			
		State.CHASE:
			if is_instance_valid(player_node):
				nav_agent.target_position = player_node.global_position
			_move_along_path()
			
		State.ATTACK:
			velocity = Vector2.ZERO
			move_and_slide() 
			_perform_attack()

# Útvonal követése és animáció frissítése
func _move_along_path() -> void:
	if nav_agent == null or is_dead:
		return
		
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	
	velocity = direction * speed
	move_and_slide()
	
	# Dinamikus mozgás-animáció skálázás (hogy 20 FPS mellett se csússzon a lába)
	if is_instance_valid(sprite) and velocity.length() > 1.0:
		sprite.speed_scale = velocity.length() / speed
		update_8_way_animation("fallen_walking", direction)

# TÁMADÁSI LOGIKA
func _perform_attack() -> void:
	if not can_attack or is_dead: return
	
	# Dupla biztonsági ellenőrzés a függvényen belül is: ha a játékos halott, nem ütünk!
	if is_instance_valid(player_node) and player_node.get("is_dead") == true:
		return
		
	can_attack = false
	velocity = Vector2.ZERO
	
	# Megfordulunk a játékos felé és elindítjuk a 8 irányú TÁMADÁS animációt
	if is_instance_valid(player_node) and is_instance_valid(sprite):
		var look_dir = (player_node.global_position - global_position).normalized()
		update_8_way_animation("fallen_attack", look_dir)
		
		if not sprite.animation_finished.is_connected(_on_attack_animation_finished):
			sprite.animation_finished.connect(_on_attack_animation_finished)
			
	# Lejátsszuk a támadó hangot
	if is_instance_valid(sfx_attack):
		sfx_attack.pitch_scale = randf_range(0.9, 1.1)
		sfx_attack.play()
	
	print("[ENEMY] A szörny megütötte a játékost!")
	
	# Megsebezzük a játékost a GlobalData-ban
	GlobalData.current_hp -= damage
	if GlobalData.current_hp < 0:
		GlobalData.current_hp = 0
		
	# DIABLO VISUAL: Vörös villanás a játékoson
	if is_instance_valid(player_node):
		var player_sprite = player_node.get_node_or_null("AnimatedSprite2D")
		if player_sprite:
			player_sprite.modulate = Color(1.8, 0.3, 0.3, 1.0)
			get_tree().create_timer(0.12).timeout.connect(func():
				if is_instance_valid(player_sprite): player_sprite.modulate = Color.WHITE
			)
	
	# Frissítjük a HUD-ot
	GlobalData.stat_changed.emit()
	
	# Csapás után megvárjuk a cooldown-t
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func _on_attack_animation_finished() -> void:
	if is_dead or not is_instance_valid(sprite): return
	
	if sprite.animation.begins_with("fallen_attack"):
		if sprite.animation_finished.is_connected(_on_attack_animation_finished):
			sprite.animation_finished.disconnect(_on_attack_animation_finished)
		
		sprite.stop()
		sprite.frame = 0

func update_8_way_animation(animation_prefix: String, move_dir: Vector2) -> void:
	if not is_instance_valid(sprite): return
	var angle = rad_to_deg(move_dir.angle())
	if angle < 0: angle += 360.0
	var suffix = "_del" 

	if angle >= 337.5 or angle < 22.5: suffix = "_kelet"
	elif angle < 67.5: suffix = "_delk"
	elif angle < 112.5: suffix = "_del"
	elif angle < 157.5: suffix = "_dny"
	elif angle < 202.5: suffix = "_ny"
	elif angle < 247.5: suffix = "_eny"
	elif angle < 292.5: suffix = "_e"
	else: suffix = "_ek"

	last_direction_suffix = suffix 
	sprite.play(animation_prefix + suffix)

func _get_next_wander_position() -> void:
	is_waiting = false
	if nav_agent == null: nav_agent = get_node_or_null("NavigationAgent2D")
	if nav_agent == null: return
	
	var random_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	var random_distance = randf_range(0.0, wander_radius)
	var target_pos = spawn_position + (random_direction * random_distance)
	
	nav_agent.target_position = target_pos
	
	if is_instance_valid(sprite):
		var indulo_irany = (target_pos - global_position).normalized()
		update_8_way_animation("fallen_walking", indulo_irany)

func _start_waiting() -> void:
	is_waiting = true
	velocity = Vector2.ZERO
	if is_instance_valid(sprite):
		sprite.stop()
		sprite.frame = 0
	var random_wait = randf_range(wait_time_min, wait_time_max)
	await get_tree().create_timer(random_wait).timeout
	if not is_dead and current_state == State.WANDER:
		_get_next_wander_position()

func take_damage(amount: int) -> void:
	if is_dead: return
	current_hp -= amount
	print("[ENEMY] Szörny eltalálva! Sebzés: ", amount, " | Maradék HP: ", current_hp)
	
	# Csak akkor hergelhető fel, ha a játékos még életben van!
	if is_instance_valid(player_node) and player_node.get("is_dead") == false:
		current_state = State.CHASE
	
	if is_instance_valid(sprite):
		sprite.modulate = Color(1.5, 0.2, 0.2, 1.0) 
		get_tree().create_timer(0.12).timeout.connect(func():
			if is_instance_valid(sprite) and not is_dead: sprite.modulate = Color.WHITE
		)
	if current_hp <= 0: die()

func die() -> void:
	is_dead = true
	set_physics_process(false)
	var collision = get_node_or_null("CollisionShape2D")
	if collision: collision.disabled = true
	
	print("[ENEMY] A szörny meghalt!")
	
	if is_instance_valid(sfx_death):
		sfx_death.pitch_scale = randf_range(0.95, 1.05)
		sfx_death.play()
	
	if GlobalData.has_method("gain_xp"):
		GlobalData.get("gain_xp").call(xp_reward)
		
	GlobalData.stat_changed.emit()
	
	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE 
		var death_anim_name = "fallen_death" + last_direction_suffix
		if sprite.sprite_frames.has_animation(death_anim_name):
			sprite.play(death_anim_name)
			await sprite.animation_finished
		else:
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.5)
			await tween.finished
			
	if is_instance_valid(sfx_death) and sfx_death.playing:
		await sfx_death.finished
		
	queue_free()
