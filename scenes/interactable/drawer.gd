class_name Drawer
extends MeshInstance3D

var og_position : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	og_position = global_position

	if has_user_signal("interacted"):
		self.connect("interacted", Callable(self, "open_drawer"))


func open_drawer() -> void:
	
