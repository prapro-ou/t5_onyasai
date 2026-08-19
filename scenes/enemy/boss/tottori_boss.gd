extends "res://scenes/enemy/enemy.gd"


# ==================================================
# 砂嵐関連
# ==================================================

@onready var sandstorm_timer: Timer = $SandstormTimer
@onready var duration_timer: Timer = $DurationTimer


# 砂嵐本体
@onready var sandstorm_effect: CanvasLayer = $SandstormEffect
@onready var sand_overlay: ColorRect = $SandstormEffect/SandOverlay
@onready var sand_particles: GPUParticles2D = $SandstormEffect/SandParticles


# ==================================================
# 砂嵐の状態
# ==================================================

# 砂嵐中か
var is_sandstorm := false

# 前兆中か
var is_warning := false



# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	super._ready()
	# Playerを取得
	player = get_tree().get_first_node_in_group("player")

	# 砂嵐関係を初期状態にする
	sandstorm_effect.visible = false
	sand_overlay.visible = false
	sand_particles.emitting = false


	# Timerのシグナル
	sandstorm_timer.timeout.connect(start_sandstorm)
	duration_timer.timeout.connect(end_sandstorm)

	# 砂嵐タイマー開始
	sandstorm_timer.start()


# ==================================================
# 砂嵐開始
# ==================================================

func start_sandstorm() -> void:

	# すでに砂嵐中・前兆中なら何もしない
	if is_sandstorm or is_warning:
		return

	is_warning = true

	print("砂嵐の前兆！")


	# ------------------------------------------
	# ボスが白く点滅
	# ------------------------------------------

	await white_flash()

	if not is_instance_valid(self):
		return


	# ------------------------------------------
	# 前兆の砂を出す
	# ------------------------------------------

	


	# 2秒間前兆
	await get_tree().create_timer(2.0).timeout

	if not is_instance_valid(self):
		return


	# 前兆終了
	is_warning = false
	


	# ------------------------------------------
	# 砂嵐開始
	# ------------------------------------------

	is_sandstorm = true

	print("砂嵐発生！")


	# 砂嵐画面を表示
	sandstorm_effect.visible = true
	sand_overlay.visible = true


	# 砂粒を最初から発生
	sand_particles.restart()
	sand_particles.emitting = true


	# ------------------------------------------
	# 砂嵐持続時間開始
	# ------------------------------------------

	duration_timer.start()


# ==================================================
# ボスの白い点滅
# ==================================================

func white_flash() -> void:

	for i in range(3):

		sprite.modulate = Color(3.0, 3.0, 3.0)

		await get_tree().create_timer(0.12).timeout


		sprite.modulate = Color.WHITE

		await get_tree().create_timer(0.12).timeout


	sprite.modulate = Color.WHITE


# ==================================================
# 砂嵐終了
# ==================================================

func end_sandstorm() -> void:

	# 砂嵐中でなければ何もしない
	if not is_sandstorm:
		return


	is_sandstorm = false


	# ------------------------------------------
	# 砂粒停止
	# ------------------------------------------

	sand_particles.emitting = false

	# 次回のために初期状態へ
	sand_particles.restart()


	# ------------------------------------------
	# 砂嵐画面を消す
	# ------------------------------------------

	sand_overlay.visible = false
	sandstorm_effect.visible = false


	print("砂嵐終了")


	# ------------------------------------------
	# 次の砂嵐まで待つ
	# ------------------------------------------

	sandstorm_timer.start()
