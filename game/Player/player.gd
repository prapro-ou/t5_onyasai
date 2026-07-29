extends CharacterBody2D

@export var bullet_scene : PackedScene
signal level_up_requested

const MAP_WIDTH = 1920
const MAP_HEIGHT = 1080
const PLAYER_MARGIN = 80   # プレイヤー半分くらいの大きさ

var speed = 500.0

var facing_direction = Vector2.RIGHT

var exp_drop = 0
var level = 1
var attack_power = 1

var exp_to_lp = 5 

	
func _physics_process(_delta):
	var direction = Vector2.ZERO

	direction.x = Input.get_axis("left", "right")
	direction.y = Input.get_axis("up", "down")
	if direction != Vector2.ZERO:
		direction = direction.normalized()
		facing_direction = direction

	velocity = direction * speed
	move_and_slide()
	global_position.x = clamp(global_position.x, -960, 960)
	global_position.y = clamp(global_position.y, -540, 540)


func _on_attack_timer_timeout():

	var bullet = bullet_scene.instantiate()

	bullet.global_position = global_position
	bullet.direction = facing_direction
	
	bullet.rotation = facing_direction.angle() + PI / 2

	get_tree().current_scene.add_child(bullet)
	
var hp = 10
var invincible = false

func take_damage(damage):
	
	if invincible ==  true:
		return
	
	hp -= damage
	print("HP:", hp)
	
	invincible = true
	$InvincibleTimer.start()
	$FlashTimer.start()
	
	if hp <= 0:
		queue_free()


func _on_invincible_timer_timeout() :
	invincible = false
	$FlashTimer.stop()
	$Sprite2D.modulate.a = 1.0

func _on_flash_timer_timeout() :
	if $Sprite2D.modulate.a == 1.0:
		$Sprite2D.modulate.a = 0.3
	else:
		$Sprite2D.modulate.a = 1.0
		
func add_exp(value):
	exp_drop += value
	
	while exp_drop >= exp_to_lp:
		exp_drop -= exp_to_lp
		level_up()
	print("EXP:", exp_drop)
	
func level_up():
	level += 1
	exp_to_lp += 5
	
	print("LEVEL UP")
	print("Lv:" ,level)
	level_up_requested.emit()
