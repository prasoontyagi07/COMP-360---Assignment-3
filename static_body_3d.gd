extends StaticBody3D

@export var fade_time := 0.25
var _smashed := false
@onready var mesh: MeshInstance3D = _find_mesh(self)

func _find_mesh(n: Node) -> MeshInstance3D:
	for c in n.get_children():
		if c is MeshInstance3D:
			return c
		var m := _find_mesh(c)
		if m != null:
			return m
	return null

func smash() -> void:
	if _smashed:
		return
	_smashed = true

	if mesh:
		var t := create_tween()
		t.tween_property(mesh, "transparency", 1.0, fade_time)
		await t.finished

	queue_free()
