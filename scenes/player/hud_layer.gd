extends CanvasLayer

@onready var interaction_label: Label = %InteractionLabel
@onready var countdown_label: Label = %CountdownLabel

func _ready() -> void:
	interaction_label.text = ""
	GameManager.update_interaction_label.connect(_update_interaction_label)
	GameManager.tick_countdown.connect(_update_countdown)
	
func _update_countdown():
	countdown_label.text = " " + str(GameMain.countdown)

func _update_interaction_label(string: String):
	interaction_label.text = string
