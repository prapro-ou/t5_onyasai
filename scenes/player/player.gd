extends CharacterBody2D


# ==================================================
# 攻撃タイプ
# ==================================================

enum AttackType {
	KATANA,
	BOW,
	HORSE
}

# 現在使用している攻撃タイプ
@export var attack_type: AttackType = AttackType.KATANA

# 弓で使用する矢のシーン
@export var arrow_scene: PackedScene


# ==================================================
# 移動設定
# ==================================================

# 刀属性の移動速度
@export var katana_move_speed: float = 200.0

# 弓属性の移動速度
@export var bow_move_speed: float = 140.0

# Playerが最後に移動した方向
# ゲーム開始時は右向き
var last_move_direction: Vector2 = Vector2.RIGHT

# Playerが画面端から離れる距離
@export var screen_margin: float = 30.0


# ==================================================
# 騎馬属性設定
# ==================================================

# 騎馬属性の通常移動速度
@export var horse_move_speed: float = 300.0

# 突進時の速度
@export var horse_dash_speed: float = 650.0

# 突進時間
@export var horse_dash_duration: float = 0.5

# 突進ダメージ
@export var horse_dash_damage: int = 2

# 突進中かどうか
var is_dashing: bool = false

# 突進方向
var dash_direction: Vector2 = Vector2.RIGHT

# 1回の突進ですでに攻撃した敵
var dash_hit_enemies: Array[Node] = []


# ==================================================
# HP設定
# ==================================================

@export var max_hp: int = 10
var current_hp: int

# ==================================================
# 属性設定
# ==================================================

var player_zokusei

# ==================================================
# Playerの状態
# ==================================================

# 刀攻撃中かどうか
var is_attacking: bool = false

# 死亡しているかどうか
var is_dead: bool = false

# Playerが死亡したことをMainへ知らせる
signal died


# ==================================================
# 子ノード
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer
@onready var damage_cooldown: Timer = $DamageCooldown
@onready var hurt_box: Area2D = $HurtBox
@onready var weapon_holder: Node2D = $WeaponHolder
@onready var hp_bar = $HPBar

# 刀の攻撃判定
@onready var katana_collision: CollisionShape2D = (
	$WeaponHolder/KatanaHitBox/CollisionShape2D
)

# 騎馬の攻撃判定
@onready var horse_collision: CollisionShape2D = (
	$HorseHitBox/CollisionShape2D
)

# 効果音
@onready var attack_sound: AudioStreamPlayer2D = $AttackSound
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	# HPを最大HPで初期化
	current_hp = max_hp

	# 刀の攻撃判定を無効化
	katana_collision.disabled = true

	# 騎馬の攻撃判定を無効化
	horse_collision.disabled = true

	# HPバーを初期化
	hp_bar.set_hp(current_hp, max_hp)


# ==================================================
# 毎フレームの処理
# ==================================================

func _physics_process(_delta: float) -> void:
	# 死亡していたら何もしない
	if is_dead:
		return

	# --------------------------
	# 騎馬の突進中
	# --------------------------
	if is_dashing:
		velocity = dash_direction * horse_dash_speed
		move_and_slide()

		# 画面外に出ないようにする
		clamp_to_screen()

		return

	# --------------------------
	# 通常移動
	# --------------------------

	# 入力から移動方向を取得
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	# 移動している場合だけ最後の移動方向を保存
	if direction != Vector2.ZERO:
		last_move_direction = direction.normalized()

	# 現在の属性に応じた速度で移動
	velocity = direction * get_current_move_speed()

	# Playerを移動
	move_and_slide()

	# 画面外に出ないようにする
	clamp_to_screen()

	# アニメーションを更新
	update_animation(direction)

	# 敵との接触を確認
	check_enemy_contact()


# ==================================================
# 画面外への移動防止
# ==================================================

func clamp_to_screen() -> void:
	var screen_size := get_viewport_rect().size

	global_position.x = clamp(
		global_position.x,
		screen_margin,
		screen_size.x - screen_margin
	)

	global_position.y = clamp(
		global_position.y,
		screen_margin,
		screen_size.y - screen_margin
	)


# ==================================================
# 移動速度
# ==================================================

func get_current_move_speed() -> float:
	match attack_type:
		AttackType.KATANA:
			return katana_move_speed

		AttackType.BOW:
			return bow_move_speed

		AttackType.HORSE:
			return horse_move_speed

	# 想定外の場合は刀の速度
	return katana_move_speed


# ==================================================
# アニメーション
# ==================================================

func update_animation(direction: Vector2) -> void:
	# 刀攻撃中は移動アニメーションへ変更しない
	if is_attacking:
		return

	# 騎馬専用アニメーションはまだ未実装
	# 現段階では刀・弓と同じ idle / run を使用する

	# 停止中
	if direction == Vector2.ZERO:
		animated_sprite.play("idle")

	# 移動中
	else:
		animated_sprite.play("run")

	# 左向き
	if direction.x < 0:
		animated_sprite.flip_h = false
		weapon_holder.scale.x = 1.0

	# 右向き
	elif direction.x > 0:
		animated_sprite.flip_h = true
		weapon_holder.scale.x = -1.0


# ==================================================
# 自動攻撃
# ==================================================

func _on_attack_timer_timeout() -> void:
	# 死亡していたら攻撃しない
	if is_dead:
		return

	# 現在選択している属性によって攻撃を変更
	match attack_type:
		AttackType.KATANA:
			attack_with_katana()

		AttackType.BOW:
			attack_with_bow()

		AttackType.HORSE:
			attack_with_horse()


# ==================================================
# 刀攻撃
# ==================================================

func attack_with_katana() -> void:
	# すでに攻撃中なら何もしない
	if is_attacking:
		return

	# 死亡していたら攻撃しない
	if is_dead:
		return

	# 攻撃中にする
	is_attacking = true

	# 刀攻撃アニメーション
	animated_sprite.play("attack")

	# 刀の当たり判定を有効化
	katana_collision.set_deferred("disabled", false)

	# 0.2秒待つ
	await get_tree().create_timer(0.2).timeout

	# Playerが削除されていたら終了
	if not is_inside_tree():
		return

	# 刀の当たり判定を無効化
	katana_collision.set_deferred("disabled", true)


# 刀の攻撃アニメーション終了
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false


# 刀が敵に当たったとき
func _on_katana_hit_box_body_entered(body: Node2D) -> void:
	# 敵でなければ何もしない
	if not body.is_in_group("enemy"):
		return

	# ダメージ処理を持っていなければ何もしない
	if not body.has_method("take_damage"):
		return

	# 攻撃音
	attack_sound.play()

	# 敵にダメージ
	var actual_damage := get_attribute_damage(1, body)
	body.take_damage(actual_damage, global_position)


# ==================================================
# 弓攻撃
# ==================================================

func attack_with_bow() -> void:
	# 死亡していたら攻撃しない
	if is_dead:
		return

	# 矢のシーンが設定されていなければ終了
	if arrow_scene == null:
		push_warning("Arrow Sceneが設定されていません。")
		return

	# 矢を生成
	var arrow := arrow_scene.instantiate()
	
	# Playerの属性を矢に渡す
	arrow.player_zokusei = player_zokusei

	# 現在のステージへ矢を追加
	get_tree().current_scene.add_child(arrow)

	# Playerの位置から矢を出現
	arrow.global_position = global_position

	# 最後に移動した方向とは逆方向へ発射
	var shoot_direction := -last_move_direction

	# 矢の進行方向を設定
	arrow.direction = shoot_direction

	# 矢画像を進行方向へ回転
	arrow.rotation = shoot_direction.angle()


# ==================================================
# 騎馬攻撃
# ==================================================

func attack_with_horse() -> void:
	# 死亡していたら突進しない
	if is_dead:
		return

	# すでに突進中なら何もしない
	if is_dashing:
		return

	# 最後に移動した方向へ突進
	dash_direction = last_move_direction.normalized()

	# 今回攻撃した敵をリセット
	dash_hit_enemies.clear()

	# 突進開始
	is_dashing = true

	# 騎馬専用アニメーションはまだ未実装
	# 現段階では画像・アニメーションの切り替えは行わない

	# 騎馬の攻撃判定をON
	horse_collision.set_deferred("disabled", false)

	# 指定された時間だけ突進
	await get_tree().create_timer(horse_dash_duration).timeout

	# Playerが削除されていたら終了
	if not is_inside_tree():
		return

	# 突進終了
	is_dashing = false

	# 騎馬の攻撃判定をOFF
	horse_collision.set_deferred("disabled", true)


# 騎馬の突進が敵に当たったとき
func _on_horse_hit_box_body_entered(body: Node2D) -> void:
	# 突進中でなければ攻撃しない
	if not is_dashing:
		return

	# 死亡していたら攻撃しない
	if is_dead:
		return

	# 敵でなければ無視
	if not body.is_in_group("enemy"):
		return

	# 同じ突進ですでに攻撃した敵なら無視
	if body in dash_hit_enemies:
		return

	# take_damage()を持っていなければ無視
	if not body.has_method("take_damage"):
		return

	# 今回攻撃済みの敵として記録
	dash_hit_enemies.append(body)
	$HouseSound.play()
	# 敵へダメージ
	var actual_damage := get_attribute_damage(
	horse_dash_damage,
	body
	)
	body.take_damage(
	actual_damage,
	global_position
	)


# ==================================================
# Playerのダメージ処理
# ==================================================

# 敵がHurtBoxに入ったとき
func _on_hurt_box_body_entered(body: Node2D) -> void:
	# 死亡していたらダメージを受けない
	if is_dead:
		return

	# 騎馬の突進中は無敵
	if is_dashing:
		return

	# 敵でなければ何もしない
	if not body.is_in_group("enemy"):
		return

	# ダメージのクールタイム中なら何もしない
	if not damage_cooldown.is_stopped():
		return

	# ダメージを受ける
	take_damage(1)

	# クールタイム開始
	damage_cooldown.start()


# 接触し続けている敵を確認
func check_enemy_contact() -> void:
	# 死亡していたら確認しない
	if is_dead:
		return

	# 騎馬の突進中は無敵
	if is_dashing:
		return

	# クールタイム中なら確認しない
	if not damage_cooldown.is_stopped():
		return

	# HurtBoxに重なっている敵を取得
	var overlapping_bodies := hurt_box.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			take_damage(1)
			damage_cooldown.start()
			break


# Playerがダメージを受ける
func take_damage(damage: int) -> void:
	# 死亡済みなら何もしない
	if is_dead:
		return

	# 騎馬の突進中は無敵
	if is_dashing:
		return

	# HPを減らす
	current_hp -= damage

	# HPが0未満にならないようにする
	current_hp = clamp(current_hp, 0, max_hp)

	# ダメージ音
	damage_sound.play()

	print("プレイヤーの残りHP: ", current_hp)

	# HPバーを更新
	hp_bar.set_hp(current_hp, max_hp)

	# HPが0ならゲームオーバー
	if current_hp <= 0:
		die()


# ==================================================
# 属性選択
# ==================================================

# 刀属性
func select_katana() -> void:
	player_zokusei = "red"
	attack_type = AttackType.KATANA
	#UI変更
	var attribute_ui = get_tree().current_scene.get_node_or_null("TottoriStageUI/AttributeUI")

	if attribute_ui:
		attribute_ui.update_attribute(player_zokusei)

	# 1秒ごとに攻撃
	attack_timer.wait_time = 1.0

	print("属性を刀に変更しました")


# 弓属性
func select_bow() -> void:
	player_zokusei = "yellow"
	attack_type = AttackType.BOW
	#UI変更
	var attribute_ui = get_tree().current_scene.get_node_or_null("TottoriStageUI/AttributeUI")

	if attribute_ui:
		attribute_ui.update_attribute(player_zokusei)

	# 1秒ごとに攻撃
	attack_timer.wait_time = 1.0

	print("属性を弓に変更しました")


# 騎馬属性
func select_horse() -> void:
	player_zokusei = "blue"
	attack_type = AttackType.HORSE
	#UI変更
	var attribute_ui = get_tree().current_scene.get_node_or_null("TottoriStageUI/AttributeUI")

	if attribute_ui:
		attribute_ui.update_attribute(player_zokusei)

	# 騎馬専用アニメーションはまだ未実装
	# 現段階では現在のPlayer画像をそのまま使用する

	# 2秒ごとに突進
	attack_timer.wait_time = 2.0

	print("属性を騎馬に変更しました")

# ==================================================
# 属性による攻撃力の設定
# ==================================================
func get_attribute_damage(base_damage: int, enemy: Node2D) -> int:
	var actual_damage := base_damage

	if "enemy_zokusei" in enemy:
		if player_zokusei == enemy.enemy_zokusei:
			actual_damage *= 2

	return actual_damage
	
	
# ==================================================
# ゲーム開始・停止
# ==================================================

# 属性選択中はPlayerを停止
func prepare_for_attribute_selection() -> void:
	# 移動処理を停止
	set_physics_process(false)

	# 自動攻撃を停止
	attack_timer.stop()


# 属性選択後にPlayerを動かす
func start_gameplay() -> void:
	# 移動処理を開始
	set_physics_process(true)

	# 自動攻撃を開始
	attack_timer.start()


# ==================================================
# ゲームオーバー
# ==================================================

func die() -> void:
	# すでに死亡していたら何もしない
	if is_dead:
		return

	print("ゲームオーバー")

	# 死亡状態にする
	is_dead = true

	# 移動停止
	velocity = Vector2.ZERO

	# 突進停止
	is_dashing = false

	# 刀攻撃状態を解除
	is_attacking = false

	# 刀の攻撃判定をOFF
	katana_collision.set_deferred("disabled", true)

	# 騎馬の攻撃判定をOFF
	horse_collision.set_deferred("disabled", true)

	# 自動攻撃を停止
	attack_timer.stop()

	# Playerの物理処理を停止
	set_physics_process(false)

	# アニメーション停止
	animated_sprite.pause()

	# Mainへゲームオーバーを知らせる
	died.emit()
