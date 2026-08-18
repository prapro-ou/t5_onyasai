extends "res://scenes/enemy/enemy.gd"


# ==================================================
# Wave関連
# ==================================================

@onready var wave_timer: Timer = $WaveTimer
@onready var warning_line: Line2D = $WarningLine

# Wave本体
@export var wave_scene: PackedScene


# ==================================================
# Waveの状態
# ==================================================

# Wave攻撃中か
var is_wave_attack := false

# ゲームオーバーなどで停止しているか
var is_stopped := false

# 前兆中か
var is_warning := false

# Waveの方向
var wave_direction := Vector2.RIGHT


# ==================================================
# WarningLineのTween
# ==================================================

var warning_tween: Tween


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	# ボスのHPを設定
	max_hp = max_hp * 2
	current_hp = max_hp
	# 親のenemy.gdの初期化
	super._ready()

	# Playerを取得
	player = get_tree().get_first_node_in_group("player")

	# このボスをenemyグループに登録
	add_to_group("enemy")

	# Wave関係を初期状態にする
	warning_line.visible = false
	warning_line.clear_points()

	# Timerのシグナル
	if not wave_timer.timeout.is_connected(start_wave_attack):
		wave_timer.timeout.connect(start_wave_attack)

	# Waveタイマー開始
	wave_timer.start()


# ==================================================
# Wave攻撃開始
# ==================================================

func start_wave_attack() -> void:

	# ------------------------------------------
	# 停止中なら何もしない
	# ------------------------------------------

	if is_stopped:
		return


	# ------------------------------------------
	# すでに攻撃中・前兆中なら何もしない
	# ------------------------------------------

	if is_wave_attack or is_warning:
		return


	# 前兆開始
	is_warning = true

	print("Wave攻撃の前兆！")


	# ------------------------------------------
	# 攻撃方向を決める
	# ------------------------------------------

	var directions = [
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.DOWN
	]

	wave_direction = directions.pick_random()


	# ------------------------------------------
	# 白いラインを表示
	# ------------------------------------------

	show_warning_line()


	# ------------------------------------------
	# 1秒間前兆
	# ------------------------------------------

	await get_tree().create_timer(1.0).timeout


	# ==================================================
	# 重要
	# 待っている間にゲームオーバーになった場合
	# ==================================================

	if is_stopped:

		is_warning = false

		if is_instance_valid(warning_line):
			warning_line.visible = false

		return


	# Nodeが削除されていた場合
	if not is_instance_valid(self):
		return


	# ------------------------------------------
	# 前兆終了
	# ------------------------------------------

	is_warning = false

	warning_line.visible = false


	# ------------------------------------------
	# Wave開始前にもう一度確認
	# ------------------------------------------

	if is_stopped:
		return


	# ------------------------------------------
	# Wave開始
	# ------------------------------------------

	is_wave_attack = true

	print("Wave発生！")

	spawn_wave()


	# Wave攻撃終了
	is_wave_attack = false


	# ------------------------------------------
	# 次のWaveまで待つ
	# ------------------------------------------

	if is_stopped:
		return


	wave_timer.start()


# ==================================================
# 白い予告ライン
# ==================================================

func show_warning_line() -> void:

	# 停止中なら表示しない
	if is_stopped:
		return


	# ------------------------------------------
	# 以前のTweenを停止
	# ------------------------------------------

	if warning_tween and warning_tween.is_valid():
		warning_tween.kill()


	# ------------------------------------------
	# ラインを初期化
	# ------------------------------------------

	warning_line.clear_points()

	# 最初は敵の位置から長さ0
	warning_line.add_point(Vector2.ZERO)
	warning_line.add_point(Vector2.ZERO)

	# 最初は細くする
	warning_line.width = 10

	# 表示
	warning_line.visible = true


	# ------------------------------------------
	# Tween作成
	# ------------------------------------------

	warning_tween = create_tween()

	warning_tween.set_parallel(true)


	# ------------------------------------------
	# ラインを徐々に長くする
	# ------------------------------------------

	warning_tween.tween_method(
		func(length):

			# ゲームオーバー後なら何もしない
			if is_stopped:
				return

			if not is_instance_valid(warning_line):
				return

			warning_line.set_point_position(
				1,
				wave_direction * length
			),

		0.0,
		1000.0,
		1.0
	)


	# ------------------------------------------
	# ラインを徐々に太くする
	# ------------------------------------------

	warning_tween.tween_property(
		warning_line,
		"width",
		50.0,
		1.0
	)


# ==================================================
# Wave生成
# ==================================================

func spawn_wave() -> void:

	# ------------------------------------------
	# 停止中なら絶対に生成しない
	# ------------------------------------------

	if is_stopped:
		print("ShimaneBoss: Wave生成を中止")
		return


	# ------------------------------------------
	# Waveシーン確認
	# ------------------------------------------

	if wave_scene == null:

		print("Waveシーンが設定されていません。")

		return


	# ------------------------------------------
	# Waveを生成
	# ------------------------------------------

	var wave = wave_scene.instantiate()


	# ------------------------------------------
	# 現在のシーンに追加
	# ------------------------------------------

	get_tree().current_scene.add_child(wave)


	# ------------------------------------------
	# 敵の位置からWaveを発射
	# ------------------------------------------

	wave.global_position = global_position


	# ------------------------------------------
	# Waveの方向とアニメーションを設定
	# ------------------------------------------

	wave.setup(wave_direction)


	print("Waveを生成！")


# ==================================================
# ゲームオーバー時の停止
# ==================================================

func stop_enemy() -> void:

	# ------------------------------------------
	# 最初に停止フラグを立てる
	# ------------------------------------------

	is_stopped = true


	# ------------------------------------------
	# Waveの状態を停止
	# ------------------------------------------

	is_wave_attack = false
	is_warning = false


	# ------------------------------------------
	# WaveTimer停止
	# ------------------------------------------

	if is_instance_valid(wave_timer):

		wave_timer.stop()


	# ------------------------------------------
	# WarningLineのTween停止
	# ------------------------------------------

	if warning_tween and warning_tween.is_valid():

		warning_tween.kill()


	# ------------------------------------------
	# WarningLineを消す
	# ------------------------------------------

	if is_instance_valid(warning_line):

		warning_line.visible = false
		warning_line.clear_points()


# ==================================================
# ボスの白い点滅
# ==================================================

func white_flash() -> void:

	# 停止中なら何もしない
	if is_stopped:
		return


	for i in range(3):

		# 途中でゲームオーバーになった場合
		if is_stopped:
			break


		sprite.modulate = Color(3.0, 3.0, 3.0)

		await get_tree().create_timer(0.12).timeout


		if is_stopped:
			break


		sprite.modulate = Color.WHITE

		await get_tree().create_timer(0.12).timeout


	sprite.modulate = Color.WHITE
