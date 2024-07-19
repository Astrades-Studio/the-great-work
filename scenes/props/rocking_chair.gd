@tool
extends MeshInstance3D

# Variables to control rotation
@export var speed : float = 20.0 # Degrees per second
@export var max_angle : float = 10.0
@export var active: bool = false

var angle : float = 0.0
var direction : int = 1

func _process(delta):
	if !active:
		return
	# Calculate the new angle
	angle += direction * speed * delta

	# Change direction if the angle exceeds the bounds
	if angle > max_angle:
		angle = max_angle
		direction = -1
	elif angle < -max_angle:
		angle = -max_angle
		direction = 1

	# Apply the rotation
	rotation_degrees.x = angle
