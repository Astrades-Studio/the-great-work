extends Node

const TRANSITION_LAYER = preload("res://scenes/ui/transition_layer.tscn")

var transition_layer : TransitionLayer
var duration := 2.0
var color := Color.BLACK

var progress : Array = []
var scene_name : String
var scene_load_status := 0

signal transition_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	transition_layer = TRANSITION_LAYER.instantiate()
	transition_layer.game_visible.connect(self._on_game_visible)
	transition_layer.animation_finished.connect(self._on_transition_finished)
	add_child(transition_layer)
	transition_layer.hide()


func change_scene_to_file(path: String) -> void:
	scene_name = path
	transition_layer.request_transition(duration, color)
	#await transition_layer.animation_finished
	

func _on_transition_finished():
	ResourceLoader.load_threaded_request(scene_name)


func _on_game_visible():
	transition_finished.emit()


func _process(_delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(scene_name, progress)
	# TODO: add countdown or loading bar
	# Check if there are erros while loading:
	if scene_load_status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Failed to load scene: ", scene_name)
	if scene_load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		push_error("Invalid scene: ", scene_name)

	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(scene_name)
		get_tree().change_scene_to_packed(new_scene)
		transition_layer.fade_in()
