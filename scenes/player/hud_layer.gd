extends CanvasLayer

const LOOK_CROSSHAIR = preload("res://assets/ui/crosshairs/eye_corsshair2.png")
const INTERACT_CROSSHAIR = preload("res://assets/ui/crosshairs/HAND_CROSSHAIR (1).png")
const IDLE_CROSSHAIR = preload("res://assets/ui/crosshairs/dot_small.png")

@onready var crosshair: TextureRect = %HandCrosshair
@onready var interaction_label: Label = %InteractionLabel
@onready var shadow_distance_slider: HSlider = %ShadowDistanceSlider
@onready var controls: PanelContainer = %Controls
@onready var idle_crosshair: TextureRect = %IdleCrosshair

func _ready() -> void:
	GameManager.interaction_label_updated.connect(_update_interaction_label)
	GameManager.crosshair_signal.connect(_update_crosshair)
	GameManager.tick_countdown.connect(_update_countdown)
	GameManager.shadow_distance_changed.connect(_on_shadow_distance_slider_value_changed)
	GameManager.lamp_collected.connect(show_controls)


func show_controls():
	controls.show.call_deferred()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and controls.visible:
		controls.hide()


func _update_countdown():
	pass
	#countdown_label.text = " " + str(GameMain.countdown)

func _update_crosshair(_crosshair : InteractionComponent.InteractionType):
	if _crosshair == InteractionComponent.InteractionType.IDLE:
		crosshair.hide()
		idle_crosshair.show()
	elif _crosshair == InteractionComponent.InteractionType.LOOK:
		crosshair.texture = LOOK_CROSSHAIR
		crosshair.show()
		idle_crosshair.hide()
	elif _crosshair == InteractionComponent.InteractionType.INTERACT:
		crosshair.texture = INTERACT_CROSSHAIR
		crosshair.show()
		idle_crosshair.hide()


func _update_interaction_label(string: String):
	interaction_label.text = string

func _on_shadow_distance_slider_value_changed(value):
	shadow_distance_slider.value = value
	print("Shadow distance changed: ", value)
