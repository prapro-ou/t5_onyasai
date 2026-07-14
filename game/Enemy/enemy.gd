extends CharacterBody2D

const SPEED = 100

var player
var hp = 3


func _ready():
	player = get_tree().get_first_node_in_group("player")


func _physics_process(_delta):

	if player:
		var direction = (player.global_position - global_position).normalized()

		velocity = direction * SPEED

		move_and_slide()

func take_damage(damage):

	hp -= damage

	if hp <= 0:
		queue_free()
