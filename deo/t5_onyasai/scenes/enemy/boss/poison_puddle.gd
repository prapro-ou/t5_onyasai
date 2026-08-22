extends Area2D


# ==================================================
# 設定
# ==================================================

# 毒沼が存在する時間
@export var life_time: float = 5.0

# ダメージ
@export var damage: int = 1

# ダメージ間隔
@export var damage_interval: float = 1.0


# ==================================================
# 状態
# ==================================================

var player_inside := false
var player: Node2D = null


# ==================================================
# ノード
# ==================================================

@onready var damage_timer: Timer = $DamageTimer


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	# Playerが入った
	body_entered.connect(_on_body_entered)

	# Playerが出た
	body_exited.connect(_on_body_exited)

	# ダメージタイマー
	damage_timer.wait_time = damage_interval

	damage_timer.timeout.connect(_on_damage_timer_timeout)


	# ------------------------------------------
	# 一定時間後に毒沼を消す
	# ------------------------------------------

	get_tree().create_timer(life_time).timeout.connect(_on_life_time_timeout)


# ==================================================
# Playerが入った
# ==================================================

func _on_body_entered(body: Node2D) -> void:

	if not body.is_in_group("player"):
		return

	player = body

	player_inside = true

	# すぐにダメージ
	if player.has_method("take_damage"):
		player.take_damage(damage)

	# 一定間隔でダメージ
	damage_timer.start()


# ==================================================
# Playerが出た
# ==================================================

func _on_body_exited(body: Node2D) -> void:

	if body != player:
		return

	player_inside = false

	player = null

	damage_timer.stop()


# ==================================================
# 継続ダメージ
# ==================================================

func _on_damage_timer_timeout() -> void:

	if not player_inside:
		return

	if not is_instance_valid(player):
		damage_timer.stop()
		return

	if player.has_method("take_damage"):
		player.take_damage(damage)


# ==================================================
# 毒沼の寿命終了
# ==================================================

func _on_life_time_timeout() -> void:

	damage_timer.stop()

	queue_free()
