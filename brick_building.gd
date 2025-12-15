# BrickBuildingGenerator.gd
extends Node3D

@export var brick_material: Material
@export var brick_size := Vector3(0.6, 0.25, 0.3) # x=length, y=height, z=depth
@export var bricks_per_row := 18
@export var rows := 10
@export var wall_depth_bricks := 12
@export var tile_per_brick := Vector2(2.5, 1.5)

func _ready() -> void:
	_clear_old()
	_build_walls()

func _clear_old() -> void:
	for c in get_children():
		if c is MeshInstance3D:
			c.queue_free()

func _build_walls() -> void:
	var total_width := bricks_per_row * brick_size.x
	var total_depth := wall_depth_bricks * brick_size.x
	var half_w := total_width * 0.5
	var half_d := total_depth * 0.5
	
	# Front wall (z = -half_d - brick_size.z/2), full width
	for y in range(rows):
		for i in range(bricks_per_row):
			var pos := Vector3(-half_w + float(i) * brick_size.x + brick_size.x * 0.5, float(y) * brick_size.y + brick_size.y * 0.5, -half_d - brick_size.z * 0.5)
			_spawn_brick(pos, false)
	
	# Back wall (z = +half_d + brick_size.z/2), full width
	for y in range(rows):
		for i in range(bricks_per_row):
			var pos := Vector3(-half_w + float(i) * brick_size.x + brick_size.x * 0.5, float(y) * brick_size.y + brick_size.y * 0.5, +half_d + brick_size.z * 0.5)
			_spawn_brick(pos, false)
	
	# Left wall, fits between front and back
	for y in range(rows):
		for i in range(wall_depth_bricks):
			var pos := Vector3(-half_w - brick_size.z * 0.5, float(y) * brick_size.y + brick_size.y * 0.5, -half_d + float(i) * brick_size.x + brick_size.x * 0.5)
			_spawn_brick(pos, true)
	
	# Right wall, fits between front and back
	for y in range(rows):
		for i in range(wall_depth_bricks):
			var pos := Vector3(+half_w + brick_size.z * 0.5, float(y) * brick_size.y + brick_size.y * 0.5, -half_d + float(i) * brick_size.x + brick_size.x * 0.5)
			_spawn_brick(pos, true)

func _spawn_brick(local_pos: Vector3, rotate_y_90: bool) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = brick_size
	mi.mesh = box
	
	if brick_material:
		mi.material_override = brick_material
		if brick_material is StandardMaterial3D:
			var m := brick_material as StandardMaterial3D
			m.uv1_scale = Vector3(tile_per_brick.x, tile_per_brick.y, 1.0)
	
	mi.position = local_pos
	if rotate_y_90:
		mi.rotation.y = deg_to_rad(90)
	
	add_child(mi)
