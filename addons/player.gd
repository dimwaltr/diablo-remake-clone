# Teljes player.gd script — fegyver + sword_walk + SHIFT attack rendszer


extends CharacterBody2D

@export var speed := 100.0
@export var acceleration := 12.0

# === LÉPÉSHANG BEÁLLÍTÁSOK ===
@export var base_step_delay := 0.65
@onready var sfx_walk = $lepeshang
@onready var footstep_timer = $FootstepTimer

@onready var nav_agent = $NavigationAgent2D
@onready var sprite = $AnimatedSprite2D

# === LIGHTNING ===
const LIGHTNING_SCENE = preload("res://objects/lightning.tscn")
@export var lightning_mana_cost := 4

# === HALÁL ===
var is_dead := false
var last_direction_suffix := "_s"
@onready var sfx_death = get_node_or_null("SfxDeath")

# === FEGYVER / ATTACK ===
var equipped_weapon_id: String = ""
var has_sword := false
var is_attacking := false
var attack_target_position := Vector2.ZERO
var weapon_min_damage := 0
var weapon_max_damage := 0
var weapon_bonus_strength := 0

@onready var sfx_sword = $SwordHit
var attack_sound_played := false
var attack_damage_done := false

func _ready():
	nav_agent.path_desired_distance = 6.0
	nav_agent.target_desired_distance = 8.0
	nav_agent.avoidance_enabled = true
	nav_agent.velocity_computed.connect(_on_velocity_computed)
	sprite.animation_finished.connect(_on_animation_finished)


func _on_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead:
		return

	if not nav_agent.is_navigation_finished():
		velocity = safe_velocity


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	# SHIFT + BAL KATT = ATTACK
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if Input.is_action_pressed("attack_modifier"):
				start_attack()
				return

	# ===== BAL KATT =====
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

	# ===== JOBB KATT = LIGHTNING =====
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if GlobalData.current_mana >= lightning_mana_cost:
			GlobalData.current_mana -= lightning_mana_cost
			GlobalData.stat_changed.emit()
			shoot_lightning()
		else:
			print("Nincs elég mana a villámhoz!")


func _physics_process(delta):
	
	# ===== HALÁL =====
	if not is_dead and GlobalData.current_hp <= 0:
		player_die()
		return

	
	if is_dead:
		return
	
	if is_attacking:

		if sprite.animation.begins_with("sword_attack"):

			# Hang a 3. frame-nél
			if sprite.frame >= 3 and not attack_sound_played:
				attack_sound_played = true

				if sfx_sword:
					sfx_sword.play()

			# Sebzés a 4. frame-nél
			if sprite.frame >= 4 and not attack_damage_done:
				attack_damage_done = true
				deal_melee_damage()

		move_and_slide()
		return

	var final_target = nav_agent.target_position
	var distance_to_target = global_position.distance_to(final_target)

	if nav_agent.is_navigation_finished() or distance_to_target <= nav_agent.target_desired_distance:
		velocity = Vector2.ZERO

		if sprite:
			sprite.stop()
			sprite.frame = 0

		footstep_timer.stop()
		return

	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	var target_velocity = direction * speed

	velocity = velocity.lerp(target_velocity, acceleration * delta)

	move_and_slide()
	nav_agent.velocity = velocity

	# ===== ANIMÁCIÓ =====
	if velocity.length() > 5.0:
		var anim_speed = velocity.length() / 30.0
		sprite.speed_scale = clamp(anim_speed, 1.8, 4.0)

		update_animation(velocity.normalized())

		if footstep_timer.is_stopped():
			play_footstep()
			var dynamic_delay = base_step_delay / sprite.speed_scale
			footstep_timer.start(dynamic_delay)
	else:
		velocity = Vector2.ZERO

		if sprite:
			sprite.stop()
			sprite.frame = 0

		footstep_timer.stop()


func update_animation(direction):
	if is_dead:
		return

	var angle = rad_to_deg(direction.angle())

	if angle < 0:
		angle += 360

	var prefix = "sword_walk" if has_sword else "walk"

	if angle >= 337.5 or angle < 22.5:
		sprite.play(prefix + "_e")
		last_direction_suffix = "_e"

	elif angle < 67.5:
		sprite.play(prefix + "_se")
		last_direction_suffix = "_se"

	elif angle < 112.5:
		sprite.play(prefix + "_s")
		last_direction_suffix = "_s"

	elif angle < 157.5:
		sprite.play(prefix + "_sw")
		last_direction_suffix = "_sw"

	elif angle < 202.5:
		sprite.play(prefix + "_w")
		last_direction_suffix = "_w"

	elif angle < 247.5:
		sprite.play(prefix + "_nw")
		last_direction_suffix = "_nw"

	elif angle < 292.5:
		sprite.play(prefix + "_n")
		last_direction_suffix = "_n"

	else:
		sprite.play(prefix + "_ne")
		last_direction_suffix = "_ne"


func start_attack() -> void:
	attack_sound_played = false
	attack_damage_done = false
	print("ATTACK CLICK")
	print("has_sword =", has_sword)
	if not has_sword:
		print("NO WEAPON")
		return

	if is_attacking:
		return

	is_attacking = true

	
		
	velocity = Vector2.ZERO
	nav_agent.target_position = global_position

	attack_target_position = get_global_mouse_position()

	var dir = (attack_target_position - global_position).normalized()

	update_attack_animation(dir)
	print("START ATTACK")

func update_attack_animation(direction: Vector2) -> void:
	var angle = rad_to_deg(direction.angle())

	if angle < 0:
		angle += 360

	var suffix := "_s"

	if angle >= 337.5 or angle < 22.5:
		suffix = "_e"
	elif angle < 67.5:
		suffix = "_se"
	elif angle < 112.5:
		suffix = "_s"
	elif angle < 157.5:
		suffix = "_sw"
	elif angle < 202.5:
		suffix = "_w"
	elif angle < 247.5:
		suffix = "_nw"
	elif angle < 292.5:
		suffix = "_n"
	else:
		suffix = "_ne"

	last_direction_suffix = suffix

	var anim_name = "sword_attack" + suffix
	print("Anim:", anim_name)
	print("Exists:", sprite.sprite_frames.has_animation(anim_name))


	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func update_equipped_weapon(weapon_id: String,min_dmg := 0,
	max_dmg := 0,bonus_str := 0) -> void:
	
	equipped_weapon_id = weapon_id
	has_sword = weapon_id != ""
	weapon_min_damage = min_dmg
	weapon_max_damage = max_dmg
	weapon_bonus_strength = bonus_str
	GlobalData.bonus_strength = weapon_bonus_strength
	GlobalData.stat_changed.emit()

	print("[PLAYER] Equipped weapon:", weapon_id)
	print(
	"[STRENGTH]",
	"BASE:",
	GlobalData.stat_strength,
	" BONUS:",
	GlobalData.bonus_strength,
	" TOTAL:",
	GlobalData.get_total_strength()
	)

	print(
	"[DAMAGE]",
	GlobalData.get_min_damage(),
	"-",
	GlobalData.get_max_damage()
	)

	# Azonnali vizuális frissítés
	if velocity.length() <= 1.0:

		var prefix = "sword_walk" if has_sword else "walk"
		var anim_name = prefix + last_direction_suffix

		if sprite.sprite_frames.has_animation(anim_name):
			sprite.play(anim_name)
			sprite.stop()
			sprite.frame = 0

func deal_melee_damage() -> void:

	var hit_chance = GlobalData.get_total_hit_chance()
	var roll = randi_range(1, 100)

	if roll > hit_chance:
		print("MISS! Roll:", roll, " Chance:", hit_chance)
		return

	var damage = randi_range(
		GlobalData.get_min_damage(),
		GlobalData.get_max_damage()
	)

	var weapon_damage = randi_range(
		weapon_min_damage,
		weapon_max_damage
	)

	damage += weapon_damage

	print(
	"[PLAYER DAMAGE] BASE:",
	GlobalData.get_min_damage(),
	"-",
	GlobalData.get_max_damage(),
	" WEAPON:",
	weapon_min_damage,
	"-",
	weapon_max_damage,
	" TOTAL:",
	GlobalData.get_min_damage() + weapon_min_damage,
	"-",
	GlobalData.get_max_damage() + weapon_max_damage
)
	

	print("HIT! Damage:", damage)

	for body in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(body):
			continue

		if global_position.distance_to(body.global_position) <= 50:
			body.take_damage(damage)
			break
			
func play_footstep():
	if sfx_walk:
		sfx_walk.pitch_scale = randf_range(0.9, 1.1)
		sfx_walk.play()


func shoot_lightning() -> void:
	if LIGHTNING_SCENE == null:
		return

	var lightning_instance = LIGHTNING_SCENE.instantiate()

	var target_pos = get_global_mouse_position()
	var attack_direction = (target_pos - global_position).normalized()

	lightning_instance.direction = attack_direction
	lightning_instance.rotation = attack_direction.angle()

	get_parent().add_child(lightning_instance)

	lightning_instance.global_position = global_position

	velocity = Vector2.ZERO
	nav_agent.target_position = global_position

	if sprite:
		sprite.stop()


func player_die() -> void:
	if is_dead:
		return

	is_dead = true

	print("[PLAYER] A karakter elesett a harcban!")

	velocity = Vector2.ZERO

	if is_instance_valid(footstep_timer):
		footstep_timer.stop()

	if is_instance_valid(sfx_death):
		sfx_death.play()

	if is_instance_valid(sprite):
		sprite.speed_scale = 1.0

		var death_anim = "warrior_death" + last_direction_suffix

		if sprite.sprite_frames.has_animation(death_anim):
			sprite.play(death_anim)
		else:
			print("[PLAYER_WARNING] Hiányzik az animáció: ", death_anim)
			sprite.stop()

	var death_screen = get_node_or_null("/root/Main/HudLayer/DeathScreen")

	if death_screen:
		death_screen.visible = true
		death_screen.modulate.a = 0.0

		var tween = create_tween()
		tween.tween_property(death_screen, "modulate:a", 0.4, 1.0)


func _on_animation_finished() -> void:
	print("ANIMATION FINISHED:", sprite.animation)
	if not is_attacking:
		return

	if not sprite.animation.begins_with("sword_attack"):
		return

	deal_melee_damage()

	

	is_attacking = false
