extends Node2D

# Wave 1で出現させる青鬼のシーン
@export var blue_enemy_scene: PackedScene

# Wave 2から出現させる黄色鬼のシーン
@export var yellow_enemy_scene: PackedScene

# Wave 3から出現させる赤鬼のシーン
@export var red_enemy_scene: PackedScene

# Mainの子ノードであるSpawnTimerを取得する
@onready var spawn_timer: Timer = $SpawnTimer

# 現在のWave
# ゲーム開始時はWave 1から始める
var current_wave: int = 1

# Wave 1で倒した青鬼の数
var blue_kill_count: int = 0

# Wave 2へ進むために必要な青鬼の撃破数
const BLUE_KILLS_TO_WAVE_2: int = 2

# Wave 2で倒した敵の数
var wave_2_kill_count: int = 0

# Wave 3へ進むために必要な撃破数
const KILLS_TO_WAVE_3: int = 2


func _ready() -> void:
	# SpawnTimerの待ち時間が終了したら、
	# spawn_enemy関数を実行する
	spawn_timer.timeout.connect(spawn_enemy)
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


# 敵を生成する処理
func spawn_enemy() -> void:
	# 今回生成する敵シーンを入れる変数
	var scene_to_spawn: PackedScene

	# 現在のWaveによって生成する敵を変更する
	if current_wave == 1:
		# Wave 1では青鬼だけを生成する
		scene_to_spawn = blue_enemy_scene


	elif current_wave == 2:
		# Wave 2では青鬼と黄色鬼のどちらかを生成する
		var random_value := randf()

		# 70%の確率で青鬼を生成する
		if random_value < 0.7:
			scene_to_spawn = blue_enemy_scene

		# 30%の確率で黄色鬼を生成する
		else:
			scene_to_spawn = yellow_enemy_scene


	else:
		# Wave 3では青鬼・黄色鬼・赤鬼のどれかを生成する
		var random_value := randf()

		# 50%の確率で青鬼を生成する
		if random_value < 0.5:
			scene_to_spawn = blue_enemy_scene

		# 30%の確率で黄色鬼を生成する
		elif random_value < 0.8:
			scene_to_spawn = yellow_enemy_scene

		# 20%の確率で赤鬼を生成する
		else:
			scene_to_spawn = red_enemy_scene

	# 敵シーンが設定されていない場合は処理を終了する
	if scene_to_spawn == null:
		push_warning("敵シーンが設定されていません。")
		return

	# playerグループからプレイヤーを取得する
	var player := get_tree().get_first_node_in_group("player")

	# プレイヤーが見つからない場合は処理を終了する
	if player == null:
		push_warning("playerグループにプレイヤーが見つかりません。")
		return

	# 選ばれた敵シーンから敵を生成する
	var enemy := scene_to_spawn.instantiate()

	# 敵をMainの子ノードとして追加する
	add_child(enemy)

	# プレイヤーの周囲からランダムな方向を選ぶ
	var angle := randf_range(0.0, TAU)

	# プレイヤーから敵が出現するまでの距離
	var spawn_distance := 500.0

	# プレイヤーから見た敵の出現位置を計算する
	var spawn_offset := Vector2.RIGHT.rotated(angle) * spawn_distance

	# 敵をプレイヤーの周囲に配置する
	enemy.global_position = player.global_position + spawn_offset

	# 敵が倒されたときに_on_enemy_died関数を実行する
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)
	else:
		push_warning("生成した敵にdiedシグナルがありません。")


# 敵が倒されたときに呼ばれる処理
func _on_enemy_died() -> void:
	# 現在がWave 1の場合
	if current_wave == 1:
		# 青鬼の撃破数を1増やす
		blue_kill_count += 1

		print(
			"Wave 1 青鬼撃破数：",
			blue_kill_count,
			"/",
			BLUE_KILLS_TO_WAVE_2
		)

		# 必要な数の青鬼を倒したらWave 2へ進む
		if blue_kill_count >= BLUE_KILLS_TO_WAVE_2:
			current_wave = 2

			print("Wave 2開始：青鬼に加えて黄色鬼も出現します")


	# 現在がWave 2の場合
	elif current_wave == 2:
		# 青鬼でも黄色鬼でも撃破数を1増やす
		wave_2_kill_count += 1

		print(
			"Wave 2 撃破数：",
			wave_2_kill_count,
			"/",
			KILLS_TO_WAVE_3
		)

		# 必要な数の敵を倒したらWave 3へ進む
		if wave_2_kill_count >= KILLS_TO_WAVE_3:
			current_wave = 3

			print("Wave 3開始：青鬼と黄色鬼に加えて赤鬼も出現します")


	# Wave 3の場合
	else:
		print("Wave 3の敵を倒しました")
