extends Node

var sound_bus_1 : AudioStreamPlayer
var sound_bus_2 : AudioStreamPlayer
var sound_bus_3 : AudioStreamPlayer

const PAGE_BOOK = preload("res://assets/sounds/sfx/Page Book.wav")

const SHADOW_1_SOUND = preload("res://assets/sounds/sfx/shadow/Devil Tremolo 001.wav")
const SHADOW_2_SOUND = preload("res://assets/sounds/sfx/shadow/Nightmare Songbird 001.wav")
const SHADOW_3_SOUND = preload("res://assets/sounds/sfx/shadow/Tormented Souls 001.wav")
const SHADOW_4_SOUND = preload("res://assets/sounds/sfx/shadow/Warp Wave 001.wav")
const SHADOW_5_SOUND = preload("res://assets/sounds/sfx/shadow/Well Of Nightmares 001.wav")
const SHADOW_6_SOUND = preload("res://assets/sounds/sfx/shadow/Whisper From Behind 001.wav")
const SHADOW_7_SOUND = preload("res://assets/sounds/sfx/shadow/Whisper Out Of Nowhere 001.wav")
const SHADOW_8_SOUND = preload("res://assets/sounds/sfx/shadow/Whispering Tunnels 001.wav")


var shadow_sounds = [SHADOW_1_SOUND,
	SHADOW_2_SOUND,
	SHADOW_3_SOUND,
	SHADOW_4_SOUND,
	SHADOW_5_SOUND,
	SHADOW_6_SOUND,
	SHADOW_7_SOUND,
	SHADOW_8_SOUND]

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
	

func play_shadow_sound():
	# Play the first shadow sound, then if called again play the second, and so on
	if shadow_sounds.size() > 0:
		shadow_sounds.shuffle()
		var sound = shadow_sounds.pop_front()
		play_sound(sound)
		shadow_sounds.append(sound)
