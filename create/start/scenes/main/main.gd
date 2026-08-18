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

# 青鬼2（新敵）
@export var blue_enemy2_scene: PackedScene

# 黄色鬼
@export var yellow_enemy2_scene: PackedScene

# 赤鬼
@export var red_enemy2_scene: PackedScene

# ==================================================
# 子ノード
# ==================================================

# 敵を出現させるTimer
@onready var spawn_timer: Timer = $SpawnTimer

# Playerシーン内の実際のCharacterBody2Dを取得する
@onready var player = $Player/Player

# ゲーム開始時の属性選択画面
@onready var attribute_select_ui = $AttributeSelectUI


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

#クリア画面仮実装
var wave_3_kill_count: int = 0
const KILLS_TO_CLEAR: int = 1  # Wave3で倒す数（5体）
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
	
	#ここから追加
	$Player/Player.died.connect(game_over)
	#ここまで


#ここから追加
func game_over()-> void: 
	print("ゲームオーバー")
	#BGMストップ
	$BGM.stop()
	#新しい敵は出さない
	$SpawnTimer.stop()
	#少し待つ
	await get_tree().create_timer(0.7).timeout
	#倒れる音
	$Player/Player/GameOverSound.play()
	#敵を停止
	for enemy in get_tree().get_nodes_in_group("enemy"):
		enemy.stop_enemy()
	#少し待つ
	await get_tree().create_timer(0.7).timeout
	# ゲームオーバー画面を表示
	$GameOver.show_game_over()
#ここまで

# ==================================================
# 敵の生成
# ==================================================

func spawn_enemy() -> void:
	# 今回生成する敵シーン
	var scene_to_spawn: PackedScene

	# 現在のWaveによって出現する敵を決める
	match current_wave:

		# --------------------------
		# Wave1 (青鬼: 70%, 青鬼2: 30%)
		# --------------------------
		1:
			var random_value := randf()

			# 青鬼：70%
			if random_value < 0.7:
				scene_to_spawn = blue_enemy_scene
			# 青鬼2：30%
			else:
				scene_to_spawn = blue_enemy2_scene

		# --------------------------
		# Wave2 (青鬼: 30%, 青鬼2: 15%, 黄鬼: 50%, 黄鬼2: 5%)
		# --------------------------
		2:
			var random_value := randf()

			# 青鬼：30% (0.0 ～ 0.30)
			if random_value < 0.30:
				scene_to_spawn = blue_enemy_scene
			# 青鬼2：15% (0.30 ～ 0.45)
			elif random_value < 0.45:
				scene_to_spawn = blue_enemy2_scene
			# 黄色鬼：50% (0.45 ～ 0.95)
			elif random_value < 0.95:
				scene_to_spawn = yellow_enemy_scene
			# 黄色鬼2：5% (0.95 ～ 1.00)
			else:
				scene_to_spawn = yellow_enemy2_scene

		# --------------------------
		# Wave3 (青鬼2: 5%, 黄鬼: 5%, 黄鬼2: 10%, 赤鬼: 60%, 赤鬼2: 20%)
		# --------------------------
		3:
			var random_value := randf()

			# 青鬼2：5% (0.0 ～ 0.05)
			if random_value < 0.05:
				scene_to_spawn = blue_enemy2_scene
			# 黄色鬼：5% (0.05 ～ 0.10)
			elif random_value < 0.10:
				scene_to_spawn = yellow_enemy_scene
			# 黄色鬼2：10% (0.10 ～ 0.20)
			elif random_value < 0.20:
				scene_to_spawn = yellow_enemy2_scene
			# 赤鬼：60% (0.20 ～ 0.80)
			elif random_value < 0.80:
				scene_to_spawn = red_enemy_scene
			# 赤鬼2：20% (0.80 ～ 1.00)
			else:
				scene_to_spawn = red_enemy2_scene

		# 想定していないWaveの場合
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

	# 敵を生成する
	var enemy := scene_to_spawn.instantiate()

	# Mainの子ノードとして追加する
	add_child(enemy)

	# Playerの周囲からランダムな方向を決める
	var angle := randf_range(0.0, TAU)

	# Playerから敵を出現させる距離
	var spawn_distance: float = 500.0

	# Playerから見た敵の出現位置を計算する
	var spawn_offset := Vector2.RIGHT.rotated(angle) * spawn_distance

	# 敵をPlayerの周囲に配置する
	enemy.global_position = player.global_position + spawn_offset

	# 敵が倒されたときのシグナルを接続する
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		push_warning("生成した敵にdiedシグナルがありません。")


# ==================================================
# 敵を倒したときの処理
# ==================================================

func _on_enemy_died() -> void:
	match current_wave:

		# --------------------------
		# Wave1
		# --------------------------
		1:
			# 青鬼の撃破数を1増やす
			blue_kill_count += 1

			print(
				"Wave1 青鬼撃破数：",
				blue_kill_count,
				"/",
				BLUE_KILLS_TO_WAVE_2
			)

			# 必要な数を倒したらWave2へ
			if blue_kill_count >= BLUE_KILLS_TO_WAVE_2:
				start_wave_2()

		# --------------------------
		# Wave2
		# --------------------------
		2:
			# 青鬼・黄色鬼どちらでも撃破数を1増やす
			wave_2_kill_count += 1

			print(
				"Wave2 撃破数：",
				wave_2_kill_count,
				"/",
				KILLS_TO_WAVE_3
			)

			# 必要な数を倒したらWave3へ
			if wave_2_kill_count >= KILLS_TO_WAVE_3:
				start_wave_3()

		# --------------------------
		# Wave3
		# --------------------------
		3:
			print("Wave3の敵を倒しました")
			wave_3_kill_count += 1

			print(
				"Wave3 撃破数：",
				wave_3_kill_count,
				"/",
				KILLS_TO_CLEAR
			)

			if wave_3_kill_count >= KILLS_TO_CLEAR:
				print("条件達成：game_clear() を呼び出します")
				game_clear()

# ==================================================
# Wave切り替え
# ==================================================

# Wave2を開始する
func start_wave_2() -> void:
	# 現在のWaveを2にする
	current_wave = 2

	# 敵の出現間隔を変更する
	spawn_timer.wait_time = WAVE_2_SPAWN_TIME

	print("Wave2開始：青鬼に加えて黄色鬼も出現します")


# Wave3を開始する
func start_wave_3() -> void:
	# 現在のWaveを3にする
	current_wave = 3

	# 敵の出現間隔を変更する
	spawn_timer.wait_time = WAVE_3_SPAWN_TIME

	print("Wave3開始：青鬼と黄色鬼に加えて赤鬼も出現します")



# ==================================================
# 属性選択
# ==================================================

# 「刀」ボタンを押したとき
func _on_katana_button_pressed() -> void:
	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()
	# Playerを刀属性にする
	player.select_katana()

	# ゲームを開始する
	start_game_after_attribute_selection()


# 「弓」ボタンを押したとき
func _on_bow_button_pressed() -> void:
	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()
	# Playerを弓属性にする
	player.select_bow()

	# ゲームを開始する
	start_game_after_attribute_selection()


# ==================================================
# ゲーム開始
# ==================================================

# 属性選択後にゲームを開始する
func start_game_after_attribute_selection() -> void:
	# 属性選択画面を非表示にする
	attribute_select_ui.hide()

	# Playerの移動・攻撃を開始する
	player.start_gameplay()

	# 敵の出現を開始する
	spawn_timer.start()
	
#クリアシーンへの移行
func game_clear() -> void:
	print("ゲームクリア！")
	
	if spawn_timer:
		spawn_timer.stop()

	# 旧処理（$GameClear.show() など）があれば削除し、シーン遷移のみにする
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/game_clear.tscn")
