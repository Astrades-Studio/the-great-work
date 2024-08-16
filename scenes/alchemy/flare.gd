class_name Flare
extends Ingredient

const FLARE_MATERIAL_SPENT = preload("res://assets/models/materials/flare_material_spent.tres")
const FLARE_MATERIAL_UNSPENT = preload("res://assets/models/materials/flare_material_unspent.tres")

@onready var fire_beam: GPUParticles3D = %FireBeam
@onready var smoke: GPUParticles3D = %Smoke
@onready var light: OmniLight3D = %Light
@onready var duration_timer: Timer = $DurationTimer
@onready var shadow_barrier: Area3D = $ShadowBarrier
@onready var contents: MeshInstance3D = $Contents
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

@export var duration : int = 30

var spent : bool = false

@export var active: bool:
	set(value):
		if !Engine.is_editor_hint() and spent:
			return
		if !is_node_ready():
			await ready
		active = value
		if active:
			duration_timer.start(duration)
			audio.play()
			fire_beam.emitting = true
			smoke.emitting = true
			light.visible = true
			light.light_energy = 5.0
		else:
			audio.stop()
			fire_beam.emitting = false
			smoke.emitting = false
			light.visible = false

func _ready() -> void:
	super()
	active = false
	set_material(FLARE_MATERIAL_UNSPENT)
	location_changed.connect(_on_location_changed)
	if is_instance_valid(contents):
		var active_material : StandardMaterial3D = contents.get_active_material(0)
		if active_material:
			active_material.albedo_color = Color.DARK_RED
			contents.mesh.surface_set_material(0, active_material.duplicate())


	if type != Ingredient.Type.FLARE:
		type = Ingredient.Type.FLARE


func _on_location_changed():
	if current_location == Location.ENVIRONMENT:
		fire_beam.layers = 0x0002
		smoke.layers = 0x0002
	else:
		fire_beam.layers = 0x0001
		smoke.layers = 0x0001

func _on_duration_timer_timeout() -> void:
	if Engine.is_editor_hint():
		return
	active = false
	if is_instance_valid(contents):
		set_material(FLARE_MATERIAL_SPENT)
		# var active_material : StandardMaterial3D = contents.get_active_material(0)
		# if active_material:
		# 	var new_material = active_material.duplicate()
		# 	contents.mesh.surface_set_material(0, new_material)
		# 	new_material.albedo_color = Color.BLACK
	name = "Spent Flare"
	spent = true


func set_material(material : Material) -> void:
	if is_instance_valid(contents):
		contents.material_override = material


func _on_shadow_barrier_area_entered(_area: Area3D) -> void:
	pass # Replace with function body.
