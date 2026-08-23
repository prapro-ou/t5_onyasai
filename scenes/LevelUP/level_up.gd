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

	# ------------------------------------------
	# 上下キーによる選択移動（循環）の設定
	# ------------------------------------------
	# HPButton (一番上)
	hp_button.focus_neighbor_top = hp_button.get_path_to(speed_button)
	hp_button.focus_neighbor_bottom = hp_button.get_path_to(attack_button)

	# AttackButton (真ん中)
	attack_button.focus_neighbor_top = attack_button.get_path_to(hp_button)
	attack_button.focus_neighbor_bottom = attack_button.get_path_to(speed_button)

	# SpeedButton (一番下)
	speed_button.focus_neighbor_top = speed_button.get_path_to(attack_button)
	speed_button.focus_neighbor_bottom = speed_button.get_path_to(hp_button)

	# ------------------------------------------
	# 左右キー移動の無効化（自分自身を指定）
	# ------------------------------------------
	hp_button.focus_neighbor_left = hp_button.get_path()
	hp_button.focus_neighbor_right = hp_button.get_path()
	attack_button.focus_neighbor_left = attack_button.get_path()
	attack_button.focus_neighbor_right = attack_button.get_path()
	speed_button.focus_neighbor_left = speed_button.get_path()
	speed_button.focus_neighbor_right = speed_button.get_path()

	# 初期フォーカスをHPButtonに設定（ポーズ時等の描画タイミング対策で1フレーム遅延）
	call_deferred("_set_initial_focus")


func _set_initial_focus() -> void:
	hp_button.grab_focus()


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
