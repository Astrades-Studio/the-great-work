@tool
class_name Flare
extends Ingredient

@onready var fire_beam: GPUParticles3D = %FireBeam
@onready var smoke: GPUParticles3D = %Smoke
@onready var light: OmniLight3D = %Light
@onready var duration_timer: Timer = $DurationTimer
@onready var shadow_barrier: Area3D = $ShadowBarrier

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
			fire_beam.emitting = true
			smoke.emitting = true
			light.visible = true
		else:
			fire_beam.emitting = false
			smoke.emitting = false
			light.visible = false

func _ready() -> void:
	super()
	active = false
	location_changed.connect(_on_location_changed)
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
	active = false
	#mesh.mesh.surface_get_material(0).albedo_color = Color.DIM_GRAY
	#mesh.mesh.surface_get_material(1).albedo_color = Color.DIM_GRAY
	spent = true


func _on_shadow_barrier_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
