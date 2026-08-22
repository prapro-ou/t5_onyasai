extends Node

@export var mob_scene: PackedScene

func _ready() -> void:
	print("spawn!")
	randomize()

func _on_mobtimer_timeout() -> void:
	print("spawn!")
	var enemy = mob_scene.instantiate()

	enemy.global_position = Vector2(
		randi_range(0, 480),
		randi_range(0, 720)
	)

	$Enemies.add_child(enemy)
