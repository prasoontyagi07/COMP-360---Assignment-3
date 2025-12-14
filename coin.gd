# Coin.gd
extends Area3D

@export var spin_speed: float = 2.5
@export var bob_height: float = 0.15
@export var bob_speed: float = 4.0

var _start_y: float
var _t: float = 0.0
var _picked := false
static var score: int = 0

func _ready() -> void:
	_start_y = global_position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Spin
	rotate_y(spin_speed * delta)

	_t += delta
	var p := global_position
	p.y = _start_y + sin(_t * bob_speed) * bob_height
	global_position = p
	
func _update_score_label() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var path := "HUD/ScoreLabel"
	if scene.has_node(path):
		var lbl := scene.get_node(path)
		if lbl is Label:
			lbl.text = "Score: %d" % score
func _on_body_entered(body: Node) -> void:
	if _picked:
		return

	# Only the robot/player can pick it up
	if body != null and body.is_in_group("player"):
		_picked = true
		score += 1
		_update_score_label()

		# ▶ Play coin sound
		$AudioStreamPlayer3D.play()

		# ⏳ Small delay so sound can finish
		await get_tree().create_timer(0.3).timeout

		# ❌ Remove coin
		queue_free()
