# GameManager.gd
extends Node3D

@export var target_scene: PackedScene
@export var spawn_interval: float = 2.0
@export var game_duration: float = 30.0

@export var timer_label_path: NodePath = "HUD/TimerLabel" # Displays time, and later, the status

const COIN_SCRIPT := preload("res://coin.gd") # lets us read COIN_SCRIPT.score safely

var spawn_timer: Timer
var time_left: float = 0.0
var game_over := false

func _ready() -> void:
	randomize()

	time_left = game_duration
	_update_timer_label()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()

func _process(delta: float) -> void:
	if game_over:
		return

	time_left = max(time_left - delta, 0.0)
	_update_timer_label()

	if time_left <= 0.0:
		_end_game()

func _on_spawn_timer_timeout() -> void:
	if game_over:
		return
	if target_scene == null:
		return

	var inst := target_scene.instantiate() as Node3D
	if inst == null:
		return

	# Add FIRST then set global position
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent() # fallback

	scene_root.add_child(inst)

	inst.global_position = Vector3(
		randf_range(-5.0, 5.0),
		1.0,
		randf_range(-5.0, 5.0)
	)

func _update_timer_label() -> void:
	if timer_label_path == NodePath():
		return

	var scene_root := get_tree().current_scene
	if scene_root == null:
		return

	var n := scene_root.get_node_or_null(timer_label_path)
	if n is Label:
		n.text = "Time: %d" % int(ceil(time_left))

func _end_game() -> void:
	if game_over:
		return
		
	game_over = true
	if spawn_timer:
		spawn_timer.stop()

	# Display Game Over Message on Timer Label
	var final_score = COIN_SCRIPT.score
	
	if timer_label_path != NodePath():
		var scene_root := get_tree().current_scene
		if scene_root:
			var n := scene_root.get_node_or_null(timer_label_path)
			if n is Label:
				# Use a larger font or change color in the theme override for better visibility
				n.text = "TIME OVER! Score: %d" % final_score
	# ----------------------------------------------------
	
	print("⛔ Time up! Final score: ", final_score)
	
	# Disable player control
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
