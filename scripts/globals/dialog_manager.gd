extends Node

var dialog_layer : DialogLayer


# First create DialogPiece.new() and set dialog_text to be the text to say and dialog_name to be the name
# To write dialog to the screen, just call DialogManager.show_text(DialoguePiece)
# Can be done from wherever

class DialogPiece :
	var dialog_text = "I don't know"
	var dialog_name = "???"


func create_dialog(text: String, speaker: String = "???"):
	var dialog = DialogPiece.new()
	dialog.dialog_text = text
	dialog.dialog_name = speaker
	show_text(dialog)


func show_text(string : DialogPiece):
	dialog_layer.show_text(string)

func skip():
	dialog_layer.hide_text()
