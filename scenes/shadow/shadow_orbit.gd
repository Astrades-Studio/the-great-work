@tool
class_name ShadowOrbit
extends Marker3D

const BURN_FX = preload("res://scenes/shadow/skull_burn_fx.tres")
const DARK_FX = preload("res://scenes/shadow/skull_dark_fx.tres")

static var MAX_DISTANCE: float = 5.0

@export_group("Constants")
@export var STEP_DISTANCE: float = 1.0
@export var MAX_ROTATION_SPEED: float = 0.2
@export var MIN_ROTATION_SPEED: float = 0.01
@export var MAX_OFFSET : float = 2.0
@export var FREQUENCY : float = 1.0

@export var VISIBILITY_COOLDOWN: float = 10.0
@export var VISIBILITY_DURATION: float = 5.0
@export var RETREAT_COOLDOWN: float = 30.0

@export_group("Rotation")
@export var active: bool
@export var _rotate_y: bool = true
@export var offset_active := false
@export var getting_closer := false
@export var distance := MAX_DISTANCE
@export var chase_target : UCharacterBody3D

# Rotation parameters
var rotation_speed: float = 0.1
var offset : float = 0.0
var time := 0.0

# Flare parameters
var flare_references : Array[Flare] = []

@onready var skull_position: Marker3D = $ShadowDistance
@onready var skull_mesh: MeshInstance3D = %Skull
@onready var skull_approach_sound: AudioStreamPlayer3D = %SkullApproachSound
@onready var skull_appear_sound: AudioStreamPlayer3D = %SkullAppearSound
@onready var shaker_component: ShakerComponent3D = $ShadowDistance/ShakerComponent3D

enum State {
	INACTIVE,
	WAITING,
	PURSUING,
	#ORBITING,
	RETREATING
}

var current_state : State = State.WAITING: set = change_state_to


func change_state_to(state : State) -> void:
	current_state = state
	match state:
		State.INACTIVE:
			return

		State.WAITING:
			print("Shadow waiting")
			await _disappear_gradually()
			#_reset_appear_timer()

		State.PURSUING:
			print("Shadow pursuing")
			await _appear_gradually()
			skull_approach_sound.play()
			await set_distance(distance - STEP_DISTANCE)
			change_state_to(State.WAITING)

		State.RETREATING:
			print("Shadow retreating")
			await _appear_gradually()
			_change_fx_to(BURN_FX)
			skull_appear_sound.play()
			await set_distance(MAX_DISTANCE)
			await _disappear_gradually()
			_change_fx_to(DARK_FX)
			retreated.emit()


signal appeared
signal disappeared
signal retreated


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	GameManager.game_started.connect(start_pursuing)
	GameManager.tick_countdown.connect(_on_tick_countdown)

	_set_up_initial_conditions()

# Timers
@export var max_retreat_duration: float = 30.0
@export var max_visibility_duration: float = 2.5
@export var max_invisibility_duration: float = 3.5

var visibility_timer := 0.0
var retreat_timer := 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint() and !active:
		return
	match current_state:
		State.INACTIVE:
			return

		State.WAITING:
			visibility_timer += delta
			if _visible:
				if visibility_timer >= max_visibility_duration:
					visibility_timer = 0.0
					_toggle_invisibility()
			else:
				if visibility_timer >= max_invisibility_duration:
					visibility_timer = 0.0
					_toggle_invisibility()

			if offset_active:
				time += delta
				offset = sin(time * FREQUENCY) * MAX_OFFSET
				skull_position.position.y = offset

			# rotate on the y axis
			if _rotate_y:
				rotate_y(rotation_speed * delta)

			# change shaker intensity by distance, the closer to the player, the closer to 0 intensity
			var intensity = remap(distance, 0.0, MAX_DISTANCE, 0.0, 1.0)
			shaker_component.intensity = intensity

		State.PURSUING:
			if !_visible:
				_appear_gradually()


		State.RETREATING:
			visibility_timer += delta
			if visibility_timer >= max_visibility_duration:
				visibility_timer = 0.0
				_disappear_gradually()
			retreat_timer += delta
			if retreat_timer >= max_retreat_duration:
				retreat_timer = 0.0
				change_state_to(State.WAITING)
			return

	if current_state != State.RETREATING and !Engine.is_editor_hint():
		if flare_references.size() > 0:
			for flare in flare_references:
				if flare.active:
					change_state_to(State.RETREATING)
					break

	# follow the chase target gradually
	if chase_target:
		var target_position = chase_target.global_position

		if !Engine.is_editor_hint():
			target_position = chase_target.camera.global_position

		global_position = global_position.lerp(target_position, delta)
		#global_position.y = global_position.y + 1.7


func set_distance(value):
	distance = clamp(value, 0.0, MAX_DISTANCE)
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(skull_position, "position:z", distance, 1.5)
	await tween.finished
	GameManager.shadow_distance_changed.emit(distance)


# func _reset_appear_timer() -> void:
# 	await get_tree().create_timer(VISIBILITY_COOLDOWN, false).timeout
# 	if current_state == State.WAITING:
# 		current_state = State.ORBITING


func _set_up_initial_conditions() -> void:
	hide()
	current_state = State.INACTIVE
	visibility_timer = 0.0
	retreat_timer = 0.0
	await set_distance(MAX_DISTANCE)


func start_pursuing() -> void:
	current_state = State.WAITING
	show()


func _on_tick_countdown():
	if current_state == State.WAITING:
		change_state_to(State.PURSUING)


# Randomize speed
func _randomize_speed() -> void:
	rotation_speed = randf_range(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED)

var _visible := false

func _toggle_invisibility() -> void:
	if _visible:
		_disappear_gradually()
	else:
		_appear_gradually()


var transition_duration := 1.0
func _appear_gradually() -> void:
	if Engine.is_editor_hint():
		return
	_visible = true

	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	var tween : Tween = get_tree().create_tween()

	tween.tween_property(skull_mesh.mesh.material, "albedo_color:a", 1, transition_duration).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	tween.parallel().tween_property(dark_fx.draw_pass_1.material, "albedo_color:a", 1, transition_duration).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	await tween.finished
	appeared.emit()


func _disappear_gradually() -> void:
	if Engine.is_editor_hint():
		return
	var tween : Tween = get_tree().create_tween()
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")

	tween.tween_property(skull_mesh.mesh.material, "albedo_color:a", 0, transition_duration).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	tween.parallel().tween_property(dark_fx.draw_pass_1.material, "albedo_color:a", 0, transition_duration).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SPRING)

	await tween.finished
	_visible = false
	disappeared.emit()

	#skull_mesh.hide()
	#get_tree().create_timer(VISIBILITY_COOLDOWN, false).timeout.connect(_appear_gradually)


func _change_fx_to(fx : Material) -> void:
	var dark_fx : GPUParticles3D = skull_mesh.get_node("DarkFX")
	dark_fx.draw_pass_1.material = fx


func _on_hurtbox_body_entered(body: Node3D) -> void:
	if body is Flare:
		flare_references.append(body)


func _on_hurtbox_body_exited(body: Node3D) -> void:
	if body is Flare:
		flare_references.erase(body)


# Kill the player if too close
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is Player:
		if current_state == State.RETREATING or current_state == State.INACTIVE:
			return

		GameManager.game_over.emit()
