extends Node2D

# Patterns
var triangle_symbol : Array[Array] = [[1,4],[4,7],[7,1]]
var triangle_symbol_2 : Array[Array] = [[4,1],[7,4],[1,7]]


# Neurons currently connected to check pattern
var connections : Array[Neuron]

@onready var worm: Area2D = $Worm


var active_connections : Array = []
var max_connections : int = 3

var previous_neuron : Neuron

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var neurons = get_children()
	var count = 1
	for neuron in neurons:
		if neuron is Neuron:
			neuron.neuron_clicked.connect(neuron_clicked)
			neuron.identification_number = count
			count += 1

func neuron_clicked(neuron : Neuron):
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(worm, "global_position", neuron.global_position, 1.0)
	worm.look_at(neuron.global_position)
	
	neuron.modulate = Color.RED
	
	if connections.size() >= max_connections:
		var old_neuron = connections.pop_front()
		old_neuron.modulate = Color.WHITE
		connections.append(neuron)
	else:
		connections.append(neuron)
	
	if Globals.neural_dict.has(str(neuron.identification_number)):
		var possible_connections : Array = Globals.neural_dict.get(str(neuron.identification_number))
		var actual_connections : Array = look_for_neurons(possible_connections)
		for _neuron in actual_connections:
			if _neuron != neuron:
				_neuron.modulate = Color.GREEN
	
	if !previous_neuron:
		previous_neuron = neuron
	else:
		var new_pair = [previous_neuron.identification_number, neuron.identification_number]
		active_connections.append(new_pair)
		
		var count = 0
		var count_to_succeed = 3
		
		for id_pair : Array in triangle_symbol: # [1,4],[4,7],[7,1]
			var reversed = id_pair.duplicate()
			reversed.reverse()
			for active_pair in active_connections:
				if active_pair in id_pair or active_pair in reversed:
					count += 1
					if count >= count_to_succeed:
						print("you win")

func look_for_neurons(array : Array) -> Array:
	var neurons = get_children()
	var count = 1
	var results: Array
	
	for neuron in neurons:
		if neuron is Neuron:
			if neuron.identification_number in array:
				results.append(neuron)
			count += 1
	return results

#func connect_neurons(_neuron_1 : Neuron, _neuron_2 : Neuron):
	#if active_connections.size() >= max_connections:
		#active_connections.pop_back()
	#var connection : Array = [_neuron_1, neuron_2]
	#active_connections.append(connection)
	
func get_nearby_neurons(neuron):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
