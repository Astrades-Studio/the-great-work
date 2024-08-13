extends Node

const TRANSITION_LAYER = preload("res://scenes/ui/transition_layer.tscn")

var transition_layer : TransitionLayer
var duration := 2.0
var color := Color.BLACK

var progress : Array = []
var scene_name : String
var scene_load_status := 0

var loading : bool = false

signal transition_finished
signal loading_finished

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	transition_layer = TRANSITION_LAYER.instantiate()
	transition_layer.game_visible.connect(self._on_game_visible)
	transition_layer.animation_finished.connect(self._on_transition_finished)
	add_child(transition_layer)
	transition_layer.hide()


func change_scene_to_file(path: String) -> void:
	loading = true
	scene_name = path
	transition_layer.request_transition(duration, color)
	#await transition_layer.animation_finished

# Should be changed to false when the cinematic is done
var preloading = false

func preload_scene(path: String) -> void:
	preloading = true
	loading = true
	scene_name = path
	ResourceLoader.load_threaded_request(scene_name)


func _on_transition_finished():
	if preloading:
		return
	ResourceLoader.load_threaded_request(scene_name)


func _on_cinematic_finished():
	preloading = false
	transition_layer.request_transition(duration, color)


func _on_game_visible():
	transition_finished.emit()


func _process(_delta):
	if !loading:
		return
	
	scene_load_status = ResourceLoader.load_threaded_get_status(scene_name, progress)
	# TODO: add countdown or loading bar

	if preloading:
		if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
			TransitionManager.loading_finished.emit()
		return
	
	if !scene_name:
		push_error("No scene to load")
		
	# Check if there are erros while loading:
	if scene_load_status == ResourceLoader.THREAD_LOAD_FAILED:
		push_error("Failed to load scene: ", scene_name)
	#if scene_load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		#push_error("Invalid scene: ", scene_name)

	# Load the new scene as soon as it is finished
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var new_scene = ResourceLoader.load_threaded_get(scene_name)
		get_tree().change_scene_to_packed(new_scene)
		transition_layer.fade_in()
		loading = false
		preloading = false
		scene_name = ""
