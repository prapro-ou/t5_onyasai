extends Area2D

const SPEED = 700

var direction = Vector2.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += direction * SPEED * delta


func _on_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(1)
		queue_free()
