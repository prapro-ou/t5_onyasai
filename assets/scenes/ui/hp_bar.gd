extends Control

# HP部分（緑色）のColorRectを取得
@onready var fill: ColorRect = $Fill

# HPバーの最大幅を保存する変数
var full_width: float


func _ready() -> void:
	# HPバー全体の横幅を取得
	full_width = size.x

	# ゲーム開始時は満タンで表示
	fill.size.x = full_width


func set_hp(current_hp: int, max_hp: int) -> void:
	# 最大HPが0以下の場合は何もしない
	if max_hp <= 0:
		return

	# HPの割合を計算
	# 例：現在HPが2、最大HPが4なら 2/4 = 0.5
	var hp_ratio := float(current_hp) / float(max_hp)

	# HP割合を0～1の範囲に制限
	hp_ratio = clamp(hp_ratio, 0.0, 1.0)

	# HP割合に応じて緑色バーの横幅を変更
	fill.size.x = full_width * hp_ratio
