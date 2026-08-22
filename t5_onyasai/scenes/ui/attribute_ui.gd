extends Control

@onready var attribute_image: TextureRect = $TextureRect

@export var red_texture: Texture2D
@export var yellow_texture: Texture2D
@export var blue_texture: Texture2D


func _ready() -> void:
	attribute_image.visible = false


func update_attribute(attribute: String) -> void:
	match attribute:
		"red":
			attribute_image.texture = red_texture
			attribute_image.visible = true

		"yellow":
			attribute_image.texture = yellow_texture
			attribute_image.visible = true

		"blue":
			attribute_image.texture = blue_texture
			attribute_image.visible = true

		_:
			attribute_image.visible = false
