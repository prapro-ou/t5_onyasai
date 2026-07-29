extends Area2D

const SPEED = 700

var direction = Vector2.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += direction * SPEED * delta


func _on_body_entered(body):
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			var player = get_tree().get_first_node_in_group("player")
			body.take_damage(player.attack_power)
			queue_free.call_deferred()
