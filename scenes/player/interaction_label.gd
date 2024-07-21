extends Label

func _ready() -> void:
	text = ""
	GameManager.update_interaction_label.connect(update_interaction_label)

func update_interaction_label(string: String):
	text = string
