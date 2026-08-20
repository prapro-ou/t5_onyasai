extends "res://scenes/enemy/enemy.gd"


# ==================================================
# 攻撃タイプ
# ==================================================

enum AttackType {
	MOMIJI,
	WAVE,
	OKONOMIYAKI
}


# 現在の攻撃
var current_attack: AttackType = AttackType.MOMIJI

# 属性
var enemy_zukusei = "red"

# ==================================================
# 攻撃用Timer
# ==================================================

@onready var attack_timer: Timer = $AttackTimer
@onready var duration_timer: Timer = $DurationTimer


# ==================================================
# 紅葉関連
# ==================================================

@onready var momiji_effect: CanvasLayer = $MomijiEffect

@onready var momiji_overlay: ColorRect = \
	$MomijiEffect/MomijiOverlay

@onready var momiji_particles: GPUParticles2D = \
	$MomijiEffect/MomijiParticles


# ==================================================
# Wave関連
# ==================================================

@onready var warning_line: Line2D = $WarningLine

@export var wave_scene: PackedScene

var wave_direction := Vector2.RIGHT


# ==================================================
# お好み焼き関連
# ==================================================

@export var okonomiyaki_scene: PackedScene


# ==================================================
# 状態
# ==================================================

# 紅葉中
var is_momiji := false

# 攻撃の前兆中
var is_warning := false

# 攻撃中
var is_attacking := false

# Boss停止中
var is_stopped := false


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	# ==================================================
	# BossのHPを2倍
	# ==================================================

	max_hp = max_hp * 2

	super._ready()


	# ==================================================
	# Player取得
	# ==================================================

	player = get_tree().get_first_node_in_group("player")


	# ==================================================
	# Bossグループ
	# ==================================================

	add_to_group("boss")


	# ==================================================
	# 紅葉初期化
	# ==================================================

	momiji_effect.visible = false

	momiji_overlay.visible = false

	momiji_particles.emitting = false


	# ==================================================
	# Wave初期化
	# ==================================================

	warning_line.visible = false

	warning_line.clear_points()


	# ==================================================
	# Timerシグナル
	# ==================================================

	if not attack_timer.timeout.is_connected(start_next_attack):
		attack_timer.timeout.connect(start_next_attack)


	if not duration_timer.timeout.is_connected(end_momiji):
		duration_timer.timeout.connect(end_momiji)


	# ==================================================
	# 最初の攻撃
	# ==================================================

	current_attack = AttackType.MOMIJI

	start_momiji()


# ==================================================
# 次の攻撃
# ==================================================

func start_next_attack() -> void:

	if is_stopped:
		return


	if is_attacking:
		return


	# ==================================================
	# 攻撃を切り替える
	# ==================================================

	match current_attack:

		AttackType.MOMIJI:
			current_attack = AttackType.WAVE


		AttackType.WAVE:
			current_attack = AttackType.OKONOMIYAKI


		AttackType.OKONOMIYAKI:
			current_attack = AttackType.MOMIJI


	# ==================================================
	# 攻撃実行
	# ==================================================

	match current_attack:

		AttackType.MOMIJI:

			print("広島Boss：紅葉嵐")

			start_momiji()


		AttackType.WAVE:

			print("広島Boss：Wave")

			start_wave_attack()


		AttackType.OKONOMIYAKI:

			print("広島Boss：お好み焼き")

			start_okonomiyaki()


# ==================================================
# 紅葉嵐
# ==================================================

func start_momiji() -> void:

	if is_stopped:
		return


	if is_attacking:
		return


	is_attacking = true
	is_warning = true


	print("紅葉嵐の前兆！")


	# ==================================================
	# Boss白点滅
	# ==================================================

	await white_flash()


	if is_stopped or not is_instance_valid(self):

		is_warning = false
		is_attacking = false

		return


	# ==================================================
	# 前兆時間
	# ==================================================

	await get_tree().create_timer(2.0).timeout


	if is_stopped or not is_instance_valid(self):

		is_warning = false
		is_attacking = false

		return


	# ==================================================
	# 前兆終了
	# ==================================================

	is_warning = false


	# ==================================================
	# 紅葉開始
	# ==================================================

	is_momiji = true

	print("紅葉嵐発生！")
	$MomijiSound.play()


	# ==================================================
	# 紅葉表示
	# ==================================================

	momiji_effect.visible = true

	momiji_overlay.visible = true


	# ==================================================
	# 紅葉パーティクル開始
	# ==================================================

	momiji_particles.restart()

	momiji_particles.emitting = true


	# ==================================================
	# 紅葉持続
	# ==================================================

	duration_timer.start()


# ==================================================
# 紅葉終了
# ==================================================

func end_momiji() -> void:

	if not is_momiji:
		return


	is_momiji = false


	# ==================================================
	# 紅葉停止
	# ==================================================

	momiji_particles.emitting = false

	momiji_particles.restart()


	# ==================================================
	# 紅葉エフェクト消去
	# ==================================================

	momiji_overlay.visible = false

	momiji_effect.visible = false


	print("紅葉嵐終了")
	$MomijiSound.stop()


	# ==================================================
	# 攻撃終了
	# ==================================================

	is_attacking = false


	# ==================================================
	# 次の攻撃まで待つ
	# ==================================================

	if not is_stopped:

		attack_timer.start()


# ==================================================
# Wave攻撃
# ==================================================

func start_wave_attack() -> void:

	if is_stopped:
		return


	if is_attacking:
		return


	is_attacking = true
	is_warning = true


	print("Wave攻撃の前兆！")


	# ==================================================
	# 攻撃方向決定
	# ==================================================

	var directions := [
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.DOWN
	]


	wave_direction = directions.pick_random()


	print("Wave方向：", wave_direction)


	# ==================================================
	# 予告ライン
	# ==================================================

	show_warning_line()


	# ==================================================
	# 1秒前兆
	# ==================================================

	await get_tree().create_timer(1.0).timeout


	if is_stopped or not is_instance_valid(self):

		is_warning = false
		is_attacking = false

		return


	# ==================================================
	# 前兆終了
	# ==================================================

	is_warning = false

	warning_line.visible = false


	# ==================================================
	# Wave生成
	# ==================================================

	spawn_wave()


	print("Wave発生！")
	$WaveSound.play()


	# ==================================================
	# 攻撃終了
	# ==================================================

	is_attacking = false


	# ==================================================
	# 次の攻撃まで待つ
	# ==================================================

	if not is_stopped:

		attack_timer.start()


# ==================================================
# Wave予告ライン
# ==================================================

func show_warning_line() -> void:

	warning_line.clear_points()


	# ==================================================
	# Bossの位置から開始
	# ==================================================

	warning_line.add_point(Vector2.ZERO)

	warning_line.add_point(Vector2.ZERO)


	# ==================================================
	# 最初は細く
	# ==================================================

	warning_line.width = 10.0

	warning_line.visible = true


	# ==================================================
	# Tween
	# ==================================================

	var tween := create_tween()

	tween.set_parallel(true)


	# ==================================================
	# 長さ
	# ==================================================

	tween.tween_method(
		func(length):

			if is_instance_valid(warning_line):

				warning_line.set_point_position(
					1,
					wave_direction * length
				),

		0.0,
		1000.0,
		1.0
	)


	# ==================================================
	# 太さ
	# ==================================================

	tween.tween_property(
		warning_line,
		"width",
		50.0,
		1.0
	)


# ==================================================
# Wave生成
# ==================================================

func spawn_wave() -> void:

	if wave_scene == null:

		print("Waveシーンが設定されていません。")

		return


	# ==================================================
	# Wave生成
	# ==================================================

	var wave = wave_scene.instantiate()


	get_tree().current_scene.add_child(wave)


	# ==================================================
	# Boss位置から生成
	# ==================================================

	wave.global_position = global_position


	# ==================================================
	# Wave方向設定
	# ==================================================

	wave.setup(wave_direction)


	print("広島Boss：Wave生成")


# ==================================================
# 毒攻撃
# ==================================================

func start_okonomiyaki() -> void:

	if is_stopped:
		return


	if is_attacking:
		return


	is_attacking = true
	is_warning = true


	print("毒攻撃の前兆！")
	$WaveSound.stop()
	


	# ==================================================
	# Boss白点滅
	# ==================================================

	await white_flash()


	if is_stopped or not is_instance_valid(self):

		is_warning = false
		is_attacking = false

		return


	# ==================================================
	# Bossの位置を保存
	# ==================================================

	var spawn_position := global_position


	# ==================================================
	# 少し待つ
	# ==================================================

	await get_tree().create_timer(0.5).timeout


	if is_stopped or not is_instance_valid(self):

		is_warning = false
		is_attacking = false

		return


	# ==================================================
	# 前兆終了
	# ==================================================

	is_warning = false


	# ==================================================
	# お好み焼き生成
	# ==================================================

	spawn_okonomiyaki(spawn_position)


	# ==================================================
	# 攻撃終了
	# ==================================================

	is_attacking = false


	# ==================================================
	# 次の攻撃まで待つ
	# ==================================================

	if not is_stopped:

		attack_timer.start()


# ==================================================
# お好み焼き生成
# ==================================================

func spawn_okonomiyaki(spawn_position: Vector2) -> void:

	if okonomiyaki_scene == null:

		print("毒沼シーンが設定されていません。")

		return


	# ==================================================
	# シーン生成
	# ==================================================

	var okonomiyaki = okonomiyaki_scene.instantiate()


	get_tree().current_scene.add_child(okonomiyaki)


	# ==================================================
	# Bossがいた場所に生成
	# ==================================================

	okonomiyaki.global_position = spawn_position


	print("毒沼生成！")
	$PoisonSound.play()


# ==================================================
# Boss白点滅
# ==================================================

func white_flash() -> void:

	for i in range(3):

		if is_stopped:
			return


		# 白くする

		sprite.modulate = Color(
			3.0,
			3.0,
			3.0
		)


		await get_tree().create_timer(0.12).timeout


		if is_stopped:
			return


		# 元に戻す

		sprite.modulate = Color.WHITE


		await get_tree().create_timer(0.12).timeout


	sprite.modulate = Color.WHITE


# ==================================================
# Boss停止
# ==================================================

func stop_enemy() -> void:

	print("広島Boss：攻撃停止")


	# ==================================================
	# 停止
	# ==================================================

	is_stopped = true

	is_attacking = false
	is_warning = false
	is_momiji = false


	# ==================================================
	# Timer停止
	# ==================================================

	attack_timer.stop()
	duration_timer.stop()


	# ==================================================
	# 紅葉停止
	# ==================================================

	momiji_particles.emitting = false

	momiji_particles.restart()

	momiji_overlay.visible = false

	momiji_effect.visible = false


	# ==================================================
	# Wave予告停止
	# ==================================================

	warning_line.visible = false

	warning_line.clear_points()


	# ==================================================
	# Bossの点滅を解除
	# ==================================================

	if is_instance_valid(sprite):

		sprite.modulate = Color.WHITE
