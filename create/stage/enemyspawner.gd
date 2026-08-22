extends Node2D

# インスペクターから敵のシーン（.tscn）を登録できるようにする
@export var enemy_scenes: Array[PackedScene] = []

# スポーン範囲の指定（画面のサイズに合わせて調整してください）
@export var spawn_area_min: Vector2 = Vector2(100, 100)
@export var spawn_area_max: Vector2 = Vector2(1100, 600)

@onready var timer = $Timer

func _ready() -> void:
	# タイマー終了時にスポーン処理を実行するシグナルを接続
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	if enemy_scenes.is_empty():
		return
	
	# 配列の中からランダムに敵の種類のシーンを選ぶ
	var random_index = randi() % enemy_scenes.size()
	var selected_scene = enemy_scenes[random_index]
	
	# 敵インスタンスの生成
	var enemy = selected_scene.instantiate()
	
	# ランダムな位置の計算
	var random_x = randf_range(spawn_area_min.x, spawn_area_max.x)
	var random_y = randf_range(spawn_area_min.y, spawn_area_max.y)
	enemy.position = Vector2(random_x, random_y)
	
	# 親シーン（tottoriステージなど）に追加
	add_child(enemy)
