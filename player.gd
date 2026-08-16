extends CharacterBody2D


# ==================================================
# 攻撃タイプ
# ==================================================

enum AttackType {
	KATANA,
	BOW
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


# ==================================================
# HP設定
# ==================================================

@export var max_hp: int = 10

var current_hp: int


# ==================================================
# Playerの状態
# ==================================================

# 刀攻撃中かどうか
var is_attacking: bool = false


# ==================================================
# 子ノード
# ==================================================

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var katana_collision: CollisionShape2D = \
	$WeaponHolder/KatanaHitBox/CollisionShape2D

@onready var damage_cooldown: Timer = $DamageCooldown

@onready var hurt_box: Area2D = $HurtBox

@onready var weapon_holder: Node2D = $WeaponHolder

@onready var hp_bar = $HPBar


# ==================================================
# 初期化
# ==================================================

func _ready() -> void:
	# HPを最大HPで初期化する
	current_hp = max_hp

	# ゲーム開始時は刀の当たり判定を無効にする
	katana_collision.disabled = true

	# HPバーを初期化する
	hp_bar.set_hp(current_hp, max_hp)


# ==================================================
# 毎フレームの処理
# ==================================================

func _physics_process(_delta: float) -> void:
	# 入力から移動方向を取得する
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	# 移動している場合だけ最後の移動方向を保存する
	if direction != Vector2.ZERO:
		last_move_direction = direction.normalized()

	# 現在の属性に応じた速度で移動する
	velocity = direction * get_current_move_speed()

	# Playerを実際に移動させる
	move_and_slide()

	# アニメーションを更新する
	update_animation(direction)

	# 敵との接触を確認する
	check_enemy_contact()


# ==================================================
# 移動
# ==================================================

# 現在の攻撃タイプに応じた移動速度を返す
func get_current_move_speed() -> float:
	match attack_type:
		AttackType.KATANA:
			return katana_move_speed

		AttackType.BOW:
			return bow_move_speed

	# 万が一どちらでもない場合
	return katana_move_speed


# ==================================================
# アニメーション
# ==================================================

func update_animation(direction: Vector2) -> void:
	# 刀攻撃中は移動アニメーションへ変更しない
	if is_attacking:
		return

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
	# 現在選択している属性によって攻撃を変更する
	match attack_type:
		# 刀属性
		AttackType.KATANA:
			attack_with_katana()

		# 弓属性
		AttackType.BOW:
			attack_with_bow()


# ==================================================
# 刀攻撃
# ==================================================

func attack_with_katana() -> void:
	# すでに攻撃中なら何もしない
	if is_attacking:
		return

	# 攻撃中にする
	is_attacking = true

	# 刀攻撃アニメーション
	animated_sprite.play("attack")

	# 刀の当たり判定を有効にする
	katana_collision.set_deferred("disabled", false)

	# 0.2秒待つ
	await get_tree().create_timer(0.2).timeout

	# 刀の当たり判定を無効に戻す
	if is_instance_valid(katana_collision):
		katana_collision.set_deferred("disabled", true)


# 刀の攻撃アニメーションが終了したとき
func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false


# 刀が敵に当たったとき
func _on_katana_hit_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(1, global_position)


# ==================================================
# 弓攻撃
# ==================================================

func attack_with_bow() -> void:
	# 矢のシーンが設定されていなければ何もしない
	if arrow_scene == null:
		push_warning("Arrow Sceneが設定されていません。")
		return

	# arrow.tscnから矢を生成する
	var arrow := arrow_scene.instantiate()

	# 現在のステージへ矢を追加する
	get_tree().current_scene.add_child(arrow)

	# Playerの位置から矢を出現させる
	arrow.global_position = global_position

	# 最後に移動した方向とは逆方向へ発射する
	var shoot_direction := -last_move_direction

	# 矢に進行方向を設定する
	arrow.direction = shoot_direction

	# 矢画像を進行方向へ回転させる
	arrow.rotation = shoot_direction.angle()


# ==================================================
# Playerのダメージ処理
# ==================================================

# 敵がHurtBoxに入ったとき
func _on_hurt_box_body_entered(body: Node2D) -> void:
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


# 接触し続けている敵を確認する
func check_enemy_contact() -> void:
	# クールタイム中なら確認しない
	if not damage_cooldown.is_stopped():
		return

	# HurtBoxに重なっている敵を取得する
	var overlapping_bodies := hurt_box.get_overlapping_bodies()

	for body in overlapping_bodies:
		if body.is_in_group("enemy"):
			take_damage(1)
			damage_cooldown.start()
			break


# Playerがダメージを受ける
func take_damage(damage: int) -> void:
	current_hp -= damage

	# HPが0未満にならないようにする
	current_hp = clamp(current_hp, 0, max_hp)

	print("プレイヤーの残りHP: ", current_hp)

	# HPバーを更新する
	hp_bar.set_hp(current_hp, max_hp)

	# HPが0ならゲームオーバー
	if current_hp <= 0:
		die()

# ==================================================
# 属性選択
# ==================================================

# 刀属性に変更する
func select_katana() -> void:
	attack_type = AttackType.KATANA
	print("属性を刀に変更しました")


# 弓属性に変更する
func select_bow() -> void:
	attack_type = AttackType.BOW
	print("属性を弓に変更しました")

# 属性選択中はPlayerを停止する
func prepare_for_attribute_selection() -> void:
	# 移動処理を停止する
	set_physics_process(false)

	# 自動攻撃も停止する
	$AttackTimer.stop()


# 属性選択後にPlayerを動かす
func start_gameplay() -> void:
	# 移動処理を開始する
	set_physics_process(true)

	# 自動攻撃を開始する
	$AttackTimer.start()

# ==================================================
# ゲームオーバー
# ==================================================

func die() -> void:
	print("ゲームオーバー")

	velocity = Vector2.ZERO

	# Playerの移動処理を停止する
	set_physics_process(false)

	# アニメーションを停止する
	animated_sprite.stop()
	
