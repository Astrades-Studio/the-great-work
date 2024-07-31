extends Control

var input_on : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TransitionManager.transition_finished.connect(_on_transition_finished)

func _on_transition_finished():
	input_on = true
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		if input_on:
			TransitionManager.change_scene_to_file(GameManager.MAIN_MENU)
