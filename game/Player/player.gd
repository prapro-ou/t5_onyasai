extends CharacterBody2D

@export var bullet_scene : PackedScene

const SPEED = 500.0

var facing_direction = Vector2.RIGHT

	
func _physics_process(delta):
	var direction = Vector2.ZERO

	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		facing_direction = direction

	velocity = direction * SPEED
	move_and_slide()


func _on_attack_timer_timeout():

	var bullet = bullet_scene.instantiate()

	bullet.global_position = global_position
	bullet.direction = facing_direction
	
	bullet.rotation = facing_direction.angle() + PI / 2

	get_tree().current_scene.add_child(bullet)
