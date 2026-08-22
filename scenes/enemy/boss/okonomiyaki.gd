extends Area2D


# ==================================================
# 設定
# ==================================================

@export var duration: float = 5.0

@export var damage: int = 1


# ==================================================
# ノード
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = \
	$AnimatedSprite2D


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	# ==================================================
	# アニメーション開始
	# ==================================================

	animated_sprite.play("okonomiyaki")


	# ==================================================
	# Playerとの接触
	# ==================================================

	body_entered.connect(_on_body_entered)


	# ==================================================
	# 一定時間後に消える
	# ==================================================

	await get_tree().create_timer(duration).timeout


	if is_instance_valid(self):

		queue_free()


# ==================================================
# Playerに当たった
# ==================================================

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):
		return


	if body.has_method("take_damage"):

		body.take_damage(damage)

		print("お好み焼きがPlayerに命中！")
