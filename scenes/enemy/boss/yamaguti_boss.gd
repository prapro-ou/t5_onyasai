extends "res://scenes/enemy/enemy.gd"


# ==================================================
# ボスアニメーション設定
# ==================================================

# 停止アニメーション(default)の大きさ倍率
@export var default_scale_multiplier: float = 1.0

# 移動アニメーション(move)の大きさ倍率
@export var move_scale_multiplier: float = 1.0

# AnimatedSprite2Dの元の大きさ
var base_sprite_scale: Vector2 = Vector2.ONE


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

# ゲームオーバーなどで停止しているか
var is_stopped := false


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	# 親のenemy.gdの初期化
	super._ready()

	# AnimatedSprite2Dの元の大きさを保存
	base_sprite_scale = sprite.scale

	# 最初はdefaultアニメーション
	sprite.scale = (
		base_sprite_scale * default_scale_multiplier
	)
	sprite.play("default")

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
# 毎フレームの処理
# ==================================================

func _physics_process(delta: float) -> void:

	# ------------------------------------------
	# ゲームオーバーなどで停止中
	# ------------------------------------------

	if is_stopped:
		velocity = Vector2.ZERO

		# 停止中はdefault
		sprite.scale = (
			base_sprite_scale * default_scale_multiplier
		)

		if sprite.animation != "default":
			sprite.play("default")

		return


	# ------------------------------------------
	# 親enemy.gdの移動処理
	# ------------------------------------------

	# Player追跡、左右反転、ノックバックなどは
	# enemy.gdの処理をそのまま使用する
	super._physics_process(delta)


	# ------------------------------------------
	# ボスアニメーション更新
	# ------------------------------------------

	update_boss_animation()


# ==================================================
# ボスアニメーション
# ==================================================

func update_boss_animation() -> void:

	# ------------------------------------------
	# 移動中
	# ------------------------------------------

	if velocity.length() > 0.1:

		# move専用サイズ
		sprite.scale = (
			base_sprite_scale * move_scale_multiplier
		)

		# moveアニメーション
		if sprite.animation != "move":
			sprite.play("move")


	# ------------------------------------------
	# 停止中
	# ------------------------------------------

	else:

		# default専用サイズ
		sprite.scale = (
			base_sprite_scale * default_scale_multiplier
		)

		# defaultアニメーション
		if sprite.animation != "default":
			sprite.play("default")


# ==================================================
# 毒沼生成
# ==================================================

func spawn_poison_puddle() -> void:

	# 停止中なら生成しない
	if is_stopped:
		return

	# 毒沼シーンが設定されていない場合
	if poison_puddle_scene == null:
		print("毒沼シーンが設定されていません。")
		return

	# ボス自身の現在位置
	var spawn_position := global_position

	# 毒沼生成
	var poison_puddle = poison_puddle_scene.instantiate()

	# 現在のシーンへ追加
	get_tree().current_scene.add_child(poison_puddle)

	# ボスがいる場所に配置
	poison_puddle.global_position = spawn_position

	print("ボスの位置に毒沼を生成！")

	$PoisonSound.play()


# ==================================================
# ボス停止
# ==================================================

func stop_enemy() -> void:

	print("山口ボス：攻撃停止")

	# 停止状態
	is_stopped = true

	# 移動停止
	velocity = Vector2.ZERO

	# 毒沼生成停止
	if is_instance_valid(poison_timer):
		poison_timer.stop()

	# 停止時はdefaultへ戻す
	if is_instance_valid(sprite):
		sprite.scale = (
			base_sprite_scale * default_scale_multiplier
		)
		sprite.play("default")
