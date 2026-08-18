extends CharacterBody2D

# 敵が倒されたことをMainへ知らせるシグナル
signal died

@export var max_hp: int = 3
@export var move_speed: float = 60.0

@export var knockback_power: float = 350.0
@export var knockback_duration: float = 0.15

# Sprite2DとAnimatedSprite2Dの両方を許容する
@onready var sprite: Node = get_node_or_null("Sprite2D") if get_node_or_null("Sprite2D") != null else get_node_or_null("AnimatedSprite2D")
# 青鬼・黄色鬼には存在しないため、nullになる
@onready var hp_bar: Control = get_node_or_null("HPBar")


var current_hp: int
var player: Node2D

var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_time: float = 0.0


func _ready() -> void:
	# 現在HPを最大HPで初期化する
	current_hp = max_hp

	# playerグループからプレイヤーを取得する
	player = get_tree().get_first_node_in_group("player")

	# HPBarが付いている敵だけHPバーを初期化する
	# 現在は赤鬼だけが対象
	if hp_bar != null:
		hp_bar.set_hp(current_hp, max_hp)
	# この敵がAnimatedSprite2Dを持っている場合、アニメーションを再生する
	if sprite != null and sprite is AnimatedSprite2D:
		# "default" という名前のアニメーションを再生する
		# ※ AnimatedSprite2Dの設定画面で作ったアニメーション名（例: "walk", "move" など）に変更してください。
		sprite.play("default")

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
	# HPを減らす
	current_hp -= damage

	# HPが0未満にならないようにする
	current_hp = clamp(current_hp, 0, max_hp)

	# HPBarが付いている敵だけHPバーを更新する
	# 青鬼・黄色鬼では実行されない
	if hp_bar != null:
		hp_bar.set_hp(current_hp, max_hp)

	print("敵の残りHP: ", current_hp)

	# ノックバック処理
	apply_knockback(attacker_position)

	# ダメージ時の点滅処理
	flash_damage()

	# HPが0なら敵を倒す
	if current_hp <= 0:
		die()


func apply_knockback(attacker_position: Vector2) -> void:
	var knockback_direction := attacker_position.direction_to(global_position)

	knockback_velocity = knockback_direction * knockback_power
	knockback_time = knockback_duration


func flash_damage() -> void:
	sprite.modulate = Color.RED

	await get_tree().create_timer(0.1).timeout

	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE
		

#ここから追加
#敵の動きを止める
func stop_enemy() -> void:
	set_physics_process(false)
#ここまで

# 敵が倒されたときに呼ばれる処理
func die() -> void:
	# Mainへ「敵が倒された」と知らせる
	died.emit()

	# 敵をゲーム画面から削除する
	queue_free()
