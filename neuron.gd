class_name Neuron
extends Node2D

var identification_number : int



class worm:
	var max_connections : int = 3
	var last_pair
	var worm_head : Neuron
	
	var target_neuron : Neuron
	signal arrived_at_target
	func check_if_target(neuron : Neuron):
		if neuron == target_neuron:
			arrived_at_target.emit()


@onready var area_2d: Area2D = $Area2D



signal neuron_clicked(Neuron)

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == 1 and !event.is_released():
		neuron_clicked.emit(self)
		print(str(self.name) + " ID: " + str(self.identification_number))
