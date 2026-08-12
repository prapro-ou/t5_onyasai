extends Area2D


# ==================================================
# 矢の設定
# ==================================================

# 矢の移動速度
@export var speed: float = 500.0

# 敵に与えるダメージ
@export var damage: int = 1

# 矢が進む方向
var direction: Vector2 = Vector2.RIGHT


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	# 敵などに接触したときの処理
	body_entered.connect(_on_body_entered)

	# 画面外に出たときの処理
	$VisibleOnScreenNotifier2D.screen_exited.connect(_on_screen_exited)


# ==================================================
# 矢の移動
# ==================================================

func _physics_process(delta: float) -> void:
	# 指定された方向へ矢を移動する
	global_position += direction * speed * delta


# ==================================================
# 敵への命中
# ==================================================

func _on_body_entered(body: Node2D) -> void:
	# 接触した相手が敵か確認する
	if not body.is_in_group("enemy"):
		return

	# 敵がtake_damageを持っている場合
	if body.has_method("take_damage"):
		# 敵へダメージを与える
		body.take_damage(damage, global_position)

	# 命中した矢を削除する
	queue_free()


# ==================================================
# 画面外へ出たとき
# ==================================================

func _on_screen_exited() -> void:
	# 見えなくなった矢を削除する
	queue_free()
