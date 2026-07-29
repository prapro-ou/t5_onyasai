extends Area2D


@export var value = 1
# Called when the node enters the scene tree for the first time.


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.add_exp(value)
		call_deferred("queue_free")
