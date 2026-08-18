extends "res://scenes/enemy/enemy.gd"


# ==================================================
# 毒沼関連
# ==================================================

@onready var poison_timer: Timer = $PoisonTimer

# 毒沼シーン
@export var poison_puddle_scene: PackedScene


# ==================================================
# 設定
# ==================================================

# 毒沼を生成する間隔
@export var poison_interval: float = 6.0

# 点滅回数
@export var flash_count: int = 3

# 点滅の間隔
@export var flash_interval: float = 0.12


# ==================================================
# 状態
# ==================================================

# ゲームオーバーなどで停止
var is_stopped := false

# 毒沼を生成中か
var is_poison_attack := false

# 毒沼を生成する位置
var poison_spawn_position := Vector2.ZERO


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	
	# ボスのHPを設定
	max_hp = max_hp * 2
	current_hp = max_hp
	
	super._ready()

	# Player取得
	player = get_tree().get_first_node_in_group("player")

	# enemyグループ
	add_to_group("enemy")

	# 毒沼生成間隔
	poison_timer.wait_time = poison_interval

	# Timer接続
	if not poison_timer.timeout.is_connected(start_poison_attack):
		poison_timer.timeout.connect(start_poison_attack)

	# タイマー開始
	poison_timer.start()


# ==================================================
# 毒沼攻撃開始
# ==================================================

func start_poison_attack() -> void:

	# 停止中なら何もしない
	if is_stopped:
		return

	# すでに攻撃中なら何もしない
	if is_poison_attack:
		return

	# 毒沼攻撃中
	is_poison_attack = true

	print("毒沼攻撃の前兆！")


	# ==================================================
	# ボスが「今いる場所」を記録
	# ==================================================

	poison_spawn_position = global_position


	# ==================================================
	# ボスを点滅
	# ==================================================

	await poison_warning_flash()


	# ==================================================
	# ゲームオーバーなら中止
	# ==================================================

	if is_stopped:

		is_poison_attack = false

		return


	# ==================================================
	# 毒沼生成
	# ==================================================

	spawn_poison_puddle()


	# 攻撃終了
	is_poison_attack = false


	# ==================================================
	# 次の毒沼まで待つ
	# ==================================================

	if is_stopped:
		return

	poison_timer.start()


# ==================================================
# ボスの点滅
# ==================================================

func poison_warning_flash() -> void:

	for i in range(flash_count):

		# ゲームオーバーなら中止
		if is_stopped:
			sprite.modulate = Color.WHITE
			return


		# ------------------------------------------
		# 白くする
		# ------------------------------------------

		sprite.modulate = Color(3.0, 3.0, 3.0)

		await get_tree().create_timer(flash_interval).timeout


		# ------------------------------------------
		# 通常に戻す
		# ------------------------------------------

		if is_stopped:
			sprite.modulate = Color.WHITE
			return

		sprite.modulate = Color.WHITE

		await get_tree().create_timer(flash_interval).timeout


	# 最後は通常色
	sprite.modulate = Color.WHITE


# ==================================================
# 毒沼生成
# ==================================================

func spawn_poison_puddle() -> void:

	# 停止中なら生成しない
	if is_stopped:
		return


	# 毒沼シーン確認
	if poison_puddle_scene == null:

		print("毒沼シーンが設定されていません。")

		return


	# ==================================================
	# 毒沼生成
	# ==================================================

	var poison_puddle = poison_puddle_scene.instantiate()

	get_tree().current_scene.add_child(poison_puddle)


	# ==================================================
	# 「さっきまでボスがいた場所」に配置
	# ==================================================

	poison_puddle.global_position = poison_spawn_position


	print("毒沼を生成！")
	print("生成位置：", poison_spawn_position)


# ==================================================
# ボス停止
# ==================================================

func stop_enemy() -> void:

	print("山口ボス：攻撃停止")

	# 停止
	is_stopped = true

	# 攻撃停止
	is_poison_attack = false

	# Timer停止
	if is_instance_valid(poison_timer):
		poison_timer.stop()

	# 色を戻す
	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE
