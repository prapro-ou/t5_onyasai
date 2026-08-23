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
@export var arrow_scene: PackedScene = preload("res://scenes/player/arrow.tscn")


# ==================================================
# 移動設定
# ==================================================

# 刀属性の移動速度
@export var katana_move_speed: float = 200.0

# 刀停止アニメーション(idle)の大きさ倍率
@export var katana_idle_scale_multiplier: float = 0.8

# 刀移動アニメーション(run)の大きさ倍率
@export var katana_run_scale_multiplier: float = 0.8

# 刀攻撃アニメーション(attack)の大きさ倍率
@export var katana_attack_scale_multiplier: float = 1.2

# 弓属性の移動速度
@export var bow_move_speed: float = 140.0

# 弓停止アニメーション(yumi_idle)の大きさ倍率
@export var yumi_idle_scale_multiplier: float = 0.75

# 弓移動アニメーション(yumi_run)の大きさ倍率
@export var yumi_run_scale_multiplier: float = 1.0

# 弓攻撃アニメーション(yumi_attack)の大きさ倍率
@export var yumi_attack_scale_multiplier: float = 0.75

# yumi_attack開始から矢を放つまでの時間
@export var bow_release_delay: float = 0.3

# 矢を放った後、攻撃状態を解除するまでの時間
@export var bow_recovery_time: float = 0.2

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

# 騎馬停止アニメーション(kiba_idle)の大きさ倍率
# 1.0 = 通常サイズ、0.8 = 80%、1.2 = 120%
@export var kiba_idle_scale_multiplier: float = 0.9

# 騎馬移動アニメーション(kiba_run)の大きさ倍率
# kiba_idleとは別々に調整できる
@export var kiba_run_scale_multiplier: float = 1.0

# 騎馬突進アニメーション(kiba_dash)の大きさ倍率
@export var kiba_dash_scale_multiplier: float = 0.7

# AnimatedSprite2Dの元の大きさを保存
var base_sprite_scale: Vector2 = Vector2.ONE

# 突進時の速度
@export var horse_dash_speed: float = 650.0

# 突進時間
@export var horse_dash_duration: float = 0.5

# 突進ダメージ
@export var horse_dash_damage: int = 1

# 騎馬突進で敵を押し飛ばす速さ
# 突進速度より十分速くして、敵がPlayerに埋まるのを防ぐ
@export var horse_knockback_power: float = 1200.0

# 騎馬突進で敵を押し飛ばす時間
# 短時間だけ強く弾くことで、素早いノックバックにする
@export var horse_knockback_duration: float = 0.2

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

# 弓攻撃アニメーション中かどうか
var is_bow_attacking: bool = false

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
	# AnimatedSprite2Dの元の大きさを保存
	base_sprite_scale = animated_sprite.scale

	# ★ここを変更: GameManagerのHPボーナスを反映
	max_hp += GameManager.hp_bonus
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
	var base_speed := katana_move_speed

	match attack_type:
		AttackType.KATANA:
			base_speed = katana_move_speed

		AttackType.BOW:
			base_speed = bow_move_speed

		AttackType.HORSE:
			base_speed = horse_move_speed

	# ★ここを変更: スピードボーナスを足した速度を返す
	return base_speed + GameManager.speed_bonus

# ==================================================
# アニメーション
# ==================================================

func update_animation(direction: Vector2) -> void:
	# 刀攻撃中は移動アニメーションへ変更しない
	if is_attacking:
		return

	# 弓攻撃中はyumi_attackを上書きしない
	if is_bow_attacking:
		return

	# 騎馬属性
	if attack_type == AttackType.HORSE:
		if direction == Vector2.ZERO:
			animated_sprite.scale = (
				base_sprite_scale * kiba_idle_scale_multiplier
			)
			animated_sprite.play("kiba_idle")
		else:
			animated_sprite.scale = (
				base_sprite_scale * kiba_run_scale_multiplier
			)
			animated_sprite.play("kiba_run")

	# 弓属性
	elif attack_type == AttackType.BOW:
		if direction == Vector2.ZERO:
			animated_sprite.scale = (
				base_sprite_scale * yumi_idle_scale_multiplier
			)
			animated_sprite.play("yumi_idle")
		else:
			animated_sprite.scale = (
				base_sprite_scale * yumi_run_scale_multiplier
			)
			animated_sprite.play("yumi_run")

	# 刀属性
	else:
		# 停止中はidle
		if direction == Vector2.ZERO:
			animated_sprite.scale = (
				base_sprite_scale * katana_idle_scale_multiplier
			)
			animated_sprite.play("idle")

		# 移動中はrun
		else:
			animated_sprite.scale = (
				base_sprite_scale * katana_run_scale_multiplier
			)
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

	# --------------------------
	# 攻撃方向を決める
	# --------------------------

	# 攻撃直前に押している方向を取得
	var attack_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	# 入力がある場合は、その方向を攻撃方向として保存
	if attack_direction != Vector2.ZERO:
		attack_direction = attack_direction.normalized()
		last_move_direction = attack_direction

	# 入力がない場合は最後に移動した方向を使用
	else:
		attack_direction = last_move_direction.normalized()

	# 念のため方向が0なら右向き
	if attack_direction == Vector2.ZERO:
		attack_direction = Vector2.RIGHT
		last_move_direction = attack_direction

	# --------------------------
	# 攻撃状態・向き
	# --------------------------

	# 攻撃中にする
	is_attacking = true

	# 刀攻撃アニメーションの大きさ
	animated_sprite.scale = (
		base_sprite_scale * katana_attack_scale_multiplier
	)

	# idle/runと同じ基準で攻撃方向へ向ける
	# 左入力
	if attack_direction.x < 0:
		animated_sprite.flip_h = false
		weapon_holder.scale.x = 1.0

	# 右入力
	elif attack_direction.x > 0:
		animated_sprite.flip_h = true
		weapon_holder.scale.x = -1.0

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

		# 攻撃終了後も最後の移動方向を維持する
		if last_move_direction.x < 0:
			animated_sprite.flip_h = false
			weapon_holder.scale.x = 1.0

		elif last_move_direction.x > 0:
			animated_sprite.flip_h = true
			weapon_holder.scale.x = -1.0


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

	# すでに弓攻撃中なら重ねて攻撃しない
	if is_bow_attacking:
		return

	# 矢のシーンが設定されていなければ終了
	if arrow_scene == null:
		push_warning("Arrow Sceneが設定されていません。")
		return

	# 最後に移動した方向とは逆方向へ発射
	var shoot_direction := -last_move_direction.normalized()

	# 念のため方向が0の場合は左向きにする
	if shoot_direction == Vector2.ZERO:
		shoot_direction = Vector2.LEFT

	# 弓攻撃開始
	is_bow_attacking = true

	# yumi_attack専用サイズ
	animated_sprite.scale = (
		base_sprite_scale * yumi_attack_scale_multiplier
	)

	# 実際に矢を撃つ方向へ向ける
	if shoot_direction.x < 0:
		animated_sprite.flip_h = false
		weapon_holder.scale.x = 1.0
	elif shoot_direction.x > 0:
		animated_sprite.flip_h = true
		weapon_holder.scale.x = -1.0

	# 弓攻撃アニメーション
	animated_sprite.play("yumi_attack")

	# 矢を放つフレームまで待つ
	await get_tree().create_timer(bow_release_delay).timeout

	if not is_inside_tree():
		return

	if is_dead:
		is_bow_attacking = false
		return

	# 矢を生成
	var arrow := arrow_scene.instantiate()

	# Playerの属性を矢に渡す
	arrow.player_zokusei = player_zokusei

	# 攻撃力強化分を矢へ渡す
	arrow.attack_bonus = GameManager.attack_bonus

	# 現在のステージへ矢を追加
	get_tree().current_scene.add_child(arrow)

	# Playerの位置から矢を出現
	arrow.global_position = global_position

	# 矢の進行方向
	arrow.direction = shoot_direction

	# 矢画像を進行方向へ回転
	arrow.rotation = shoot_direction.angle()

	# 矢を放った後のアニメーション分だけ待つ
	await get_tree().create_timer(bow_recovery_time).timeout

	if not is_inside_tree():
		return

	# 弓攻撃終了
	is_bow_attacking = false


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

	# --------------------------
	# 現在の入力から突進方向を決める
	# --------------------------

	# 現在押している移動方向を取得
	var current_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	# 現在入力がある場合は、その方向を最優先
	if current_direction != Vector2.ZERO:
		dash_direction = current_direction.normalized()
		last_move_direction = dash_direction

	# 入力がない場合は、最後に移動した方向へ突進
	else:
		dash_direction = last_move_direction.normalized()

	# 念のため方向が0の場合は右向きにする
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.RIGHT
		last_move_direction = dash_direction

	# --------------------------
	# 突進アニメーション
	# --------------------------

	# 騎馬突進アニメーションのサイズ
	animated_sprite.scale = (
		base_sprite_scale * kiba_dash_scale_multiplier
	)

	# 突進方向に合わせて左右反転
	if dash_direction.x < 0:
		animated_sprite.flip_h = false
		weapon_holder.scale.x = 1.0

	elif dash_direction.x > 0:
		animated_sprite.flip_h = true
		weapon_holder.scale.x = -1.0

	# 今回攻撃した敵をリセット
	dash_hit_enemies.clear()

	# 突進開始
	is_dashing = true

	# 騎馬突進アニメーション
	animated_sprite.play("kiba_dash")

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

	# Playerから敵へ向かう押し出し方向を保存する
	# 敵がPlayer内部に残らないよう、常にPlayerから離れる方向へ飛ばす
	var horse_push_direction := global_position.direction_to(body.global_position)
	if horse_push_direction == Vector2.ZERO:
		horse_push_direction = dash_direction

	# 敵へダメージ
	var actual_damage := get_attribute_damage(
		horse_dash_damage,
		body
	)
	body.take_damage(
		actual_damage,
		global_position
	)

	# 通常ノックバックを騎馬専用の高速・短時間ノックバックで上書きする
	if (
		is_instance_valid(body)
		and not body.is_queued_for_deletion()
		and body.has_method("apply_directional_knockback")
	):
		body.apply_directional_knockback(
			horse_push_direction,
			horse_knockback_power,
			horse_knockback_duration
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
	var attribute_ui = get_tree().current_scene.get_node_or_null("StageUI/AttributeUI")

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
	var attribute_ui = get_tree().current_scene.get_node_or_null("StageUI/AttributeUI")

	if attribute_ui:
		attribute_ui.update_attribute(player_zokusei)

	# 弓属性では停止時yumi_idle、移動時yumi_run、
	# 攻撃時yumi_attackを使用する

	# 1秒ごとに攻撃
	attack_timer.wait_time = 1.0

	print("属性を弓に変更しました")


# 騎馬属性
func select_horse() -> void:
	player_zokusei = "blue"
	attack_type = AttackType.HORSE
	#UI変更
	var attribute_ui = get_tree().current_scene.get_node_or_null("StageUI/AttributeUI")

	if attribute_ui:
		attribute_ui.update_attribute(player_zokusei)

	# 騎馬属性では停止時kiba_idle、移動時kiba_run、
	# 突進時kiba_dashを使用する

	# 2秒ごとに突進
	attack_timer.wait_time = 2.0

	print("属性を騎馬に変更しました")

# ==================================================
# 属性による攻撃力の設定
# ==================================================
func get_attribute_damage(base_damage: int, enemy: Node2D) -> int:
	# ここから変更
	var actual_damage := (
		base_damage
		+ GameManager.attack_bonus
	)
	# ここまで

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

	# 弓攻撃状態を解除
	is_bow_attacking = false

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
