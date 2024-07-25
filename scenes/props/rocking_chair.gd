@tool
extends StaticBody3D

# Variables to control rotation
@export var speed : float = 20.0 # Degrees per second
@export var max_angle : float = 10.0
@export var active: bool = false:
	set(value):
		active = value
		Events.active_shadows.append(self)

var angle : float = 0.0
var direction : int = 1

func _ready() -> void:
	GameManager.tick_countdown.connect(on_tick_countdown)
	
	
func on_tick_countdown():
	if !active:
		if Events.active_shadows.size() > 5:
			return
		
		# TODO: spawn shadows
		
		active = true

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
