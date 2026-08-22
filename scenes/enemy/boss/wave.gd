extends Area2D


# ==================================================
# Wave設定
# ==================================================

@export var speed: float = 300.0
@export var damage: int = 1
@export var life_time: float = 5.0


# ==================================================
# ノード
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


# ==================================================
# Waveの状態
# ==================================================

var direction := Vector2.RIGHT


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	# Playerに当たったとき
	body_entered.connect(_on_body_entered)


# ==================================================
# Waveの設定
# ==================================================

func setup(new_direction: Vector2) -> void:

	direction = new_direction


	# ------------------------------------------
	# 方向によってアニメーションを変更
	# ------------------------------------------

	if direction == Vector2.RIGHT:
		animated_sprite.play("right")

	elif direction == Vector2.LEFT:
		animated_sprite.play("left")

	elif direction == Vector2.UP:
		animated_sprite.play("up")

	elif direction == Vector2.DOWN:
		animated_sprite.play("down")


	# ------------------------------------------
	# 一定時間後にWaveを削除
	# ------------------------------------------

	get_tree().create_timer(life_time).timeout.connect(queue_free)


# ==================================================
# Wave移動
# ==================================================

func _physics_process(delta: float) -> void:

	global_position += direction * speed * delta


# ==================================================
# Playerに当たった
# ==================================================

func _on_body_entered(body: Node2D) -> void:

	# Player以外は無視
	if not body.is_in_group("player"):
		return

	print("WaveがPlayerに命中！")

	# Playerのtake_damage()を呼ぶ
	if body.has_method("take_damage"):
		body.take_damage(damage)

	# 1回当たったらWaveを消す
	queue_free()
