class_name CinematicCamera
extends Camera3D


func return_to_gameplay_camera():
	var tween := get_tree().create_tween()
	tween.tween_property(self, "global_transform", GameManager.player.camera.global_transform, 1.0)
	await tween.finished
	GameManager.player.camera.make_current()
