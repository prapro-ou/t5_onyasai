extends Node
@export var mob_scene: PackedScene
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	new_game()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func game_over() -> void:
	$ScoreTimer.stop()
	$MobTimer.stop()
	
func new_game():
	score=0
	$player.start($StartPosition.position)
	


func on_score_Timer() -> void:
	score +=1


func _on_start_timer() -> void:
	$MobTimer.start()
	$ScoreTimer.start()


func _on_mob_timer_timeout() -> void:
	var mob= mob_scene .instantiate()
	var mob_spownlocation =get_node("Mob_Path2D/Mob_spownlocation")
	mob_spownlocation.progress_ratio=randf()
	
	var direction = mob_spownlocation.rotation+ PI/2
	
	mob.position = mob_spownlocation.position
	direction += randf_range(-PI/4 ,PI/4)
	mob.rotation =direction
	var velocity = Vector2(randf_range(150.0,250.0),0.0)
	mob.linear_velocity=velocity.rotated(direction)
	
	add_child(mob)
