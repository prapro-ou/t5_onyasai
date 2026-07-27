extends Node2D

@export var enemy_scene: PackedScene

@onready var spawn_timer: Timer = $SpawnTimer


func _ready():
	spawn_timer.timeout.connect(spawn_enemy)


func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy := enemy_scene.instantiate()

	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		return

	var angle := randf_range(0.0, TAU)
	var spawn_distance := 500.0

	var spawn_offset := Vector2.RIGHT.rotated(angle) * spawn_distance
	enemy.global_position = player.global_position + spawn_offset

	add_child(enemy)
