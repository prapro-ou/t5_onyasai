extends Node2D

@export var enemy_scene : PackedScene
@export var bullet_scene : PackedScene

const MAX_ENEMIES = 30
func _on_enemy_timer_timeout():

	var enemy_count = get_tree().get_nodes_in_group("enemy").size()
	
	if enemy_count >= MAX_ENEMIES :
		return
			
	var enemy = enemy_scene.instantiate()
	
	add_child(enemy)
	
	var player_pos = $Player.global_position
	
	var distance = 600
	
	#0上1右2下3左
	var side = randi_range(0, 3)
	
	var pos = Vector2.ZERO
	
	if side == 0:
		# 上
		pos = player_pos + Vector2(
			randi_range(-1000, 1000),
			-distance
		)

	elif side == 1:
		# 右
		pos = player_pos + Vector2(
			distance,
			randi_range(-1000, 1000)
		)

	elif side == 2:
		# 下
		pos = player_pos + Vector2(
			randi_range(-1000, 1000),
			distance
		)

	else:
		# 左
		pos = player_pos + Vector2(
			-distance,
			randi_range(-1000, 1000)
		)


	enemy.global_position = pos
