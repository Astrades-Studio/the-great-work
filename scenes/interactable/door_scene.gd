class_name Door
extends StaticBody3D

@export var door_id : StringName
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var door_opening: AudioStreamPlayer3D = $DoorOpening
@onready var door_closing: AudioStreamPlayer3D = $DoorClosing
@onready var door_locked: AudioStreamPlayer3D = $DoorLocked

@export var basement_door = false
@export var locked = true
var open = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.flare_read_signal.connect(_unlock_basement_door)
	if self.has_user_signal("interacted"):
		self.connect("interacted", Callable(self, "open_door"))
	
	if GameManager.flare_recipe_read:
		_unlock_basement_door()

var tween : Tween

	#LOCKED DOOR
func open_door():
	if locked:
		door_locked.play()
		DialogManager.create_dialog_piece("It's locked")
		return

	#OPENING DOOR
	if !locked and !open:
		door_opening.play()
		animation_player.play("open")
		open = true

	#CLOSING DOOR
	elif !locked and open:
		door_closing.play()
		animation_player.play_backwards("open")
		open = false


func unlock():
	if locked:
		locked = false
	else:
		return

func _unlock_basement_door():
	if basement_door:
		if locked:
			unlock()
		if !open:
			open_door()
