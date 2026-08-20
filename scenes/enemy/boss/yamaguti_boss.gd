extends "res://scenes/enemy/enemy.gd"


# ==================================================
# 毒沼関連
# ==================================================

@onready var poison_timer: Timer = $PoisonTimer

@export var poison_puddle_scene: PackedScene


# ==================================================
# 設定
# ==================================================

# 毒沼を生成する距離
@export var spawn_distance: float = 80.0


# 属性
var enemy_zukusei = "red"
# ==================================================
# 状態
# ==================================================

var is_stopped := false


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	super._ready()

	# Player取得
	player = get_tree().get_first_node_in_group("player")

	# enemyグループ
	add_to_group("enemy")

	# Timer
	if not poison_timer.timeout.is_connected(spawn_poison_puddle):
		poison_timer.timeout.connect(spawn_poison_puddle)

	# 毒沼生成開始
	poison_timer.start()


# ==================================================
# 毒沼生成
# ==================================================

func spawn_poison_puddle() -> void:

	# ゲームオーバー後
	if is_stopped:
		return

	# 毒沼シーンがない
	if poison_puddle_scene == null:

		print("毒沼シーンが設定されていません。")

		return


	# Playerがいなければ何もしない
	if not is_instance_valid(player):
		return


	# ------------------------------------------
	# Playerの位置を取得
	# ------------------------------------------

	var spawn_position := player.global_position


	# ------------------------------------------
	# Playerの少し近くに生成
	# ------------------------------------------

	var offset := Vector2(
		randf_range(-spawn_distance, spawn_distance),
		randf_range(-spawn_distance, spawn_distance)
	)

	spawn_position += offset


	# ------------------------------------------
	# 毒沼生成
	# ------------------------------------------

	var poison_puddle = poison_puddle_scene.instantiate()

	get_tree().current_scene.add_child(poison_puddle)

	poison_puddle.global_position = spawn_position


	print("毒沼を生成！")


# ==================================================
# ボス停止
# ==================================================

func stop_enemy() -> void:

	print("山口ボス：攻撃停止")

	is_stopped = true

	poison_timer.stop()
