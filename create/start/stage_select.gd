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
	preload("res://Gemini_Generated_Image_a8tgita8tgita8tg.jpg"),
	preload("res://Gemini_Generated_Image_taf9vqtaf9vqtaf9.png"),
	preload("res://Gemini_Generated_Image_ae3kngae3kngae3k.png"),
	preload("res://Gemini_Generated_Image_tmxzyytmxzyytmxz.png")
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

	match selected_stage:
		0:
			get_tree().change_scene_to_file("res://tottori.tscn")

		1:
			get_tree().change_scene_to_file("res://shimane.tscn")

		2:
			get_tree().change_scene_to_file("res://yamaguchi.tscn")

		3:
			get_tree().change_scene_to_file("res://hiroshima.tscn")
