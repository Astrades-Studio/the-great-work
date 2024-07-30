class_name Darkness
extends Area3D

@export var MAX_COOLDOWN : float = 30.0
@export var MAX_HP : int = 3
@export var HP_DOWN_TICK : float = 1.

const WHISPERS_DIALOG = preload("res://assets/dialog/whispers_dialog.tres")

var shadow_present : bool
var cooldown : float = 0.0
var flare_near : bool
var flare_reference : Flare
var hp : float:
	set(value):
		hp = value
		if hp <= 0:
			remove_shadow()


@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var shadow: Shadow = $Shadow
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
@onready var darkness_fx: GPUParticles3D = $DarknessFX
@onready var darkness_fx_intensity = darkness_fx.amount_ratio
@onready var darkness_light: OmniLight3D = $DarknessLight
@onready var passive_sound: AudioStreamPlayer3D = $PassiveSound

signal shadow_banished(Shadow)

func _ready() -> void:
	hide()
	hp = MAX_HP
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	GameManager.shadow_spawn_points.append(self)
	shadow_banished.connect(GameManager.on_shadow_removed.bind(shadow))


func _process(delta: float) -> void:
	if flare_reference:
		if flare_reference.active and shadow_present:
			hp -= delta
			print("HP: " + str(hp))
	if !shadow_present and cooldown >= 0.:
		cooldown -= delta


func _on_tick_countdown() -> void:
	pass


func _on_body_entered(body: Node3D) -> void:
	if body is Flare:
		if is_instance_valid(body):
			flare_reference = body
	if body is Player:
		if body.ingredient_in_hand is Flare:
			flare_reference = body.ingredient_in_hand
		if shadow_present:
			#body.gas_lamp.disabled = true
			shadow.turn_invisible()
			body.panic_effects.increase_agitation()
			if !GameManager.first_shadow_encountered:
				DialogManager.play_subtitles(load("res://assets/dialog/first_shadow_encounter.tres"), 2.0)
				GameManager.first_shadow_encountered = true
				
				
func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.gas_lamp.disabled = false
		shadow.reset_invisibility()
		if is_instance_valid(body.ingredient_in_hand):
			if body.ingredient_in_hand is Flare:
				flare_reference = null
		await get_tree().create_timer(2).timeout			
		body.panic_effects.decrease_agitation()

var tween : Tween        
func spawn_shadow() -> bool:
	if shadow_present:
		return false
	if cooldown >= 0.:
		return false
	hp = MAX_HP
	shadow_present = true
	show()
	tween = get_tree().create_tween()
	tween.tween_property(darkness_fx, "amount_ratio", 1, 2)
	play_random_whisper()
	await tween.finished
	return true


func remove_shadow() -> void:
	shadow_banished.emit()
	cooldown = MAX_COOLDOWN
	shadow_present = false
	# TODO: VFX
	shadow.visible = false
	
	tween = get_tree().create_tween()
	tween.tween_property(darkness_fx, "amount_ratio", 0, 2)
	await tween.finished
	hide()


func play_random_whisper() -> void:
	var dialog : Dialog = WHISPERS_DIALOG
	# if dialog is empty, reload it
	if dialog.dialog.is_empty():
		dialog = load("res://assets/dialog/whispers_dialog.tres")
	dialog.dialog.shuffle()
	
	# choose a DialogPiece at random from WHISPERS_DIALOG
	var index = randi() % dialog.size()
	var piece = dialog[index]
	DialogManager.create_subtitles_piece(piece)
	play_random_shadow_sound()
	# remove that piece from the dialog
	dialog.dialog.remove_at(index)


func play_random_shadow_sound():
	SfxManager.shadow_sounds.shuffle()
	var selected_sound = SfxManager.shadow_sounds[0]
	audio.stream = selected_sound
	audio.play()
