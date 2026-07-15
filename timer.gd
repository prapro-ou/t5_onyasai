extends CharacterBody2D

@export var speed: float = 300.0

# 攻撃用の弾のシーン（後で作成する bullet.tscn をここにドラッグ＆ドロップします）
@export var bullet_scene: PackedScene

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
	move_and_slide()

# Timerノードの「timeout」シグナルと接続する関数
func _on_timer_timeout() -> void:
	shoot()

func shoot() -> void:
	if not bullet_scene:
		print("弾のシーンが設定されていません！")
		return
		
	# 弾のインスタンスを生成してステージに配置
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position
	
	# 例：前方に飛ばす場合、プレイヤーの向いている方向などを弾に渡す
	# (ここでは一旦メインシーンのルートに追加する処理)
	get_tree().current_scene.add_child(bullet)
