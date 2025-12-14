# static_body_3d.gd
extends StaticBody3D

@export var fade_time := 0.25
@export var coin_scene: PackedScene
@export var coin_count := 1
@export var coin_spread := 0	

@onready var mesh: GeometryInstance3D = find_child("MeshInstance3D", true, false)

var _smashed := false

func _ready() -> void:
	if coin_scene == null:
		coin_scene = preload("res://Coin.tscn")

func smash() -> void:
	print("BOX SMASHED")

	if _smashed:
		return
	_smashed = true

	# --- NEW: Tell the RobotController to reset the smash state ---
	# Find the robot node (assuming it's in the "player" group)
	var robot_node = get_tree().get_first_node_in_group("player")
	
	if robot_node and robot_node.has_method("reset_smash"):
		robot_node.reset_smash()
	# -------------------------------------------------------------

	_spawn_coins()

	# fade then remove
	if mesh:
		var t := create_tween()
		t.tween_property(mesh, "transparency", 1.0, fade_time)
		await t.finished

	queue_free()

func _spawn_coins() -> void:
	
	if coin_scene == null:
		return

	var parent := get_parent()
	if parent == null:
		return
		

	for i in range(coin_count):
		var coin := coin_scene.instantiate()
		parent.add_child(coin)

		# little ring around target
		var offset := Vector3(
			randf_range(-coin_spread, coin_spread),
			0.3,
			randf_range(-coin_spread, coin_spread)
		)

		coin.global_position = global_position + offset

		# tiny “pop” up/down tween	
		var pop := coin.create_tween()
		pop.tween_property(coin, "global_position", coin.global_position + Vector3(0, 0.4, 0), 0.12)
		pop.tween_property(coin, "global_position", coin.global_position, 0.18)
