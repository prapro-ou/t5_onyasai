extends CharacterBody2D

#ここから追加
#ゲームオーバーになったことを知らせる
signal died
#ここまで
@export var move_speed: float = 200.0
@export var max_hp: int = 10

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var katana_collision: CollisionShape2D = $WeaponHolder/KatanaHitBox/CollisionShape2D
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var hurt_box: Area2D = $HurtBox
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var hp_bar = $HPBar

var current_hp: int
var is_attacking: bool = false
#ここから追加
var is_dead: bool = false
#ここまで


func _ready() -> void:
	current_hp = max_hp
	katana_collision.disabled = true
	hp_bar.set_hp(current_hp, max_hp)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = direction * move_speed
	move_and_slide()

	update_animation(direction)
	check_enemy_contact()


func update_animation(direction: Vector2) -> void:
	#ここから追加
	if is_dead:
		return
	#ここまで
	if is_attacking:
		return

	if direction == Vector2.ZERO:
		animated_sprite.play("idle")
	else:
		animated_sprite.play("run")

	if direction.x < 0:
		animated_sprite.flip_h = false
		weapon_holder.scale.x = 1.0
	elif direction.x > 0:
		animated_sprite.flip_h = true
		weapon_holder.scale.x = -1.0


func _on_attack_timer_timeout() -> void:
	if is_attacking:
		return

	is_attacking = true
	animated_sprite.play("attack")
	
	katana_collision.set_deferred("disabled", false)

	await get_tree().create_timer(0.2).timeout

	if is_instance_valid(katana_collision):
		katana_collision.set_deferred("disabled", true)


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false


func _on_katana_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		#ここから追加
		$AttackSound.play()
		#ここまで
		body.take_damage(1, global_position)


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		return

	if not damage_cooldown.is_stopped():
		return

	take_damage(1)
	damage_cooldown.start()


func check_enemy_contact() -> void:
	if not damage_cooldown.is_stopped():
		return

	var overlapping_bodies := hurt_box.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			take_damage(1)
			damage_cooldown.start()
			break


func take_damage(damage: int) -> void:
	current_hp -= damage
	$DamageSound.play()
	print("プレイヤーの残りHP: ", current_hp)

	hp_bar.set_hp(current_hp, max_hp)

	if current_hp <= 0:
		die()


func die() -> void:
	#ここから追加
	is_dead = true
	#ここまで
	
	velocity = Vector2.ZERO
	set_physics_process(false)
	animated_sprite.stop()
	#ここから追加
	animated_sprite.pause()
	#ゲームオーバーになった事を知らせる
	died.emit()
	#ここまで
