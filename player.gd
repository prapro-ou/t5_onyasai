extends CharacterBody2D

@export var speed: float = 400.0

# 攻撃用の弾のシーン
@export var bullet_scene: PackedScene

# スクリプトから子ノードのSprite2Dを操作するための変数
@onready var sprite_2d: Sprite2D = $Sprite2D

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		
		# 向きを変える処理（左右反転）
		if direction.x < 0:
			sprite_2d.flip_h = true   # 左を向いたときは画像を反転
		elif direction.x > 0:
			sprite_2d.flip_h = false  # 右を向いたときは通常の向きに戻す
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	# プレイヤーを実際に移動させる（if/elseの枠から出た正しい位置）
	move_and_slide()

# Timerノードから呼び出される関数
func _on_timer_timeout() -> void:
	shoot()

func shoot() -> void:
	if not bullet_scene:
		print("弾のシーンが設定されていません！")
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	get_tree().current_scene.add_child(bullet)
