extends Control

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var title_button: Button = $VBoxContainer/TitleButton

# 追加：音用ノードの取得
@onready var retry_se: AudioStreamPlayer = $RetrySE
@onready var title_se: AudioStreamPlayer = $TitleSE

func _ready() -> void:
	# ボタンの押し込みイベントを接続
	retry_button.pressed.connect(_on_retry_button_pressed)
	title_button.pressed.connect(_on_title_button_pressed)

func _on_retry_button_pressed() -> void:
	# 効果音を鳴らす
	retry_se.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1).timeout
	# メインゲーム画面を再読み込みしてリトライ
	get_tree().change_scene_to_file("res://scenes/main/main_stage.tscn")

func _on_title_button_pressed() -> void:
	# 効果音を鳴らす
	title_se.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1).timeout
	# ステージ選択画面へ移動
	get_tree().change_scene_to_file("res://scenes/mori-mi/stage_select.tscn")
