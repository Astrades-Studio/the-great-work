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
		
var tween : Tween
func open_door():
	if locked:
		DialogManager.create_dialog_piece("It's locked")
		return
	
	tween = get_tree().create_tween()
	if !locked and !open:
		#tween.tween_property(self, "rotation:y", 0.0, 1.0)
		animation_player.play("open")
		open = true
		
	elif !locked and open:
		#tween.tween_property(self, "rotation:y", 1.0, 1.0)
		animation_player.play_backwards("open")
		open = false
