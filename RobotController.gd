# RobotController.gd
extends CharacterBody3D

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var claw_hitbox: Area3D = find_child("ClawHitbox", true, false)

@onready var spring_arm_pivot: Node3D = $SpringArmPivot
@onready var spring_arm: SpringArm3D = $SpringArmPivot/SpringArm3D
@onready var camera: Camera3D = $SpringArmPivot/SpringArm3D/Camera3D

@onready var armature: Node3D = $Armature

const IDLE_ANIM_NAME := "idle"
const SMASH_ANIM_NAME := "grab" # using grab as smash

@export var move_speed: float = 4.0
@export var mouse_sens: float = 0.005
@export var pitch_limit: float = PI / 4.0
@export var turn_lerp: float = 0.15

var is_smashing := false

func _ready() -> void:
	if animation_player == null:
		push_error("AnimationPlayer not found under robot.")
		return

	if claw_hitbox == null:
		push_error("ClawHitbox (Area3D) not found under robot.")
		return

	# Camera: capture mouse + force this camera active (turning off current for MainLevel camera)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if camera:
		camera.current = true

	# Listen for overlaps: Area3D -> body_entered (targets are StaticBody3D)
	claw_hitbox.body_entered.connect(_on_claw_hitbox_body_entered)

	# Start idle
	if animation_player.has_animation(IDLE_ANIM_NAME):
		animation_player.play(IDLE_ANIM_NAME)

func _unhandled_input(event: InputEvent) -> void:
	# Quit (Escape mapped to "quit")
	if event.is_action_pressed("quit"):
		get_tree().quit()
		return

	# Mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# mouse moves the camera left/right (horizontal rotation pivot)
		spring_arm_pivot.rotate_y(-event.relative.x * mouse_sens)

		# pitch up/down (spring arm)
		spring_arm.rotate_x(-event.relative.y * mouse_sens)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -pitch_limit, pitch_limit)

	# Smash (Space mapped to ui_accept)
	if event.is_action_pressed("ui_accept"):
		smash_action()

func _physics_process(delta: float) -> void:
	# --- Camera-relative WASD movement (relative to SpringArmPivot yaw) ---
	var input_2d := Vector2.ZERO

	if Input.is_action_pressed("right"):
		input_2d.x += 1.0
	if Input.is_action_pressed("left"):
		input_2d.x -= 1.0
	if Input.is_action_pressed("forward"):
		input_2d.y += 1.0
	if Input.is_action_pressed("back"):
		input_2d.y -= 1.0

	input_2d = input_2d.normalized()

	# Build world-space forward/right using the pivot
	var basis := spring_arm_pivot.global_transform.basis
	var forward := -basis.z
	var right := basis.x

	# Flatten to XZ plane
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var move_dir := (right * input_2d.x) + (forward * input_2d.y)

	if move_dir.length() > 0.0:
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0
	move_and_slide()

	# --- Rotate the visual armature toward movement direction ---
	if armature:
		var planar_vel := Vector3(velocity.x, 0.0, velocity.z)
		if planar_vel.length() > 0.05:
			# Godot forward is -Z, so we align facing to -Z
			var target_y := atan2(-planar_vel.x, -planar_vel.z)
			armature.rotation.y = lerp_angle(armature.rotation.y, target_y, turn_lerp)

func smash_action() -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation(SMASH_ANIM_NAME):
		push_warning("No animation named '%s' found." % SMASH_ANIM_NAME)
		return
	if is_smashing:
		return

	is_smashing = true

	animation_player.stop()
	animation_player.play(SMASH_ANIM_NAME)

	await animation_player.animation_finished

	is_smashing = false

	if animation_player.has_animation(IDLE_ANIM_NAME):
		animation_player.play(IDLE_ANIM_NAME)

func _on_claw_hitbox_body_entered(body: Node) -> void:
	if not is_smashing:
		return

	if body != null and body.is_in_group("smash_target"):
		body.queue_free()
