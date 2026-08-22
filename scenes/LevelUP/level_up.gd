extends Control


# ==================================================
# シグナル
# ==================================================

signal upgrade_selected(upgrade_type: String)


# ==================================================
# ノード
# ==================================================

@onready var level_label: Label = $Background/Panel/VBoxContainer/LevelLabel

@onready var hp_button: Button = $Background/Panel/VBoxContainer/HPButton

@onready var attack_button: Button = $Background/Panel/VBoxContainer/AttackButton

@onready var speed_button: Button = $Background/Panel/VBoxContainer/SpeedButton


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:

	# ゲーム全体がPause中でもLevelUp画面だけ操作可能にする
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	set_level(GameManager.level)


# ==================================================
# レベル表示
# ==================================================

func set_level(new_level: int) -> void:

	level_label.text = "LEVEL " + str(new_level)


# ==================================================
# 体力UP
# ==================================================

func _on_hp_button_pressed() -> void:

	GameManager.apply_upgrade("hp")

	upgrade_selected.emit("hp")

	close()


# ==================================================
# 攻撃力UP
# ==================================================

func _on_attack_button_pressed() -> void:

	GameManager.apply_upgrade("attack")

	upgrade_selected.emit("attack")

	close()


# ==================================================
# 移動速度UP
# ==================================================

func _on_speed_button_pressed() -> void:

	GameManager.apply_upgrade("speed")

	upgrade_selected.emit("speed")

	close()


# ==================================================
# 閉じる
# ==================================================

func close() -> void:

	queue_free()
