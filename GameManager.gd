extends Node3D

@export var target_scene: PackedScene
@export var spawn_interval := 2.0
@export var game_duration := 30.0
@export var timer_label: Label

var game_timer: Timer
var spawn_timer: Timer


func _ready():
	print("GameManager started")

	game_timer = Timer.new()
	game_timer.wait_time = game_duration
	game_timer.one_shot = true
	game_timer.timeout.connect(_on_game_timer_timeout)
	add_child(game_timer)
	game_timer.start()

	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()


func _process(delta):
	if game_timer and timer_label:
		timer_label.text = "Time: " + str(int(game_timer.time_left))


func _on_spawn_timer_timeout():
	if target_scene == null:
		return

	var instance = target_scene.instantiate()
	instance.position = Vector3(
		randf_range(-5, 5),
		1,
		randf_range(-5, 5)
	)
	get_parent().add_child(instance)


func _on_game_timer_timeout():
	spawn_timer.stop()
	print("Game over – stopping spawns")
