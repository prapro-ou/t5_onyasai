extends CharacterBody2D

const SPEED = 100

var player
var hp = 2

@export var exp_scene : PackedScene


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
		# 物理フレームの計算が終わってから安全に死亡処理を行う
		die.call_deferred()

# 死亡処理を別関数に分ける
func die():
	if exp_scene:
		var exp_drop = exp_scene.instantiate()
		exp_drop.global_position = global_position
		get_tree().current_scene.add_child(exp_drop)
	
	queue_free()


func _on_area_2d_body_entered(body):
	print("接触:", body.name)
	if body.is_in_group("player"):
		body.take_damage(1)
