extends CanvasLayer

const LOOK_CROSSHAIR = preload("res://assets/ui/crosshairs/eye_corsshair2.png")
const INTERACT_CROSSHAIR = preload("res://assets/ui/crosshairs/HAND_CROSSHAIR (1).png")
const IDLE_CROSSHAIR = preload("res://assets/ui/crosshairs/dot_small.png")
@onready var crosshair: TextureRect = %Crosshair
@onready var interaction_label: Label = %InteractionLabel
@onready var countdown_label: Label = %CountdownLabel
@onready var state_label: Label = %StateLabel
@onready var shadow_distance_slider: HSlider = %ShadowDistanceSlider

func _ready() -> void:
	GameManager.state_label_updated.connect(_update_state_label)
	GameManager.interaction_label_updated.connect(_update_interaction_label)
	GameManager.crosshair_signal.connect(_update_crosshair)
	GameManager.tick_countdown.connect(_update_countdown)
	GameManager.shadow_distance_changed.connect(_on_shadow_distance_slider_value_changed)


func _update_countdown():
	countdown_label.text = " " + str(GameMain.countdown)

func _update_crosshair(_crosshair : InteractionComponent.InteractionType):
	if _crosshair == InteractionComponent.InteractionType.IDLE:
		crosshair.texture = IDLE_CROSSHAIR
	elif _crosshair == InteractionComponent.InteractionType.LOOK:
		crosshair.texture = LOOK_CROSSHAIR
	elif _crosshair == InteractionComponent.InteractionType.INTERACT:
		crosshair.texture = INTERACT_CROSSHAIR


func _update_interaction_label(string: String):
	interaction_label.text = string

func _update_state_label(state : GameManager.GameState):
	state_label.text = GameManager.GameState.keys()[state]

func _on_shadow_distance_slider_value_changed(value):
	shadow_distance_slider.value = value
	print("Shadow distance changed: ", value)
