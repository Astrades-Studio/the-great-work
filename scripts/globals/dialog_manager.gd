extends Node

var dialog_layer : DialogLayer
var subtitles_layer : SubtitleLayer

const INTRO := preload("res://assets/dialog/intro_dialog.tres")

# First create DialogPiece.new() and set dialog_text to be the text to say and dialog_name to be the name
# To write dialog to the screen, just call DialogManager.show_text(DialoguePiece)
# Can be done from wherever


# Takes a string and shows a text box containing it. 
# Optionally you can include a name as the second parameter
func create_dialog_piece(text: String, speaker: String = "Melchiades"):
	var dialog_piece := DialogPiece.new()
	dialog_piece.dialog_text = text
	dialog_piece.dialog_speaker = speaker

	var _dialog = Dialog.new()
	_dialog.dialog.append(dialog_piece)
	play_dialog(_dialog)



func play_dialog(dialog : Dialog):
	GameManager.current_state = GameManager.GameState.DIALOG
	dialog_layer.play_dialog(dialog)


func play_subtitles(dialog : Dialog, duration : float):
	#GameManager.current_state = GameManager.GameState.DIALOG
	subtitles_layer.play_subtitles(dialog, duration)


func play_cinematic(dialog : Dialog, duration : float):
	subtitles_layer.play_subtitles(dialog, duration)


func skip_dialog():
	dialog_layer.hide_text()


func _on_dialog_finished():
#	await get_tree().create_timer(0.2).timeout
	GameManager.current_state = GameManager.GameState.PLAYING


func _on_subtitle_finished():
	pass
	
