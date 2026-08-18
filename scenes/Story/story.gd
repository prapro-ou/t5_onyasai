extends Node2D

var story_index := 0

var stories = [
	"ある日、一人の戦士が鬼退治へと立ち上がった。",
	"こうして、鬼との戦いが始まった。"
]

@onready var story_text: RichTextLabel = $CanvasLayer/UI/StoryText

var is_typing := false
var skip_typing := false

func _ready() -> void:
	show_story()


func show_story() -> void:
	is_typing = true
	skip_typing = false

	story_text.text = stories[story_index]
	story_text.visible_characters = 0

	for i in range(stories[story_index].length()):
		if skip_typing:
			break

		story_text.visible_characters = i + 1
		await get_tree().create_timer(0.05).timeout

	story_text.visible_characters = stories[story_index].length()
	is_typing = false


func _on_nextbutton_pressed() :
	# 文字表示中なら、一気に全文表示
	if is_typing:
		skip_typing = true
		return
	
	story_index += 1
	
	if story_index >= stories.size():
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	else:
		show_story()

func _on_skipbutton_pressed() :
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
