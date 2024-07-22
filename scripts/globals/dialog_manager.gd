extends Node

var dialog_layer : DialogLayer


# First create DialogPiece.new() and set dialog_text to be the text to say and dialog_name to be the name
# To write dialog to the screen, just call DialogManager.show_text(DialoguePiece)
# Can be done from wherever


# Takes a string and shows a text box containing it. 
# Optionally you can include a name as the second parameter
func create_dialog_piece(text: String, speaker: String = "???"):
	var dialog_piece := DialogPiece.new()
	dialog_piece.dialog_text = text
	dialog_piece.dialog_name = speaker
	dialog_layer.queue_text(dialog_piece)


func play_dialog(dialog : Dialog):
	for dialog_piece : DialogPiece in dialog.dialog:
		dialog_layer.queue_text(dialog_piece)


func skip():
	dialog_layer.hide_text()
