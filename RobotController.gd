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

# Hop tuning
@export var hop_height: float = 1.8
@export var hop_distance: float = 1.0
@export var hop_up_time: float = 0.15
@export var hop_down_time: float = 0.20

# Turn smoothing
@export var turn_lerp: float = 0.15

var is_smashing := false
var is_hopping := false
var hop_tween: Tween = null

func _ready() -> void:
	if animation_player == null:
		push_error("AnimationPlayer not found under robot.")
		return

	if claw_hitbox == null:
		push_error("ClawHitbox (Area3D) not found under robot.")
		return

	# Camera: capture mouse + force this camera active
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
		# Mouse moves camera left/right (horizontal rotation)
		spring_arm_pivot.rotate_y(-event.relative.x * mouse_sens)

		# Mouse moves camera up/down (vertical rotation)
		spring_arm.rotate_x(-event.relative.y * mouse_sens)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, -pitch_limit, pitch_limit)

	# Smash (Space mapped to ui_accept)
	if event.is_action_pressed("ui_accept"):
		smash_action()
		return

	# Hop (Shift mapped to "hop")
	if event.is_action_pressed("hop"):
		hop_action()
		return

func _physics_process(_delta: float) -> void:
	# If hopping, tween is controlling position
	if is_hopping:
		return

	# Movement direction relative to camera (SpringArmPivot)
	var input_dir := _get_move_input_dir()

	if input_dir.length() > 0.0:
		velocity.x = input_dir.x * move_speed
		velocity.z = input_dir.z * move_speed

		# Rotate the armature to face movement direction
		if armature:
			var target_y := atan2(-input_dir.x, -input_dir.z)
			armature.rotation.y = lerp_angle(armature.rotation.y, target_y, turn_lerp)
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0
	move_and_slide()

func _get_move_input_dir() -> Vector3:
	var dir := Vector3.ZERO

	# Use camera yaw so WASD matches where you're looking
	var yaw := spring_arm_pivot.rotation.y
	var forward := Vector3.FORWARD.rotated(Vector3.UP, yaw)
	var right := Vector3.RIGHT.rotated(Vector3.UP, yaw)

	if Input.is_action_pressed("forward"):
		dir += forward
	if Input.is_action_pressed("back"):
		dir -= forward
	if Input.is_action_pressed("right"):
		dir += right
	if Input.is_action_pressed("left"):
		dir -= right

	dir.y = 0.0
	return dir.normalized() if dir.length() > 0.0 else Vector3.ZERO

func hop_action() -> void:
	if is_hopping:
		return

	is_hopping = true
	velocity = Vector3.ZERO

	if hop_tween:
		hop_tween.kill()

	var start := global_position

	# Only move forward if you are holding a movement key
	var move_dir := _get_move_input_dir()
	var offset := move_dir * hop_distance

	var peak := start + Vector3(0.0, hop_height, 0.0) + (offset * 0.5)
	var end := start + offset

	hop_tween = create_tween()
	hop_tween.tween_property(self, "global_position", peak, hop_up_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hop_tween.tween_property(self, "global_position", end, hop_down_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await hop_tween.finished
	is_hopping = false

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

	# Wait until the smash animation finishes
	await animation_player.animation_finished

	is_smashing = false

	# Return to idle
	if animation_player.has_animation(IDLE_ANIM_NAME):
		animation_player.play(IDLE_ANIM_NAME)

func _on_claw_hitbox_body_entered(body: Node) -> void:
	# Only trigger smash effects during the smash window
	if not is_smashing:
		return

	if body == null:
		return

	if body.is_in_group("smash_target"):
		# NEW: call smash() on the target (target handles fade/coins/etc)
		if body.has_method("smash"):
			body.call_deferred("smash")  # safe even if we’re mid-physics step
		else:
			# fallback
			body.queue_free()
