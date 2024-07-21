extends Node

var music_stream_1 : AudioStreamPlayer
var music_stream_2 : AudioStreamPlayer
var music_stream_3 : AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_stream_1 = AudioStreamPlayer.new()
	music_stream_2 = AudioStreamPlayer.new()
	music_stream_3 = AudioStreamPlayer.new()
	add_child(music_stream_1)
	add_child(music_stream_2)
	add_child(music_stream_3)


func play_music(music: AudioStream, delay := 0.0):
	if !music_stream_1.playing:
		music_stream_1.stream = music
		music_stream_1.play(delay)
	elif !music_stream_2.playing:
		music_stream_2.stream = music
		music_stream_2.play(delay)
	elif !music_stream_3.playing:
		music_stream_3.stream = music
		music_stream_3.play(delay)
