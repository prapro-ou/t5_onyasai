extends Control

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var title_button: Button = $VBoxContainer/TitleButton

func _ready() -> void:
	# ボタンの押し込みイベントを接続
	retry_button.pressed.connect(_on_retry_button_pressed)
	title_button.pressed.connect(_on_title_button_pressed)
func _on_retry_button_pressed() -> void:
	# メインゲーム画面を再読み込みしてリトライ
	get_tree().change_scene_to_file("res://tottori.tscn")
func _on_title_button_pressed() -> void:
	# ※ "res://scenes/title/title.tscn" の部分は、実際のタイトルシーンのファイルパスを指定してください
	get_tree().change_scene_to_file("res://stage_select.tscn")
