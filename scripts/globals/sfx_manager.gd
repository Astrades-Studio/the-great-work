extends Node

var sound_bus_1 : AudioStreamPlayer
var sound_bus_2 : AudioStreamPlayer
var sound_bus_3 : AudioStreamPlayer

const PAGE_BOOK = preload("res://assets/sounds/sfx/Page Book.wav")
const OPEN_BOOK = preload("res://assets/sounds/sfx/Open Book.wav")
const SHADOW_01 = preload("res://assets/sounds/sfx/shadow/Shadow_01.wav")
const SHADOW_02 = preload("res://assets/sounds/sfx/shadow/Shadow_02.wav")
const SHADOW_03 = preload("res://assets/sounds/sfx/shadow/Shadow_03.wav")
const SHADOW_04 = preload("res://assets/sounds/sfx/shadow/Shadow_04.wav")


var shadow_sounds = [
	SHADOW_01,
	SHADOW_02,
	SHADOW_03,
	SHADOW_04,
	]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	sound_bus_1 = AudioStreamPlayer.new()
	sound_bus_2 = AudioStreamPlayer.new()
	sound_bus_3 = AudioStreamPlayer.new()
	sound_bus_1.bus = "SFX"
	sound_bus_2.bus = "SFX"
	sound_bus_3.bus = "SFX"
	add_child(sound_bus_1)
	add_child(sound_bus_2)
	add_child(sound_bus_3)


func play_sound(sound: AudioStream, delay := 0.0, volume := 0.0):
	if !sound_bus_1.playing:
		sound_bus_1.stream = sound
		sound_bus_1.volume_db = volume
		sound_bus_1.play(delay)
	elif !sound_bus_2.playing:
		sound_bus_2.stream = sound
		sound_bus_2.volume_db = volume
		sound_bus_2.play(delay)
	elif !sound_bus_3.playing:
		sound_bus_3.stream = sound
		sound_bus_3.volume_db = volume
		sound_bus_3.play(delay)
	else:
		push_warning("Too many sounds playing")


func stop_all_sounds():
	sound_bus_1.stop()
	sound_bus_2.stop()
	sound_bus_3.stop()
	

func play_shadow_sound(volume : float):
	# Play the first shadow sound, then if called again play the second, and so on
	if shadow_sounds.size() > 0:
		shadow_sounds.shuffle()
		var sound = shadow_sounds.pop_front()
		play_sound(sound, volume)
		shadow_sounds.append(sound)



func set_bus_volume(target_db : float, bus_idx : int):
	AudioServer.set_bus_volume_db(bus_idx, target_db)
