@icon("res://AutoFootStepsPlugin/Icon.png")
extends Node3D
class_name AutoFootSteps
## This node from the Ovani Auto Footsteps plugin will play footsteps when your player walks.
##
## Place this around your players feet, and tell it your player's walking running & crouching speed.
## Then, It'll automatically detect what the player is standing on, and play the correct sound.

const AIR_NAME : StringName = StringName("Air")

## The Current Collection of Sound Effects / Materials to play.
@export
var foot_profile : FootProfile #= preload("res://AutoFootStepsPlugin/DefaultSounds/BareFootProfile.tres")
## The Current Material Name the player is standing on.
var current_material : StringName = AIR_NAME

func _get_material() -> FootProfileMaterialSpecification:
	if current_material == AIR_NAME:
		return FootProfile._AIR_MAT_SPEC
	return foot_profile._material_lookup[current_material]

var _character_controller : CharacterBody3D
var _cached_collider_materials : Dictionary
var _cached_material_materials : Dictionary

## The audio bus to play footsteps to.
@export
var audio_bus : StringName = "Master":
	get:
		if _audio_player == null:
			return audio_bus
		else:
			return _audio_player.bus
	set(value):
		audio_bus = value
		_audio_player.bus = value
var _audio_player : AudioStreamPlayer3D
var _audio_player_playback : AudioStreamPlaybackPolyphonic

## Footstep volume, in decibels.
@export_range(-80, 20)
var volume_db : float = 0

## The distance per step in meters.
@export
var footstep_distance : float = 1.6

## The speed we'll expect your player to crouch at.
@export
var crouch_speed : float = 1.6 / 2
## The speed we'll expect your player to walk at.
@export
var walk_speed : float = 1.6
## The speed we'll expect your player to run at.
@export
var run_speed : float = 1.6 * 2

## If you've got an un-centered GridMap, use this variable to accordingly offset
## where the node checks for grid flooring.
@export
var grid_offset : Vector3

func _ready():
	var parent : Node = get_parent()
	if not parent is CharacterBody3D:
		push_warning("!WARNING!"
		 		+ "\nAn \"AutoFootSteps\" Node has been put somewhere other than a CharacterBody3D node."
				+ "\nThis AutoFootSteps Node has imploded.")
		queue_free()
	else:
		_character_controller = parent as CharacterBody3D

	var new_audio_player : AudioStreamPlayer3D = AudioStreamPlayer3D.new()
	new_audio_player.bus = audio_bus
	_audio_player = new_audio_player
	add_child(new_audio_player)
	_audio_player.stream = AudioStreamPolyphonic.new()
	_audio_player.play()
	_audio_player_playback = _audio_player.get_stream_playback()


	var timer : Timer = Timer.new()
	timer.name = "Timer8th"
	timer.autostart = true
	timer.wait_time = .125
	timer.timeout.connect(self._process_eighth)
	add_child(timer)


var _last_floor_state : bool

var _last_positions : Array[Vector3]
var _last_eighth_pos : Vector3
var _cur_distance_travelled : float

const _xz : Vector3 = Vector3(1, 0, 1)

func _xy_vel_to_speed(vec : Vector3) -> float:
	return (vec*_xz).abs().length() / 2

func _xz_points_to_speed(p1 : Vector3, p2 : Vector3, time : float) -> float:
	return (p1 * _xz).distance_to(p2 * _xz) / time

func _process(_delta):
	if len(_last_positions) != 6:
		return
	var cur_material : FootProfileMaterialSpecification = null

	# Jump/land needs a higher update rate!
	if _last_floor_state and !_character_controller.is_on_floor() and _character_controller.velocity.y > 0:
		_refresh_foot_material(10)
		if cur_material == null:
			cur_material = _get_material()
		_play_random_ordered_sfx_from_arr(cur_material.jumps, cur_material.volume_multiplier)
	elif !_last_floor_state and _character_controller.is_on_floor() and _last_positions[0].y > position.y:
		_refresh_foot_material(10)
		if cur_material == null:
			cur_material = _get_material()
		_play_random_ordered_sfx_from_arr(cur_material.landings, cur_material.volume_multiplier)
	_last_floor_state = _character_controller.is_on_floor()


func _process_eighth():
	_refresh_foot_material()

	_cur_distance_travelled += _last_eighth_pos.distance_to(global_position * _xz)
	_last_eighth_pos = global_position * _xz

	var cur_material : FootProfileMaterialSpecification = null
	# normal footstep logic
	if _cur_distance_travelled > footstep_distance:
		_cur_distance_travelled = 0

		if cur_material == null:
			cur_material = _get_material()
			if cur_material == null:
				return
		var steps_sfx_array : Array[AudioStream]

		var current_speed : float = _character_controller.get_real_velocity().length()
		if current_speed < lerp(crouch_speed, walk_speed, .5):
			steps_sfx_array = cur_material.soft_steps
		elif current_speed > lerp(run_speed, walk_speed, .5):
			steps_sfx_array = cur_material.hard_steps
		else:
			steps_sfx_array = cur_material.med_steps

		_play_random_ordered_sfx_from_arr(steps_sfx_array, cur_material.volume_multiplier)

	# jump/fall/skid/slip logic
	_last_positions.push_front(global_position)
	if len(_last_positions) > 6:
		_last_positions.remove_at(len(_last_positions) - 1)

	if len(_last_positions) == 6:
		# scuff
		if _character_controller.is_on_floor():
			if _xy_vel_to_speed(_character_controller.get_real_velocity()) < crouch_speed:
				var speed_over_time : float = _xz_points_to_speed(_last_positions[0], _last_positions[4], .5)
				if speed_over_time > lerp(walk_speed, run_speed, .5):
					if cur_material == null:
						cur_material = _get_material()
					_play_random_ordered_sfx_from_arr(cur_material.scuffs, cur_material.volume_multiplier)


var _rng : RandomNumberGenerator = RandomNumberGenerator.new()
var _sfx_count : int
func _play_random_ordered_sfx_from_arr(sfx : Array[AudioStream], volume_multiplier : float):
	if len(sfx) == 0:
		return
	_sfx_count = _sfx_count + 1
	var played_sound = sfx[_sfx_count % len(sfx)]
	_audio_player_playback.play_stream(played_sound, 0, volume_db * volume_multiplier, _rng.randf_range(.9, 1.1))
	if _sfx_count % len(sfx) == len(sfx) - 1:
		sfx.shuffle()
		if sfx[0] == played_sound:
			sfx[0] = sfx[len(sfx) - 1]
			sfx[len(sfx) - 1] = played_sound



func _get_mat_fmat(mat : Material) -> FootProfileMaterialSpecification:
	# do if cached
	if mat in _cached_material_materials:
		return foot_profile._material_lookup[_cached_material_materials[mat]]

	# check if resource name is recognized, or path (non-builtin)
	if mat.resource_name != "":
		var mat_fmat = foot_profile._string_to_material(mat.resource_name)
		if mat_fmat.name != AIR_NAME:
			return mat_fmat;
	if mat.resource_path.ends_with(".tres") or mat.resource_path.ends_with(".res"):
		var mat_fmat = foot_profile._string_to_material(mat.resource_path)
		if mat_fmat.name != AIR_NAME:
			return mat_fmat;
	# gather related textures.
	var target_textures : Array[Texture] = []
	# 1st check if this is the most common material: BaseMaterial3D
	var mat_3D : BaseMaterial3D = mat as BaseMaterial3D
	if mat_3D != null:
		target_textures.append(mat_3D.albedo_texture)
	else:
		# 2nd check if this is a custom shader
		var mat_custom : ShaderMaterial = mat as ShaderMaterial
		if mat_custom == null:
			return FootProfile._AIR_MAT_SPEC
		else:
			# how absolutely repulsive! we will need to index through each and every property
			# to find where the user has put their texture fields.
			for property in mat_custom.get_property_list():
				if property["type"] == TYPE_OBJECT:
					var found_texture : Texture = mat_custom.get(property["name"]) as Texture
					if found_texture != null:
						target_textures.append(found_texture)

	for texture in target_textures:
		if texture != null:
			if texture.resource_name != "":
				return foot_profile.string_to_material(texture.resource_name)
			return foot_profile._string_to_material(texture.resource_path)
		else:
			pass

	return FootProfile._AIR_MAT_SPEC

func _refresh_foot_material(ray_distance : float = .5):
	var raycast_response : Dictionary = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(global_position, to_global(Vector3(0, -ray_distance, 0))))
	if "collider" not in raycast_response:
		current_material = AIR_NAME
		return

	if raycast_response["collider"] is GridMap:
		var hit_grid : GridMap = raycast_response["collider"]
		var grid_hit_location : Vector3 = hit_grid.to_local(raycast_response["position"]);
		grid_hit_location = grid_hit_location - Vector3(0, hit_grid.cell_size.y / 2, 0);
		grid_hit_location += grid_offset;
		var hit_cell : int = hit_grid.get_cell_item(hit_grid.local_to_map(grid_hit_location));
		if (hit_cell == GridMap.INVALID_CELL_ITEM):
			current_material = AIR_NAME
			return
		var mesh : Mesh = hit_grid.mesh_library.get_item_mesh(hit_cell);
		if mesh == null:
			current_material = AIR_NAME
			return
		for s_count in mesh.get_surface_count():
			var mat : Material = mesh.surface_get_material(s_count)
			if mat == null:
				continue
			var figured_material : FootProfileMaterialSpecification = _get_mat_fmat(mat);
			if figured_material.name != AIR_NAME:
				_cached_material_materials[mat] = figured_material.name
				current_material = figured_material.name
				return
		current_material = AIR_NAME
		return
	if raycast_response["collider"] is CSGShape3D:
		var hit_CSG : CSGShape3D = raycast_response["collider"]
		var hit_mesh : ArrayMesh = hit_CSG.get_meshes()[1];

		var surface_start = 0;
		var face_id = raycast_response["face_index"]*3;
		for surface_num in len(hit_mesh._surfaces):
			var surface = hit_mesh._surfaces[surface_num];
			if (face_id > surface_start && face_id < surface_start + surface.vertex_count):
				current_material = _get_mat_fmat(surface.material).name;
				return;
			else:
				surface_start = surface_start + surface.vertex_count;
		current_material = AIR_NAME
		return

	var hit_collider : CollisionObject3D = raycast_response["collider"]

	#figure/process if this collider is tagged
	for col_child in hit_collider.get_children():
		if col_child is FootMaterialTag:
			current_material = col_child.foot_material_override
			return

	#figure/process if this collider's material is known already / cached
	if hit_collider in _cached_collider_materials:
		current_material = _cached_collider_materials[hit_collider]
		return

	# check if mat can be extrapolated from collider name
	var figured_material : FootProfileMaterialSpecification = foot_profile._string_to_material(hit_collider.name)

	# if not, check if the parent can
	if figured_material.name == AIR_NAME:
		var col_parent : Node = hit_collider.get_parent()
		figured_material = foot_profile._string_to_material(col_parent.name)
		# if not, check if the parent is a mesh - then check the material's names in order.
		if figured_material.name == AIR_NAME:
			var col_parent_Geo3D : GeometryInstance3D = col_parent as GeometryInstance3D
			if col_parent_Geo3D != null:
				# gather related materials in array
				var target_materials : Array[Material] = [col_parent_Geo3D.material_override]

				var col_parent_mesh3D : MeshInstance3D = col_parent_Geo3D as MeshInstance3D
				if col_parent_mesh3D != null:
					for mat_num in col_parent_mesh3D.get_surface_override_material_count():
						target_materials.append(col_parent_mesh3D.get_surface_override_material(mat_num))
					var col_parent_mesh3D_prim : PrimitiveMesh = col_parent_mesh3D.mesh as PrimitiveMesh
					if col_parent_mesh3D_prim != null:
						target_materials.append(col_parent_mesh3D_prim.material)

				# for each mat
				for mat in target_materials:
					if mat == null:
						continue
					figured_material = _get_mat_fmat(mat);
					if figured_material.name != AIR_NAME:
						_cached_material_materials[mat] = figured_material.name
						break

	_cached_collider_materials[hit_collider] = figured_material.name
	current_material = figured_material.name
