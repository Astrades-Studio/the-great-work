extends Node

var sound_bus_1 : AudioStreamPlayer
var sound_bus_2 : AudioStreamPlayer
var sound_bus_3 : AudioStreamPlayer

const PAGE_BOOK = preload("res://assets/sounds/sfx/Page Book.wav")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	sound_bus_1 = AudioStreamPlayer.new()
	sound_bus_2 = AudioStreamPlayer.new()
	sound_bus_3 = AudioStreamPlayer.new()
	add_child(sound_bus_1)
	add_child(sound_bus_2)
	add_child(sound_bus_3)


func play_sound(sound: AudioStream, delay := 0.0):
	if !sound_bus_1.playing:
		sound_bus_1.stream = sound
		sound_bus_1.play(delay)
	elif !sound_bus_2.playing:
		sound_bus_2.stream = sound
		sound_bus_2.play(delay)
	elif !sound_bus_3.playing:
		sound_bus_3.stream = sound
		sound_bus_3.play(delay)
