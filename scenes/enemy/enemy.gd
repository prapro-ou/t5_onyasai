extends CharacterBody2D

@export var max_hp: int = 3
@export var move_speed: float = 60.0

@export var knockback_power: float = 350.0
@export var knockback_duration: float = 0.15

@onready var sprite: Sprite2D = $Sprite2D

var current_hp: int
var player: Node2D

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0


func _ready() -> void:
	current_hp = max_hp
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if knockback_time > 0.0:
		knockback_time -= delta
		velocity = knockback_velocity
		move_and_slide()
		return

	if player == null or not is_instance_valid(player):
		velocity = Vector2.ZERO
		return

	var direction := global_position.direction_to(player.global_position)

	velocity = direction * move_speed

	if direction.x < 0:
		sprite.flip_h = false
	elif direction.x > 0:
		sprite.flip_h = true

	move_and_slide()


func take_damage(damage: int, attacker_position: Vector2) -> void:
	current_hp -= damage
	print("敵の残りHP: ", current_hp)

	apply_knockback(attacker_position)
	flash_damage()

	if current_hp <= 0:
		queue_free()


func apply_knockback(attacker_position: Vector2) -> void:
	var knockback_direction := attacker_position.direction_to(global_position)

	knockback_velocity = knockback_direction * knockback_power
	knockback_time = knockback_duration


func flash_damage() -> void:
	sprite.modulate = Color.RED

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE
