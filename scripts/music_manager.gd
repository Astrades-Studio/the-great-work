extends Node

var music_stream_1 : AudioStreamPlayer
var ambient_music_stream : AudioStreamPlayer
var ambient_music_stream_2 : AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	music_stream_1 = AudioStreamPlayer.new()
	ambient_music_stream = AudioStreamPlayer.new()
	ambient_music_stream_2 = AudioStreamPlayer.new()
	
	add_child(music_stream_1)
	add_child(ambient_music_stream)
	add_child(ambient_music_stream_2)


var tween : Tween
func play_music(music: AudioStream, fade_duration := 5.0):
	if !music_stream_1.playing:
		music_stream_1.volume_db = linear_to_db(1.0)
		music_stream_1.stream = music
		music_stream_1.play(0.0)
	else:
		fade_music_stream(music_stream_1, fade_duration)

	
func play_ambient_music(music: AudioStream, fade_duration := 5.0):
	if !ambient_music_stream.playing:
		ambient_music_stream.volume_db = linear_to_db(1.0)
		ambient_music_stream.stream = music
		ambient_music_stream.play(0.0)
	else:
		fade_music_stream(ambient_music_stream, fade_duration)


func fade_music_stream(music_stream: AudioStreamPlayer, fade_duration := 5.0):
	tween = get_tree().create_tween()
	tween.tween_property(music_stream, "volume_db", linear_to_db(0.0), fade_duration)
	tween.tween_callback(music_stream.stop)
	tween.finished.connect(music_stream.play.bind(0.0)) 
