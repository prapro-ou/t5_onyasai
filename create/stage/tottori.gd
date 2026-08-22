extends Node2D

var is_game_over := false



func _on_player_hit() -> void:
	is_game_over = true
	
	$GameOverUI/GameOverText.visible = true
	
	$Timer.stop()
	$BGM.stop()


func _process(_delta: float) -> void:
	if is_game_over:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://stage_select.tscn")

var kill_count := 0
var clear_count := 10


func enemy_defeated() -> void:
	kill_count += 1
	
	print("倒した敵: ", kill_count)
	
	if kill_count >= clear_count:
		stage_clear()


func stage_clear() -> void:
	get_tree().change_scene_to_file("res://clear.tscn")
