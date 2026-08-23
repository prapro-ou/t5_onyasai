extends Node2D


# ==================================================
# 敵シーン
# ==================================================

# 青鬼
@export var blue_enemy_scene: PackedScene
@export var blue_enemy4島根_scene: PackedScene
# 黄色鬼
@export var yellow_enemy_scene: PackedScene
@export var yellow_enemy4島根_scene: PackedScene
# 赤鬼
@export var red_enemy_scene: PackedScene
@export var red_enemy4島根_scene: PackedScene
# 島根ボス
@export var shimane_boss_scene: PackedScene

# ここから追加
# レベルアップ画面
@export var level_up_scene: PackedScene
# ここまで


# ==================================================
# 子ノード
# ==================================================

# 敵を出現させるTimer
@onready var spawn_timer: Timer = $SpawnTimer

# Playerシーン内の実際のCharacterBody2D
@onready var player = $Player/Player

# ゲーム開始時の属性選択画面
@onready var attribute_select_ui = $AttributeSelectUI

# ==================================================
# ステージUI
# ==================================================
#UIの可視化
@onready var shimane_stage_ui = $StageUI
#Waveのラベル更新
@onready var wave_label: Label = $StageUI/WaveBoard/Wave

# ==================================================
# Wave設定
# ==================================================

# 現在のWave
var current_wave: int = 1


# ==================================================
# Wave1
# ==================================================

# Wave1で倒した青鬼の数
var blue_kill_count: int = 0

# Wave2へ進むために必要な撃破数
const BLUE_KILLS_TO_WAVE_2: int = 15

# Wave1の敵出現間隔
const WAVE_1_SPAWN_TIME: float = 0.7


# ==================================================
# Wave2
# ==================================================

# Wave2で倒した敵の数
var wave_2_kill_count: int = 0

# Wave3へ進むために必要な撃破数
const KILLS_TO_WAVE_3: int = 16

# Wave2の敵出現間隔
const WAVE_2_SPAWN_TIME: float = 0.3


# ==================================================
# Wave3
# ==================================================

# Wave3で倒した敵の数
var wave_3_kill_count: int = 0

# 島根ボス出現に必要な撃破数
const KILLS_TO_SHIMANE_BOSS: int = 8

# Wave3の敵出現間隔
const WAVE_3_SPAWN_TIME: float = 0.8


# ここから追加
# ==================================================
# レベルアップ
# ==================================================

# レベルアップ用の撃破数
var level_up_kill_count: int = 0

# レベルアップ画面を表示中か
var is_level_up: bool = false

# 次のレベルに必要な撃破数を計算
# 次のレベルに必要な撃破数を計算
func get_required_kills(target_level: int) -> int:
	# 指定した必要撃破数リスト (Lv1→2: 5体, Lv2→3: 7体, ...)
	var kill_table: Array[int] = [5, 7, 8, 10, 15, 5, 12, 14, 5, 8, 14, 8, 10, 10, 10]
	
	var index := target_level - 1
	
	# リストの範囲内であればその数値を返す
	if index >= 0 and index < kill_table.size():
		return kill_table[index]
	
	# リストの範囲を超えた高レベル時は最後の値(10)を返す
	return kill_table[-1]
	
# ここまで

# ==================================================
# 島根ボス
# ==================================================

# 島根ボスが出現済みか
var shimane_boss_spawned: bool = false


# ==================================================
# ゲーム状態
# ==================================================

# ゲームオーバーになったか
var is_game_over: bool = false

# ステージクリアになったか
var is_stage_clear: bool = false


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	#Wave更新
	wave_label.text = "WAVE " + str(current_wave)

	# ------------------------------------------
	# SpawnTimer
	# ------------------------------------------

	if not spawn_timer.timeout.is_connected(spawn_enemy):
		spawn_timer.timeout.connect(spawn_enemy)

	# Wave1の敵出現間隔
	spawn_timer.wait_time = WAVE_1_SPAWN_TIME

	# 属性選択までは敵を出現させない
	spawn_timer.stop()


	# ------------------------------------------
	# Player
	# ------------------------------------------

	# 属性選択まではPlayerを動かさない
	player.prepare_for_attribute_selection()


	# ------------------------------------------
	# 属性選択画面
	# ------------------------------------------

	attribute_select_ui.show()

	# Panel -> VBoxContainer -> 各ボタン の順で指定
	var katana_btn = attribute_select_ui.get_node("Panel/VBoxContainer/KatanaButton")
	var bow_btn = attribute_select_ui.get_node("Panel/VBoxContainer/BowButton")
	var horse_btn = attribute_select_ui.get_node("Panel/VBoxContainer/HorseButton")

	# 上下キー移動のループ（循環）を設定
	katana_btn.focus_neighbor_top = horse_btn.get_path()
	katana_btn.focus_neighbor_bottom = bow_btn.get_path()

	bow_btn.focus_neighbor_top = katana_btn.get_path()
	bow_btn.focus_neighbor_bottom = horse_btn.get_path()

	horse_btn.focus_neighbor_top = bow_btn.get_path()
	horse_btn.focus_neighbor_bottom = katana_btn.get_path()

	# 最初に刀ボタンを選択状態にする
	katana_btn.grab_focus()


	# ------------------------------------------
	# Player死亡シグナル
	# ------------------------------------------

	if not player.died.is_connected(game_over):
		player.died.connect(game_over)


# ==================================================
# ゲームオーバー
# ==================================================

func game_over() -> void:

	# すでにゲームオーバーなら何もしない
	if is_game_over:
		return

	# クリア済みなら何もしない
	if is_stage_clear:
		return

	is_game_over = true

	print("ゲームオーバー")


	# ------------------------------------------
	# BGM、UI停止
	# ------------------------------------------

	$BGM.stop()
	# 島根ステージUIを非表示する
	shimane_stage_ui.visible = false


	# ------------------------------------------
	# 新しい敵を出さない
	# ------------------------------------------

	spawn_timer.stop()


	# ------------------------------------------
	# Playerの攻撃停止
	# ------------------------------------------

	if player.has_node("AttackTimer"):
		player.get_node("AttackTimer").stop()


	# ------------------------------------------
	# 現在存在する敵を停止
	# ------------------------------------------

	for enemy in get_tree().get_nodes_in_group("enemy"):

		if enemy.has_method("stop_enemy"):
			enemy.stop_enemy()


	# ------------------------------------------
	# 少し待つ
	# ------------------------------------------

	await get_tree().create_timer(0.7).timeout


	# ------------------------------------------
	# ゲームオーバー音
	# ------------------------------------------

	if is_instance_valid(player):

		if player.has_node("GameOverSound"):
			player.get_node("GameOverSound").play()


	# ------------------------------------------
	# 少し待つ
	# ------------------------------------------

	await get_tree().create_timer(0.7).timeout


	# ------------------------------------------
	# ゲームオーバー画面
	# ------------------------------------------

	if is_instance_valid($GameOver):
		$GameOver.show_game_over()


# ==================================================
# 敵の生成
# ==================================================

func spawn_enemy() -> void:

	# ゲームオーバー後は生成しない
	if is_game_over:
		return

	# ステージクリア後は生成しない
	if is_stage_clear:
		return

	# 島根ボス出現後は通常敵を生成しない
	if shimane_boss_spawned:
		return

	# ここから追加
	# レベルアップ中は生成しない
	if is_level_up:
		return
	# ここまで

	# ------------------------------------------
	# 今回生成する敵シーン
	# ------------------------------------------

	var scene_to_spawn: PackedScene


	# ------------------------------------------
	# Waveによって敵を決める
	# ------------------------------------------

	match current_wave:

		# ==========================================
		# Wave1 (青鬼: 40%, 島根青鬼: 60%)
		# ==========================================
		1:
			var random_value := randf()

			# 青鬼 40%
			if random_value < 0.4:
				scene_to_spawn = blue_enemy_scene
			# 島根青鬼 60%
			else:
				scene_to_spawn = blue_enemy4島根_scene


		# ==========================================
		# Wave2 (青鬼: 15%, 黄色鬼: 35%, 島根黄色鬼: 50%)
		# ==========================================
		2:
			var random_value := randf()

			# 青鬼 15%
			if random_value < 0.15:
				scene_to_spawn = blue_enemy_scene
			# 黄色鬼 35% (0.15 〜 0.50)
			elif random_value < 0.5:
				scene_to_spawn = yellow_enemy_scene
			# 島根黄色鬼 50% (0.50 〜 1.0)
			else:
				scene_to_spawn = yellow_enemy4島根_scene


		# ==========================================
		# Wave3 (赤鬼: 30%, 黄色鬼: 10%, 島根赤鬼: 60%)
		# ==========================================
		3:
			var random_value := randf()

			# 赤鬼 30%
			if random_value < 0.3:
				scene_to_spawn = red_enemy_scene
			# 黄色鬼 10% (0.30 〜 0.40)
			elif random_value < 0.4:
				scene_to_spawn = yellow_enemy_scene
			# 島根赤鬼 60% (0.40 〜 1.0)
			else:
				scene_to_spawn = red_enemy4島根_scene
		# ==========================================
		# その他
		# ==========================================

		_:

			push_warning(
				"存在しないWaveです: "
				+ str(current_wave)
			)

			return


	# ------------------------------------------
	# 敵シーン確認
	# ------------------------------------------

	if scene_to_spawn == null:

		push_warning(
			"敵シーンが設定されていません。"
		)

		return


	# ------------------------------------------
	# Player確認
	# ------------------------------------------

	if player == null:
		push_warning("Playerが見つかりません。")
		return


	# ------------------------------------------
	# 敵生成
	# ------------------------------------------

	var enemy := scene_to_spawn.instantiate()

	add_child(enemy)


	# ------------------------------------------
	# Playerの周囲にランダム生成
	# ------------------------------------------

	var angle := randf_range(0.0, TAU)

	var spawn_distance: float = 500.0

	var spawn_offset := (
		Vector2.RIGHT.rotated(angle)
		* spawn_distance
	)


	enemy.global_position = (
		player.global_position
		+ spawn_offset
	)


	# ------------------------------------------
	# 敵死亡シグナル
	# ------------------------------------------

	if enemy.has_signal("died"):

		enemy.died.connect(_on_enemy_died)

	else:

		push_warning(
			"生成した敵にdiedシグナルがありません。"
		)


# ==================================================
# 敵を倒したとき
# ==================================================

func _on_enemy_died() -> void:

	# ゲームオーバー後は処理しない
	if is_game_over:
		return

	# ステージクリア後は処理しない
	if is_stage_clear:
		return


	# ここから追加
	# ------------------------------------------
	# レベルアップ判定
	# ------------------------------------------

	level_up_kill_count += 1

	var required_kills: int = get_required_kills(GameManager.level)

	print(
	"レベルアップ用撃破数：",
	level_up_kill_count,
	"/",
	required_kills
)

	if level_up_kill_count >= required_kills and not is_level_up:

		level_up_kill_count -= required_kills

		open_level_up()
	# ここまで
	match current_wave:


		# ==========================================
		# Wave1
		# ==========================================

		1:

			blue_kill_count += 1

			print(
				"Wave1 青鬼撃破数：",
				blue_kill_count,
				"/",
				BLUE_KILLS_TO_WAVE_2
			)


			# 5体倒したらWave2
			if blue_kill_count >= BLUE_KILLS_TO_WAVE_2:

				start_wave_2()

		# ==========================================
		# Wave2
		# ==========================================

		2:

			wave_2_kill_count += 1

			print(
				"Wave2 撃破数：",
				wave_2_kill_count,
				"/",
				KILLS_TO_WAVE_3
			)


			# 5体倒したらWave3
			if wave_2_kill_count >= KILLS_TO_WAVE_3:

				start_wave_3()


		# ==========================================
		# Wave3
		# ==========================================

		3:

			wave_3_kill_count += 1

			print(
				"Wave3 撃破数：",
				wave_3_kill_count,
				"/",
				KILLS_TO_SHIMANE_BOSS
			)


			# 5体倒したら鳥取ボス
			if wave_3_kill_count >= KILLS_TO_SHIMANE_BOSS:

				# ここが重要
				# Physics処理が終わってからボスを生成する
				call_deferred("spawn_tottori_boss")


# ここから追加
# ==================================================
# レベルアップ画面
# ==================================================

func open_level_up() -> void:

	# すでにレベルアップ中なら何もしない
	if is_level_up:
		return

	# LevelUpシーンが設定されているか確認
	if level_up_scene == null:

		push_warning(
			"LevelUpシーンが設定されていません。"
		)

		return


	# ------------------------------------------
	# レベルアップ状態
	# ------------------------------------------

	is_level_up = true


	# ------------------------------------------
	# LevelUp画面を生成
	# ------------------------------------------

	var level_up = level_up_scene.instantiate()


	# ------------------------------------------
	# Pause中でもLevelUp画面だけ動かす
	# ------------------------------------------

	level_up.process_mode = Node.PROCESS_MODE_WHEN_PAUSED


	# ------------------------------------------
	# Mainに追加
	# ------------------------------------------

	add_child(level_up)


	# ------------------------------------------
	# 現在のレベルを表示
	# ------------------------------------------

	if level_up.has_method("set_level"):

		level_up.set_level(
			GameManager.level + 1
		)


	# ------------------------------------------
	# 強化選択シグナルを接続
	# ------------------------------------------

	if level_up.has_signal("upgrade_selected"):

		level_up.upgrade_selected.connect(
			_on_upgrade_selected
		)


	# ------------------------------------------
	# ゲーム世界全体を完全停止
	# ------------------------------------------

	get_tree().paused = true


# ==================================================
# 強化を選択したとき
# ==================================================

func _on_upgrade_selected(
	upgrade_type: String
) -> void:

	print(
		"強化選択：",
		upgrade_type
	)
	
	# ------------------------------------------
	# 強化を選択したタイミングでレベルアップ
	# ------------------------------------------

	GameManager.level_up()


	# ------------------------------------------
	# Playerへ強化を反映
	# ------------------------------------------

	apply_player_upgrades()


	# ------------------------------------------
	# レベルアップ状態を解除
	# ------------------------------------------

	is_level_up = false


	# ------------------------------------------
	# ゲーム世界を再開
	# ------------------------------------------

	get_tree().paused = false
	$AttributeSelectUI/ClickSound.play()


# ==================================================
# Playerへ強化を反映
# ==================================================

func apply_player_upgrades() -> void:

	# ------------------------------------------
	# HP
	# ------------------------------------------

	player.max_hp = (
		10
		+ GameManager.hp_bonus
	)

	# 最大HPまで回復
	player.current_hp = player.max_hp

	# HPバー更新
	player.hp_bar.set_hp(
		player.current_hp,
		player.max_hp
	)


	# ------------------------------------------
	# 移動速度
	# ------------------------------------------

	player.katana_move_speed = (
		200.0
		+ GameManager.speed_bonus
	)

	player.bow_move_speed = (
		140.0
		+ GameManager.speed_bonus
	)

	player.horse_move_speed = (
		300.0
		+ GameManager.speed_bonus
	)


	# ------------------------------------------
	# 確認用
	# ------------------------------------------

	print("==============================")
	print("Player強化反映")
	print("最大HP：", player.max_hp)
	print(
		"攻撃力Bonus：",
		GameManager.attack_bonus
	)
	print(
		"刀速度：",
		player.katana_move_speed
	)
	print(
		"弓速度：",
		player.bow_move_speed
	)
	print(
		"騎馬速度：",
		player.horse_move_speed
	)
	print("==============================")

# ここまで

# ==================================================
# Wave2開始
# ==================================================

func start_wave_2() -> void:

	# すでにWave2以降なら何もしない
	if current_wave >= 2:
		return


	current_wave = 2
	
	#wavelabel更新
	wave_label.text = "WAVE " + str(current_wave)

	# Wave2の敵出現間隔
	spawn_timer.wait_time = WAVE_2_SPAWN_TIME


	print("==============================")
	print("Wave2開始")
	print("青鬼＋黄色鬼が出現します")
	print("==============================")


# ==================================================
# Wave3開始
# ==================================================

func start_wave_3() -> void:

	# すでにWave3なら何もしない
	if current_wave >= 3:
		return


	current_wave = 3
	
	#wavelabel更新
	wave_label.text = "WAVE " + str(current_wave)

	# Wave3の敵出現間隔
	spawn_timer.wait_time = WAVE_3_SPAWN_TIME


	print("==============================")
	print("Wave3開始")
	print("青鬼＋黄色鬼＋赤鬼が出現します")
	print("==============================")


# ==================================================
# 鳥取ボス生成
# ==================================================

func spawn_tottori_boss() -> void:

	# ゲームオーバーなら生成しない
	if is_game_over:
		return

	# ステージクリアなら生成しない
	if is_stage_clear:
		return

	# すでにボスが出現しているなら何もしない
	if shimane_boss_spawned:
		return


	# ------------------------------------------
	# ボスシーン確認
	# ------------------------------------------

	if shimane_boss_scene == null:

		push_warning(
			"鳥取ボスのシーンが設定されていません。"
		)

		return


	# ------------------------------------------
	# ボス出現済みにする
	# ------------------------------------------

	shimane_boss_spawned = true


	# ------------------------------------------
	# 通常敵の生成停止
	# ------------------------------------------

	spawn_timer.stop()


	print("==============================")
	print("Wave3終了")
	print("通常敵の生成停止")
	print("島根ボス出現！")
	print("==============================")


	# ------------------------------------------
	# ボス生成
	# ------------------------------------------

	var boss := shimane_boss_scene.instantiate()

	add_child(boss)


	# ------------------------------------------
	# Playerの周囲にボスを出現
	# ------------------------------------------

	var angle := randf_range(0.0, TAU)

	var spawn_distance: float = 500.0

	var spawn_offset := (
		Vector2.RIGHT.rotated(angle)
		* spawn_distance
	)


	boss.global_position = (
		player.global_position
		+ spawn_offset
	)


	# ------------------------------------------
	# ボス死亡シグナル
	# ------------------------------------------

	if boss.has_signal("died"):

		boss.died.connect(
			_on_shimane_boss_died
		)

	else:

		push_warning(
			"島根ボスにdiedシグナルがありません。"
		)


# ==================================================
# 鳥取ボス撃破
# ==================================================

func _on_shimane_boss_died() -> void:

	# ゲームオーバーならクリアしない
	if is_game_over:
		return

	# すでにクリアしているなら何もしない
	if is_stage_clear:
		return


	is_stage_clear = true


	print("==============================")
	print("島根ボス撃破！")
	print("島根ステージクリア！")
	print("==============================")


	# ------------------------------------------
	# 敵生成停止
	# ------------------------------------------

	spawn_timer.stop()


	# ------------------------------------------
	# Player停止
	# ------------------------------------------

	player.set_physics_process(false)


	# ------------------------------------------
	# Playerの自動攻撃停止
	# ------------------------------------------

	if player.has_node("AttackTimer"):

		player.get_node("AttackTimer").stop()


	# ------------------------------------------
	# ステージクリア
	# ------------------------------------------

	call_deferred("stage_clear")


# ==================================================
# ステージクリア
# ==================================================

func stage_clear() -> void:

	print("ステージクリア！")
	await get_tree().create_timer(2).timeout


	# クリアシーンへ移動
	get_tree().change_scene_to_file(
		"res://scenes/mori-mi/game_clear_s.tscn"
	)


# ==================================================
# 属性選択
# ==================================================

# ------------------------------------------
# 刀
# ------------------------------------------

func _on_katana_button_pressed() -> void:

	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()

	# Playerを刀属性
	player.select_katana()

	# ゲーム開始
	start_game_after_attribute_selection()


# ------------------------------------------
# 弓
# ------------------------------------------

func _on_bow_button_pressed() -> void:

	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()

	# Playerを弓属性
	player.select_bow()

	# ゲーム開始
	start_game_after_attribute_selection()


# ------------------------------------------
# 騎馬
# ------------------------------------------

func _on_horse_button_pressed() -> void:

	# ボタンクリック音
	$AttributeSelectUI/ClickSound.play()

	# Playerを騎馬属性
	player.select_horse()

	# ゲーム開始
	start_game_after_attribute_selection()


# ==================================================
# ゲーム開始
# ==================================================

func start_game_after_attribute_selection() -> void:

	# 属性選択画面を非表示
	attribute_select_ui.hide()


	# Playerの移動・攻撃開始
	player.start_gameplay()


	# 敵の出現開始
	spawn_timer.start()
	
	# 島根ステージUIを表示する
	shimane_stage_ui.visible = true
