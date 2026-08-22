extends Control

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var title_button: Button = $VBoxContainer/TitleButton
# 1. 追加するタイトルボタンとSEのノード取得
@onready var title_button_2: Button = $VBoxContainer/TitleButton2

@onready var retry_se: AudioStreamPlayer = $RetrySE
@onready var title_se: AudioStreamPlayer = $TitleSE
@onready var title_se_2: AudioStreamPlayer = $TitleSE

func _ready() -> void:
	# ボタンの押し込みイベントを接続
	retry_button.pressed.connect(_on_retry_button_pressed)
	title_button.pressed.connect(_on_title_button_pressed)
	# 2. 追加したボタンのシグナル接続
	title_button_2.pressed.connect(_on_title_button_2_pressed)

func _on_retry_button_pressed() -> void:
	retry_button.disabled = true
	retry_se.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/main/hiroshima_stage.tscn")

func _on_title_button_pressed() -> void:
	title_button.disabled = true
	title_se.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1).timeout
	get_tree().change_scene_to_file("res://scenes/mori-mi/stage_select.tscn")

# 3. 追加したタイトルボタンの処理関数
func _on_title_button_2_pressed() -> void:
	title_button_2.disabled = true
	# 既存のSE（title_se）を使い回す場合は title_se.play() / await title_se.finished でOKです
	title_se_2.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1).timeout
	# 遷移先のタイトル画面のパスを指定してください
	get_tree().change_scene_to_file("res://scenes/mori-mi/start.tscn")
