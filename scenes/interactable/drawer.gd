class_name Drawer
extends Node3D

var og_position : Vector3
var target_position : Vector3
var open : bool = false
@onready var drawer: MeshInstance3D = $DrawerMesh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	og_position = position
	var z_size := drawer.get_aabb().size.z
	target_position = position + (Vector3(0, 0, z_size) / 1.3)

	if has_user_signal("interacted"):
		self.connect("interacted", Callable(self, "open_drawer"))


func open_drawer() -> void:
	# create a tween that moves self locally on the z axis negative for 1 lenght of self size z
	var tween = get_tree().create_tween()
	if open:
		tween.tween_property(self, "position", og_position, 1.0)
		open = false
	else:
		tween.tween_property(self, "position", target_position, 1.0)
		open = true
	
