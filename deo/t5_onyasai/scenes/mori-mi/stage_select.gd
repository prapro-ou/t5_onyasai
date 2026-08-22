extends Control

var selected_stage := 0

@onready var stages = [
	$tottori,
	$shimane,
	$yamaguchi,
	$hiroshima
]

@onready var stage_image = $stage_image

var stage_images = [
	preload("res://gazou/mori-mi_gazou/Gemini_Generated_Image_a8tgita8tgita8tg.jpg"),
	preload("res://gazou/mori-mi_gazou/shimaneselect.jpg"),
	preload("res://gazou/mori-mi_gazou/yamagutiselect.jpg"),
	preload("res://gazou/mori-mi_gazou/hiroshimaselect.jpg")
]


func _ready() -> void:
	update_selection()


func _process(_delta: float) -> void:

	if Input.is_action_just_pressed("ui_down"):
		selected_stage += 1

		if selected_stage >= stages.size():
			selected_stage = 0

		update_selection()


	if Input.is_action_just_pressed("ui_up"):
		selected_stage -= 1

		if selected_stage < 0:
			selected_stage = stages.size() - 1

		update_selection()


	if Input.is_action_just_pressed("ui_accept"):
		select_stage()


func update_selection() -> void:

	# ステージ名の表示
	for i in range(stages.size()):
		if i == selected_stage:
			stages[i].text = "> " + stages[i].name
		else:
			stages[i].text = "  " + stages[i].name

	# 画像を変更
	stage_image.texture = stage_images[selected_stage]


func select_stage() -> void:
	# 効果音を再生
	$AudioStreamPlayer.play()
	
	# 0.15秒待ってからシーン移動（音の出だしを鳴らしてスムーズに遷移）
	await get_tree().create_timer(0.15).timeout

	match selected_stage:
		0:
			get_tree().change_scene_to_file("res://scenes/main/main.tscn")

		1:
			get_tree().change_scene_to_file("res://scenes/main/shimane_stage.tscn")

		2:
			get_tree().change_scene_to_file("res://scenes/main/yamaguti_stage.tscn")

		3:
			get_tree().change_scene_to_file("res://scenes/main/yamaguti_stage.tscn")
