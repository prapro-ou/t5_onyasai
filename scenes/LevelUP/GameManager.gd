extends Node

# ==================================================
# プレイヤーの進行状況
# ==================================================

var level: int = 1

# ==================================================
# 強化値
# ==================================================

var hp_bonus: int = 0
var attack_bonus: int = 0
var speed_bonus: float = 0.0


# ==================================================
# レベルアップ
# ==================================================

func level_up() -> void:
	level += 1
	print("★ LEVEL UP! Lv.", level)


# ==================================================
# 強化
# ==================================================

func upgrade_hp() -> void:
	hp_bonus += 2

	print("体力UP: +", hp_bonus)


func upgrade_attack() -> void:
	attack_bonus += 1
	print("攻撃力UP: +", attack_bonus)


func upgrade_speed() -> void:
	speed_bonus += 70
	print("移動速度UP: +", speed_bonus)


func apply_upgrade(upgrade_type: String) -> void:

	match upgrade_type:
		"hp":
			upgrade_hp()

		"attack":
			upgrade_attack()

		"speed":
			upgrade_speed()
			
