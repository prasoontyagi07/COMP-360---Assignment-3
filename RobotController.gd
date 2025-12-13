# RobotController.gd
extends CharacterBody3D

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var claw_hitbox: Area3D = find_child("ClawHitbox", true, false)

const IDLE_ANIM_NAME := "idle"
const SMASH_ANIM_NAME := "grab" # using grab as smash

@export var move_speed: float = 4.0

var movement_tween: Tween
var is_smashing := false

func _ready() -> void:
	if animation_player == null:
		push_error("AnimationPlayer not found under robot.")
		return

	if claw_hitbox == null:
		push_error("ClawHitbox (Area3D) not found under robot.")
		return

	# Listen for overlaps: Area3D -> body_entered (because targets are StaticBody3D)
	claw_hitbox.body_entered.connect(_on_claw_hitbox_body_entered)

	# Start idle
	if animation_player.has_animation(IDLE_ANIM_NAME):
		animation_player.play(IDLE_ANIM_NAME)

func _unhandled_input(event: InputEvent) -> void:
	# Quit (Escape mapped to "quit")
	if event.is_action_pressed("quit"):
		get_tree().quit()
		return

	# Smash (Space mapped to ui_accept)
	if event.is_action_pressed("ui_accept"):
		smash_action()

func _physics_process(delta: float) -> void:
	# Basic WASD movement (XZ plane)
	var input_dir := Vector3.ZERO

	# If you want movement relative to the robot's facing direction:
	var forward_dir: Vector3 = -global_transform.basis.z
	var right_dir: Vector3 = global_transform.basis.x

	if Input.is_action_pressed("forward"):
		input_dir += forward_dir
	if Input.is_action_pressed("back"):
		input_dir -= forward_dir
	if Input.is_action_pressed("right"):
		input_dir += right_dir
	if Input.is_action_pressed("left"):
		input_dir -= right_dir

	input_dir.y = 0.0

	if input_dir.length() > 0.0:
		input_dir = input_dir.normalized()
		velocity.x = input_dir.x * move_speed
		velocity.z = input_dir.z * move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	# Keep grounded / no jump for now
	velocity.y = 0.0

	move_and_slide()

func smash_action() -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation(SMASH_ANIM_NAME):
		push_warning("No animation named '%s' found." % SMASH_ANIM_NAME)
		return

	# Prevent re-triggering if already smashing
	if is_smashing:
		return

	is_smashing = true

	animation_player.stop()
	animation_player.play(SMASH_ANIM_NAME)

	# Wait until the animation finishes
	await animation_player.animation_finished

	is_smashing = false

	# Return to idle
	if animation_player.has_animation(IDLE_ANIM_NAME):
		animation_player.play(IDLE_ANIM_NAME)

func _on_claw_hitbox_body_entered(body: Node) -> void:
	# Only delete stuff during the smash window
	if not is_smashing:
		return

	if body != null and body.is_in_group("smash_target"):
		# Quick win: delete the target
		body.queue_free()
