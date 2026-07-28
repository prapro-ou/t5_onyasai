extends Node2D

# Wave 1で出現させる青鬼のシーン
@export var blue_enemy_scene: PackedScene

# Wave 2で出現させる黄色鬼のシーン
@export var yellow_enemy_scene: PackedScene

# Mainの子ノードであるSpawnTimerを取得する
@onready var spawn_timer: Timer = $SpawnTimer

# 現在のWave
# ゲーム開始時はWave 1から始める
var current_wave: int = 1

# Wave 1で倒した青鬼の数
var blue_kill_count: int = 0

# Wave 2へ進むために必要な青鬼の撃破数
const BLUE_KILLS_TO_WAVE_2: int = 3


func _ready() -> void:
	# SpawnTimerの待ち時間が終わったら、
	# spawn_enemy関数を呼び出す
	spawn_timer.timeout.connect(spawn_enemy)


# 敵を生成する処理
func spawn_enemy() -> void:
	# 今回生成する敵シーンを入れる変数
	var scene_to_spawn: PackedScene

	# 現在のWaveによって生成する敵を変更する
	if current_wave == 1:
		# Wave 1では青鬼だけを生成する
		scene_to_spawn = blue_enemy_scene

	else:
		# Wave 2では青鬼と黄色鬼のどちらかを選ぶ
		var random_value := randf()

		# random_valueが0.7未満なら青鬼
		# およそ70%の確率で青鬼が選ばれる
		if random_value < 0.7:
			scene_to_spawn = blue_enemy_scene

		# それ以外なら黄色鬼
		# およそ30%の確率で黄色鬼が選ばれる
		else:
			scene_to_spawn = yellow_enemy_scene

	# 敵シーンが設定されていない場合は処理を終了する
	if scene_to_spawn == null:
		push_warning("敵シーンが設定されていません。")
		return

	# playerグループからプレイヤーを取得する
	var player := get_tree().get_first_node_in_group("player")

	# プレイヤーが見つからなければ処理を終了する
	if player == null:
		push_warning("playerグループにプレイヤーが見つかりません。")
		return

	# 選択した敵シーンから敵を生成する
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

	# 敵が倒されたときにMainの関数を呼ぶ
	enemy.died.connect(_on_enemy_died)


# 敵が倒されたときに呼ばれる処理
func _on_enemy_died() -> void:
	# Wave 1のときだけ青鬼の撃破数を数える
	if current_wave == 1:
		# 青鬼の撃破数を1増やす
		blue_kill_count += 1

		# Godot下部の「出力」に撃破数を表示する
		print(
			"青鬼撃破数：",
			blue_kill_count,
			"/",
			BLUE_KILLS_TO_WAVE_2
		)

		# 青鬼を10体倒したか確認する
		if blue_kill_count >= BLUE_KILLS_TO_WAVE_2:
			# 現在のWaveを2に変更する
			current_wave = 2

			# Wave 2になったことを出力する
			print("Wave 2開始：これ以降は黄色鬼が出現します")
