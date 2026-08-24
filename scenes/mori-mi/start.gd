extends Control


# ==================================================
# PRESS ENTER
# ==================================================

@onready var press_enter: Label = $PressEnter


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	start_press_enter_animation()


# ==================================================
# 入力
# ==================================================

func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("ui_accept"):

		# 効果音を再生
		$AudioStreamPlayer.play()

		# 連続でEnterを押せないようにする
		set_process(false)

		# 0.5秒待ってからシーン移動
		await get_tree().create_timer(0.5).timeout

		get_tree().change_scene_to_file(
			"res://scenes/mori-mi/stage_select.tscn"
		)


# ==================================================
# PRESS ENTER アニメーション
# ==================================================

func start_press_enter_animation() -> void:

	var tween = create_tween()

	# 永久に繰り返す
	tween.set_loops()

	# なめらかに変化
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	# 少し薄くなる
	tween.tween_property(
		press_enter,
		"modulate:a",
		0.5,
		0.8
	)

	# 明るくなる
	tween.tween_property(
		press_enter,
		"modulate:a",
		1.0,
		0.8
	)
