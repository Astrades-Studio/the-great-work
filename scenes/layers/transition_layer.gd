class_name TransitionLayer
extends CanvasLayer

@onready var screen: ColorRect = $Screen

signal animation_finished
signal game_visible

var tween : Tween
var duration

func request_transition(_duration, color : Color = Color.BLACK):
	if tween:
		tween.kill()
	duration = _duration
	show()
	tween = get_tree().create_tween()
	tween.tween_property(screen, "modulate", color, duration)
	await tween.finished
	animation_finished.emit()

func fade_in():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(screen, "modulate", Color.TRANSPARENT, 1.0)
	await tween.finished
	hide()
	game_visible.emit()
