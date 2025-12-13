extends Node3D

@onready var anim: AnimationPlayer = find_child("AnimationPlayer", true, false)

func _ready() -> void:
	if anim == null:
		push_error("AnimationPlayer not found under arm. Expand the arm node and confirm it exists.")
		return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("grab"):
		play_grab()

func play_grab() -> void:
	if anim == null:
		return

	if not anim.has_animation("grab"):
		push_warning("No animation named 'grab' found.")
		return

	anim.stop()
	anim.play("grab")
