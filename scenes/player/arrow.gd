extends Area2D


# ==================================================
# 矢の設定
# ==================================================

# 矢の移動速度
@export var speed: float = 500.0

# 敵に与える基本ダメージ
@export var damage: int = 1

# 矢が進む方向
var direction: Vector2 = Vector2.RIGHT

# Playerから受け取る属性
var player_zokusei

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

	# 敵がtake_damageを持っているか確認
	if not body.has_method("take_damage"):
		return

	# 基本ダメージ
	var actual_damage := damage

	# Player属性とEnemy属性が同じなら2倍
	if player_zokusei == body.enemy_zokusei:
		actual_damage *= 2

		print(
			"属性一致！ ",
			player_zokusei,
			" → ",
			body.enemy_zokusei,
			" ダメージ: ",
			actual_damage
		)

	else:
		print(
			"属性不一致 ",
			player_zokusei,
			" → ",
			body.enemy_zokusei,
			" ダメージ: ",
			actual_damage
		)

	# 敵へダメージ
	body.take_damage(actual_damage, global_position)

	# 攻撃音
	$AttackSound.play()

	# 音が終わってから矢を削除
	await $AttackSound.finished

	# 命中した矢を削除
	if is_inside_tree():
		queue_free()


# ==================================================
# 画面外へ出たとき
# ==================================================

func _on_screen_exited() -> void:
	# 見えなくなった矢を削除する
	queue_free()
