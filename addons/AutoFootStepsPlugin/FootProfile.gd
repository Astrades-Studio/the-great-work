@tool
@icon("res://AutoFootStepsPlugin/FootProfileIcon.png")
extends Resource
class_name FootProfile
## A collection of Material names, keywords, and SFX.

static var _AIR_MAT_SPEC : FootProfileMaterialSpecification

## The name for this Foot Profile. Ex: Barefoot, Boot, Sneakers
@export
var name : StringName:
	get:
		if Engine.is_editor_hint():
			resource_name = name
		return name
	set(value):
		if Engine.is_editor_hint():
			resource_name = value
		name = value

## The Collected sound effects, and their tags.
@export
var materials : Array[FootProfileMaterialSpecification]

var _init : bool
var _material_lookup : Dictionary:
	get:
		if !_init:
			_init = true
			for mat_spec in materials:
				_material_lookup[mat_spec.name] = mat_spec
		return _material_lookup
	set(value):
		_material_lookup = value

func _string_to_material(string : String) -> FootProfileMaterialSpecification:
	string = string.split('/', false)[-1].to_lower()
	for mat_spec in materials:
		for similar_name in mat_spec.similar_names:
			if string.contains(similar_name):
				return mat_spec
	if _AIR_MAT_SPEC == null:
		_AIR_MAT_SPEC = FootProfileMaterialSpecification.new()
		_AIR_MAT_SPEC.name = AutoFootSteps.AIR_NAME
	return _AIR_MAT_SPEC
			
