class_name Darkness
extends Area3D

@export var MAX_COOLDOWN : float = 30.0
@export var MAX_HP : int = 3
@export var HP_DOWN_TICK : float = 1.
@onready var wait_point: Node3D = $WaitPoint

const WHISPERS_DIALOG = preload("res://assets/dialog/whispers_dialog.tres")

var already_seen : bool = false
@export var shadow_present : bool
var cooldown : float = 0.0
var flare_near : bool
var flare_reference : Flare
var hp : float:
	set(value):
		hp = value
		if hp <= 0:
			remove_shadow()


@onready var shadow: Shadow = $Shadow
@onready var darkness_fx: GPUParticles3D = $DarknessFX
@onready var darkness_fx_intensity = darkness_fx.amount_ratio
@onready var shadow_death_player: AudioStreamPlayer3D = $ShadowDeathSound
@onready var damage_sound: AudioStreamPlayer3D = $DamageSound


signal shadow_banished(Shadow)

func _ready() -> void:
	hide()
	hp = MAX_HP
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	GameManager.tick_countdown.connect(_on_tick_countdown)
	GameManager.shadow_spawn_points.append(self)
	shadow_banished.connect(GameManager.on_shadow_removed.bind(shadow))

var getting_hurt : bool = false
func _process(delta: float) -> void:
	if is_instance_valid(flare_reference):
		if flare_reference.active and shadow_present:
			hp -= delta
			shadow.change_state_to(Shadow.State.HURT)
			if !damage_sound.playing:
				damage_sound.play()

	if !shadow_present and cooldown >= 0.:
		cooldown -= delta


func _on_tick_countdown() -> void:
	pass

var _pursue_cooldown : float = 0.0
const MAX_PURSUE_COOLDOWN := 2.
var last : int = -1
func _on_body_entered(body: Node3D) -> void:
	if body is Flare:
		if is_instance_valid(body):
			flare_reference = body
	if body is Player:
		if body.ingredient_in_hand is Flare:
			flare_reference = body.ingredient_in_hand
		if shadow_present:
			if !GameManager.first_shadow_encountered:
				DialogManager.play_dialog(load("res://assets/dialog/first_shadow_encounter.tres"))
				GameManager.first_shadow_encountered = true
			#body.gas_lamp.disabled = true
			#shadow.turn_invisible()
			shadow.target = body
			shadow.change_state_to(Shadow.State.PURSUING)
			body.panic_effects.increase_agitation()
		
			if !already_seen:
				var random_int =  randi() % 3
				while last == random_int:
					random_int = randi() % 3
				if random_int == 0:
					DialogManager.create_subtitles_piece("Gordo puto!!")
				if random_int == 1:
					DialogManager.create_subtitles_piece("MAMAAA!")
				if random_int == 2:
					DialogManager.create_subtitles_piece("Get away from me!")
				last = random_int
				
				already_seen = false
				


func _on_body_exited(body: Node3D) -> void:
	if body is Player:
		body.gas_lamp.disabled = false
		#shadow.reset_invisibility()
		if is_instance_valid(body.ingredient_in_hand):
			if body.ingredient_in_hand is Flare:
				flare_reference = null
		shadow.target = null
		shadow.target_position = body.global_position
		await get_tree().create_timer(2).timeout			
		body.panic_effects.decrease_agitation()
		


var tween : Tween        
func spawn_shadow() -> bool:
	if shadow_present:
		return false
	if cooldown >= 0.:
		return false
	if !GameManager.first_shadow_spawned:
		DialogManager.create_subtitles_piece("What was that? I feel a presence.")
		GameManager.first_shadow_spawned = false
	hp = MAX_HP
	shadow_present = true
	show()
	tween = get_tree().create_tween()
	tween.tween_property(darkness_fx, "amount_ratio", 1, 2)
	tween.parallel().tween_property(darkness_fx, "lifetime", 1.7, 0.1)
	play_random_whisper()
	await tween.finished
	return true


func remove_shadow() -> void:
	shadow_death_player.play()
	damage_sound.stop()
	shadow_banished.emit()
	cooldown = MAX_COOLDOWN
	shadow_present = false
	# TODO: VFX
	shadow.visible = false
	
	tween = get_tree().create_tween()
	tween.tween_property(darkness_fx, "amount_ratio", 0, 2)
	tween.parallel().tween_property(darkness_fx, "lifetime", 10, 0.1)
	await tween.finished
	hide()


func play_random_whisper() -> void:
	var dialog : Dialog = WHISPERS_DIALOG
	# if dialog is empty, reload it
	if dialog.dialog.is_empty():
		dialog = load("res://assets/dialog/whispers_dialog.tres")
	dialog.dialog.shuffle()
	
	# choose a DialogPiece at random from WHISPERS_DIALOG
	var index = randi() % dialog.dialog.size()
	var piece = dialog.dialog[index]
	DialogManager.create_subtitles_piece(piece.dialog_text)
	play_random_shadow_sound()


func play_random_shadow_sound():
	SfxManager.play_shadow_sound(-20.0)
