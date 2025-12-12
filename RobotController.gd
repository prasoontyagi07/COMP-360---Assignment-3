# RobotController.gd

extends CharacterBody3D

# Access the AnimationPlayer node. Adjust the path if yours is deeper in the hierarchy!
@onready var animation_player: AnimationPlayer = $AnimationPlayer 

# Use the animations found in the provided model
const IDLE_ANIM_NAME = "idle" 
const SMASH_ANIM_NAME = "grab" # We'll use 'grab' as the smashing action

var movement_tween: Tween = null

func _ready():
	# Start the robot in the idle state
	if animation_player.has_animation(IDLE_ANIM_NAME):
		animation_player.play(IDLE_ANIM_NAME)

# --- Function to handle smooth movement using Tween (REQUIRED) ---
func move_base_to(target_position: Vector3, duration: float = 0.5):
	# Kill any current movement
	if movement_tween:
		movement_tween.kill()
	
	# Create the required Tween instance for "tween animations"
	movement_tween = create_tween()
	
	# Tween the global_position property of the CharacterBody3D
	movement_tween.tween_property(self, "global_position", target_position, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

# --- Function to play the smash animation ---
func smash_action():
	if animation_player.has_animation(SMASH_ANIM_NAME):
		animation_player.play(SMASH_ANIM_NAME)
		# Immediately return to idle after the smash duration
		# We assume 'grab' is short, maybe 1 second long
		await get_tree().create_timer(1.0).timeout
		if animation_player.has_animation(IDLE_ANIM_NAME):
			animation_player.play(IDLE_ANIM_NAME)

	else:
		print("Error: Smash animation '%s' not found!" % SMASH_ANIM_NAME)

# Placeholder for testing:
func _input(event):
	if event.is_action_pressed("ui_accept"): # Default key is Enter/Space
		smash_action()
		# Example Test Move (optional for now)
		# var target_pos = global_position + Vector3(1, 0, 1)
		# move_base_to(target_pos)
