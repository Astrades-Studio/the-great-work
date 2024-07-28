extends CanvasLayer

@onready var interaction_label: Label = %InteractionLabel
@onready var countdown_label: Label = %CountdownLabel

@onready var state_label: Label = %StateLabel

func _ready() -> void:
	GameManager.state_label_updated.connect(_update_state_label)
	GameManager.interaction_label_updated.connect(_update_interaction_label)
	GameManager.tick_countdown.connect(_update_countdown)
	
func _update_countdown():
	countdown_label.text = " " + str(GameMain.countdown)

func _update_interaction_label(string: String):
	interaction_label.text = string

func _update_state_label(state : GameManager.GameState):
	state_label.text = GameManager.GameState.keys()[state]
