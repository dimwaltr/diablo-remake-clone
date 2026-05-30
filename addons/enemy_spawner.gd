extends Node2D

@export var enemy_scene: PackedScene
@export var max_enemies := 5
@export var respawn_time := 5.0
@export var enable_respawn := false


var current_enemies := 0
@onready var spawn_area = $SpawnArea
@onready var collision_shape = $SpawnArea/CollisionShape2D

func _ready() -> void:

	for i in max_enemies:
		spawn_enemy()


func spawn_enemy() -> void:

	print("Spawner:", global_position)
	print("Spawn:", get_random_position())
	
	var enemy = enemy_scene.instantiate()

	enemy.global_position = get_random_position()

	add_child(enemy)

	current_enemies += 1

	enemy.tree_exited.connect(_on_enemy_removed)


func _on_enemy_removed() -> void:

	current_enemies -= 1

	if not enable_respawn:
		return

	var tree := get_tree()

	if tree == null:
		return

	await tree.create_timer(respawn_time).timeout

	if current_enemies < max_enemies:
		spawn_enemy()


func get_random_position() -> Vector2:

	var circle = collision_shape.shape as CircleShape2D

	var radius = circle.radius

	var angle = randf() * TAU
	var distance = sqrt(randf()) * radius

	return spawn_area.global_position + Vector2(
		cos(angle),
		sin(angle)
	) * distance
