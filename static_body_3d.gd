extends StaticBody3D

@export var fade_time := 0.25

@onready var mesh: MeshInstance3D = $MeshInstance3D

var _smashed := false

func smash() -> void:
	if _smashed:
		return
	_smashed = true

	# Quick fade (no material setup needed)
	if mesh:
		var t := create_tween()
		t.tween_property(mesh, "transparency", 1.0, fade_time)
		await t.finished

	queue_free()
