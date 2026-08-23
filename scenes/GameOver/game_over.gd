extends CanvasLayer

@onready var screen: Control = $Screen
@onready var fade: ColorRect = $Screen/Fade
@onready var panel: Control = $Screen/GameOverPanel
@onready var game_over_label: Label = $Screen/GameOverPanel/GameOverLabel
@onready var bgm: AudioStreamPlayer2D = $BGM
@onready var retry_sound: AudioStreamPlayer2D = $RetrySound
@onready var title_sound: AudioStreamPlayer2D = $TitleSound

# 追加：ボタンノードの取得
@onready var retry_button: Button = $Screen/GameOverPanel/RetryButton
@onready var title_button: Button = $Screen/GameOverPanel/TitleButton

func _ready() -> void:
	visible = false

	# ------------------------------------------
	# 左右キーによる選択移動（相互循環）の設定
	# ------------------------------------------
	retry_button.focus_neighbor_left = retry_button.get_path_to(title_button)
	retry_button.focus_neighbor_right = retry_button.get_path_to(title_button)

	title_button.focus_neighbor_left = title_button.get_path_to(retry_button)
	title_button.focus_neighbor_right = title_button.get_path_to(retry_button)

	# 上下キー無効化
	retry_button.focus_neighbor_top = retry_button.get_path()
	retry_button.focus_neighbor_bottom = retry_button.get_path()
	title_button.focus_neighbor_top = title_button.get_path()
	title_button.focus_neighbor_bottom = title_button.get_path()


func show_game_over() -> void:
	visible = true
	
	
	#BGM開始
	bgm.play()
	# 画面の高さ分だけ上に移動
	screen.position.y = -get_viewport().get_visible_rect().size.y
	
	# 上から降ろす
	var tween := create_tween()
	
	tween.tween_property(
		screen,
		"position:y",
		0.0,
		0.8
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	#画面が降りてきてから少し待つ
	tween.tween_interval(0.4)
	
# GAME OVERとボタンを表示
	tween.tween_property(
		panel,
		"modulate:a",
		1.0,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 表示アニメーション完了後にRetryButtonにフォーカスを当てる
	tween.tween_callback(func(): retry_button.grab_focus())


func _on_retry_button_pressed() -> void:
	#BGM止める
	bgm.stop()
	#ボタンクリック音
	retry_sound.play()
	#音がなってから画像読み込み
	await get_tree().create_timer(1).timeout
	#Mainへ
	get_tree().reload_current_scene()


func _on_title_button_pressed() -> void:
	#BGM止める
	bgm.stop()
	#ボタンクリック音
	title_sound.play()
	#音がなってから画像読み込み
	await get_tree().create_timer(1).timeout
	# 遷移先のタイトル画面のパスを指定してください
	get_tree().change_scene_to_file("res://scenes/mori-mi/start.tscn")
