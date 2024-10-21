extends Marker3D

@onready var shadow: Shadow = $Shadow
@onready var area_3d: Area3D = $Area3D
@onready var dispel_cutscene: AnimationPlayer = %DispelCutscene

var flare_reference: Flare
var _triggered : bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.hide()
	GameManager.flare_read_signal.connect(_manifest)
	#area_3d.body_entered.connect(_on_area_3d_body_entered)


func _manifest():
	self.show()



func _process(_delta: float) -> void:
	if GameManager.shadow_dispelled:
		return
	if !is_instance_valid(flare_reference):
		return
	if flare_reference.active and !_triggered:
		dispel_shadow()


func dispel_shadow() -> void:
	_triggered = true
	GameManager.current_state = GameManager.GameState.CUTSCENE
	GameManager.cutscene_started.emit()
	dispel_cutscene.play("dispel")

func _on_dispel_animation_finished():
	GameManager.cutscene_finished.emit()
	DialogManager.create_dialog_piece("Seems like I can go downstairs now.")
	GameManager.shadow_dispelled = true
	hide()


func _on_area_3d_body_entered(body: Node3D) -> void:
	if !GameManager.flare_already_made:
		return
	if GameManager.shadow_dispelled:
		return
	if body is Player:
		if is_instance_valid(body.ingredient_in_hand):
			if body.ingredient_in_hand is Flare:
				flare_reference = body.ingredient_in_hand
