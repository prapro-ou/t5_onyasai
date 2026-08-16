extends Node2D


# ==================================================
# 敵シーン
# ==================================================

# 青鬼
@export var blue_enemy_scene: PackedScene

# 黄色鬼
@export var yellow_enemy_scene: PackedScene

# 赤鬼
@export var red_enemy_scene: PackedScene


# ==================================================
# 子ノード
# ==================================================

# 敵を出現させるTimer
@onready var spawn_timer: Timer = $SpawnTimer

# Playerシーン内の実際のCharacterBody2D
@onready var player = $Player/Player

# ゲーム開始時の属性選択画面
@onready var attribute_select_ui = $AttributeSelectUI

# BGM
@onready var bgm: AudioStreamPlayer2D = $BGM


# ==================================================
# Wave設定
# ==================================================

# 現在のWave
# ゲーム開始時はWave1
var current_wave: int = 1


# --------------------------
# Wave1
# --------------------------

# Wave1で倒した青鬼の数
var blue_kill_count: int = 0

# Wave2へ進むために必要な撃破数
const BLUE_KILLS_TO_WAVE_2: int = 2

# Wave1の敵出現間隔
const WAVE_1_SPAWN_TIME: float = 4.0


# --------------------------
# Wave2
# --------------------------

# Wave2で倒した敵の数
var wave_2_kill_count: int = 0

# Wave3へ進むために必要な撃破数
const KILLS_TO_WAVE_3: int = 2

# Wave2の敵出現間隔
const WAVE_2_SPAWN_TIME: float = 4.0


# --------------------------
# Wave3
# --------------------------

# Wave3の敵出現間隔
const WAVE_3_SPAWN_TIME: float = 3.5


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	# SpawnTimerが0になったら敵を生成する
	spawn_timer.timeout.connect(spawn_enemy)

	# Wave1の敵出現間隔を設定する
	spawn_timer.wait_time = WAVE_1_SPAWN_TIME

	# 属性を選択するまでは敵を出現させない
	spawn_timer.stop()

	# 属性を選択するまではPlayerを動かさない
	player.prepare_for_attribute_selection()

	# 属性選択画面を表示する
	attribute_select_ui.show()





	# Playerが死亡したときゲームオーバー処理を実行する
	player.died.connect(game_over)


# ==================================================
# ゲームオーバー
# ==================================================

func game_over() -> void:
	print("ゲームオーバー")

	# BGMを停止
	bgm.stop()

	# 新しい敵を出現させない
	spawn_timer.stop()

	# 少し待つ
	await get_tree().create_timer(0.7).timeout

	# Playerが倒れる音を再生
	$Player/Player/GameOverSound.play()

	# 現在存在している敵を停止する
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("stop_enemy"):
			enemy.stop_enemy()

	# 少し待つ
	await get_tree().create_timer(0.7).timeout

	# ゲームオーバー画面を表示
	$GameOver.show_game_over()



# ==================================================
# 敵の生成
# ==================================================

func spawn_enemy() -> void:
	# 今回生成する敵シーン
	var scene_to_spawn: PackedScene

	# 現在のWaveによって出現する敵を決める
	match current_wave:

		# --------------------------
		# Wave1
		# --------------------------
		1:
			# 青鬼のみ
			scene_to_spawn = blue_enemy_scene

		# --------------------------
		# Wave2
		# --------------------------
		2:
			var random_value := randf()

			# 青鬼：70%
			if random_value < 0.7:
				scene_to_spawn = blue_enemy_scene

			# 黄色鬼：30%
			else:
				scene_to_spawn = yellow_enemy_scene

		# --------------------------
		# Wave3
		# --------------------------
		3:
			var random_value := randf()

			# 青鬼：50%
			if random_value < 0.5:
				scene_to_spawn = blue_enemy_scene

			# 黄色鬼：30%
			elif random_value < 0.8:
				scene_to_spawn = yellow_enemy_scene

			# 赤鬼：20%
			else:
				scene_to_spawn = red_enemy_scene

		# 想定していないWave
		_:
			push_warning("存在しないWaveです: " + str(current_wave))
			return

	# 敵シーンが設定されていなければ終了
	if scene_to_spawn == null:
		push_warning("敵シーンが設定されていません。")
		return

	# Playerが存在しなければ終了
	if player == null:
		push_warning("Playerが見つかりません。")
		return

	# 敵を生成
	var enemy := scene_to_spawn.instantiate()

	# Mainの子ノードとして追加
	add_child(enemy)

	# Playerの周囲からランダムな方向を決める
	var angle := randf_range(0.0, TAU)

	# Playerから敵を出現させる距離
	var spawn_distance: float = 500.0

	# Playerから見た敵の出現位置
	var spawn_offset := Vector2.RIGHT.rotated(angle) * spawn_distance

	# 敵をPlayerの周囲に配置
	enemy.global_position = player.global_position + spawn_offset

	# 敵が倒されたときのシグナルを接続
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		push_warning("生成した敵にdiedシグナルがありません。")


# ==================================================
# 敵を倒したとき
# ==================================================

func _on_enemy_died() -> void:
	match current_wave:

		# --------------------------
		# Wave1
		# --------------------------
		1:
			blue_kill_count += 1

			print(
				"Wave1 青鬼撃破数：",
				blue_kill_count,
				"/",
				BLUE_KILLS_TO_WAVE_2
			)

			# 必要数を倒したらWave2へ
			if blue_kill_count >= BLUE_KILLS_TO_WAVE_2:
				start_wave_2()

		# --------------------------
		# Wave2
		# --------------------------
		2:
			wave_2_kill_count += 1

			print(
				"Wave2 撃破数：",
				wave_2_kill_count,
				"/",
				KILLS_TO_WAVE_3
			)

			# 必要数を倒したらWave3へ
			if wave_2_kill_count >= KILLS_TO_WAVE_3:
				start_wave_3()

		# --------------------------
		# Wave3
		# --------------------------
		3:
			print("Wave3の敵を倒しました")


# ==================================================
# Wave切り替え
# ==================================================

# Wave2を開始
func start_wave_2() -> void:
	current_wave = 2

	# 敵の出現間隔を変更
	spawn_timer.wait_time = WAVE_2_SPAWN_TIME

	print("Wave2開始：青鬼に加えて黄色鬼も出現します")


# Wave3を開始
func start_wave_3() -> void:
	current_wave = 3

	# 敵の出現間隔を変更
	spawn_timer.wait_time = WAVE_3_SPAWN_TIME

	print("Wave3開始：青鬼と黄色鬼に加えて赤鬼も出現します")


# ==================================================
# 属性選択
# ==================================================

# 「刀」ボタン
func _on_katana_button_pressed() -> void:

	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()


	# Playerを刀属性にする
	player.select_katana()

	# ゲーム開始
	start_game_after_attribute_selection()


# 「弓」ボタン
func _on_bow_button_pressed() -> void:

	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()


	# Playerを弓属性にする
	player.select_bow()

	# ゲーム開始
	start_game_after_attribute_selection()


# 「騎馬」ボタン
func _on_horse_button_pressed() -> void:
	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()

	# Playerを騎馬属性にする
	player.select_horse()

	# ゲーム開始
	start_game_after_attribute_selection()


# ==================================================
# ゲーム開始
# ==================================================

# 属性選択後にゲームを開始する
func start_game_after_attribute_selection() -> void:
	# 属性選択画面を非表示
	attribute_select_ui.hide()

	# Playerの移動・攻撃を開始
	player.start_gameplay()

	# 敵の出現を開始
	spawn_timer.start()
