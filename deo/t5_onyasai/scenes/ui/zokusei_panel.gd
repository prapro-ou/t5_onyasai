extends Panel

@onready var katana_card: TextureRect = $KatanaCard
@onready var horse_card: TextureRect = $HorseCard
@onready var bow_card: TextureRect = $BowCard


func _ready() -> void:
	show_all_cards()


# =========================
# マウスが乗ったとき
# =========================

func _on_katana_button_mouse_entered() -> void:
	show_only_card(katana_card)


func _on_horse_button_mouse_entered() -> void:
	show_only_card(horse_card)


func _on_bow_button_mouse_entered() -> void:
	show_only_card(bow_card)


# =========================
# マウスが離れたとき
# =========================

func _on_katana_button_mouse_exited() -> void:
	show_all_cards()


func _on_horse_button_mouse_exited() -> void:
	show_all_cards()


func _on_bow_button_mouse_exited() -> void:
	show_all_cards()


# =========================
# 3枚表示
# =========================

func show_all_cards() -> void:
	katana_card.visible = true
	horse_card.visible = true
	bow_card.visible = true


# =========================
# 1枚だけ表示
# =========================

func show_only_card(card: TextureRect) -> void:
	katana_card.visible = false
	horse_card.visible = false
	bow_card.visible = false

	card.visible = true
