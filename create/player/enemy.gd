extends CharacterBody2D

@export var speed := 100.0
@export var stop_distance := 100.0

@onready var sprite = $AnimatedSprite2D

var player: Area2D

func _ready():
	player = get_tree().current_scene.get_node("player")

func _physics_process(delta):
	if player == null:
		return

	var direction = player.global_position - global_position
	var distance = direction.length()

	if distance > stop_distance:
		velocity = direction.normalized() * speed
	else:
		velocity = Vector2.ZERO

	if velocity == Vector2.ZERO:
		sprite.play("walk")
	else:
		if abs(velocity.x) > abs(velocity.y):
			sprite.play("walk")
			sprite.flip_h = velocity.x < 0
		elif velocity.y < 0:
			sprite.play("up")
		else:
			sprite.play("down")

	move_and_slide()
