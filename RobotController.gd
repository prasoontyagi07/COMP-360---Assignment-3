# RobotController.gd
extends CharacterBody3D

@onready var animation_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var claw_hitbox: Area3D = find_child("ClawHitbox", true, false)

const IDLE_ANIM_NAME := "idle"
const SMASH_ANIM_NAME := "grab" # using grab as smash

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

func _input(event: InputEvent) -> void:
	# Use Space by default (ui_accept). If you made an InputMap action "smash", swap this.
	if event.is_action_pressed("ui_accept"):
		smash_action()

func smash_action() -> void:
	if animation_player == null:
		return
	if not animation_player.has_animation(SMASH_ANIM_NAME):
		push_warning("No animation named '%s' found." % SMASH_ANIM_NAME)
		return

	is_smashing = true

	animation_player.stop()
	animation_player.play(SMASH_ANIM_NAME)

	# Wait until the animation finishes (better than guessing 1.0 seconds)
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
