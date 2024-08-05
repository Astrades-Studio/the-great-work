class_name Door
extends StaticBody3D

@export var door_id : StringName
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var locked = true
var open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if self.has_user_signal("interacted"):
		self.connect("interacted", Callable(self, "open_door"))


func open_door():
	if door_id == "Entrance":
		DialogManager.create_dialog_piece("I can't turn back now.")
	
	elif locked:
		DialogManager.create_dialog_piece("It's locked")
		return
	

	if !locked and !open:
		animation_player.play("open")
		open = true
		
	elif !locked and open:
		animation_player.play_backwards("open")
		open = false
