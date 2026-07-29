extends CanvasLayer



func show_ui():
	visible = true

func close_ui():
	visible = false
	get_tree().paused = false


func _on_attack_button_pressed():
	var player = get_tree().get_first_node_in_group("player")

	player.attack_power += 1

	close_ui()

func _on_speed_button_pressed():
	var player = get_tree().get_first_node_in_group("player")

	player.get_node("Attack Timer").wait_time *= 0.9

	close_ui()


func _on_move_button_pressed():
	var player = get_tree().get_first_node_in_group("player")

	player.speed += 50

	close_ui()
