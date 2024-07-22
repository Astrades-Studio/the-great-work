@tool
extends Resource
class_name FootProfileMaterialSpecification
## A grouping of SFX and tags.

## The name for this specific Material; Used for labelling only.
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

@export
var volume_multiplier : float = 1

## Tags, used for detecting what material an asset goes with.
@export
var similar_names : Array[String]:
	get:
		if Engine.is_editor_hint():
			for i in len(similar_names):
				similar_names[i] = similar_names[i].to_lower()
		return similar_names
	set(value):
		similar_names = value

## Soft footsteps for crouching
@export
var soft_steps : Array[AudioStream]
## Medium footsteps for walking
@export
var med_steps : Array[AudioStream]
## Hard footsteps for running
@export
var hard_steps : Array[AudioStream]

## Scuffs, for abrupt stops & slips.
@export
var scuffs : Array[AudioStream]

## Jumping off of the material SFX
@export
var jumps : Array[AudioStream]

## Landing onto the material SFX
@export
var landings : Array[AudioStream]
