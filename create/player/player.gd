extends Area2D
signal hit
signal have
@export var speed=400
var screen_size

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size=get_viewport_rect().size
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("playerr"):
		velocity.x +=1
	if Input.is_action_pressed("playerl"):
		velocity.x -=1
	if Input.is_action_pressed("playeru"):
		velocity.y -=1
	if Input.is_action_pressed("playerd"):
		velocity.y +=1

	if velocity.length()>0:
		velocity=velocity.normalized()*speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	position +=velocity * delta
	position=position.clamp(Vector2.ZERO , screen_size)
	
	if velocity.x !=0:
		$AnimatedSprite2D.animation="playerwalk"
		$AnimatedSprite2D.flip_v=false
		$AnimatedSprite2D.flip_h=velocity.x<0
	elif velocity.y <0:
		$AnimatedSprite2D.animation="playerup"
	elif velocity.y > 0:
		$AnimatedSprite2D.animation = "playerdown"
	


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	$CollisionShape2D.set_deferred("disabled", true)

	for i in range(10):
		visible = !visible
		await get_tree().create_timer(0.1).timeout

	visible = true
	$CollisionShape2D.disabled = false
