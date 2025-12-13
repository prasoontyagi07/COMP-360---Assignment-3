extends StaticBody3D

@export var fade_time := 0.25

var _smashed := false
@onready var _meshes: Array[GeometryInstance3D] = []

func _ready() -> void:
	# Grab every visible 3D geometry 
	for n in find_children("*", "GeometryInstance3D", true, false):
		_meshes.append(n)

func smash() -> void:
	if _smashed:
		return
	_smashed = true

	# Fade every mesh in parallel
	if _meshes.size() > 0:
		var t := create_tween()
		t.set_parallel(true)
		for m in _meshes:
			t.tween_property(m, "transparency", 1.0, fade_time)
		await t.finished

	queue_free()
