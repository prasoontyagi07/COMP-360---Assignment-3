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

	_spawn_smash_particles(global_position + Vector3(0, 0.25, 0))
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
func _spawn_smash_particles(at_pos: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 45
	p.lifetime = 0.35
	p.explosiveness = 1.0
	p.randomness = 0.8

	# IMPORTANT: particles need a draw mesh or you won't see anything
	var m := SphereMesh.new()
	m.radius = 0.03
	m.height = 0.06
	p.draw_pass_1 = m

	var mat := ParticleProcessMaterial.new()
	mat.gravity = Vector3(0, -12.0, 0)
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 2.0
	mat.initial_velocity_max = 6.0
	mat.angular_velocity_min = -8.0
	mat.angular_velocity_max = 8.0
	mat.damping_min = 1.0
	mat.damping_max = 3.0
	mat.scale_min = 0.4
	mat.scale_max = 1.0

	p.process_material = mat

	get_parent().add_child(p)
	p.global_position = at_pos

	# fire once, then clean up
	p.restart()
	p.emitting = true

	await get_tree().create_timer(p.lifetime + 0.2).timeout
	if is_instance_valid(p):
		p.queue_free()
