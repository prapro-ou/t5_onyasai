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

	# ------------------------------------------
	# 左右キーによる選択移動（相互循環）の設定
	# ------------------------------------------
	# リトライ：左右どちらを押しても TitleButton へ
	retry_button.focus_neighbor_left = retry_button.get_path_to(title_button)
	retry_button.focus_neighbor_right = retry_button.get_path_to(title_button)

	# タイトル：左右どちらを押しても RetryButton へ
	title_button.focus_neighbor_left = title_button.get_path_to(retry_button)
	title_button.focus_neighbor_right = title_button.get_path_to(retry_button)

	# 画面表示時に「リトライボタン」にフォーカスを当てる（1フレーム遅らせて確実に適用）
	call_deferred("_set_initial_focus")

func _set_initial_focus() -> void:
	retry_button.grab_focus()

func _on_retry_button_pressed() -> void:
	retry_button.disabled = true
	# 効果音を鳴らす
	retry_se.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1.0).timeout
	# メインゲーム画面を再読み込みしてリトライ
	get_tree().change_scene_to_file("res://scenes/main/yamaguti_stage.tscn")

func _on_title_button_pressed() -> void:
	title_button.disabled = true
	# 効果音を鳴らす
	title_se.play()
	# 1秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(1.0).timeout
	# ステージ選択画面へ移動
	get_tree().change_scene_to_file("res://scenes/mori-mi/stage_select.tscn")
