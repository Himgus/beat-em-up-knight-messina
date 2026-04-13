extends "res://scripts/character.gd"

@export var map_width:float=320

func _process(delta: float) -> void:
	super(delta)
	if global_position.x > map_width:
		global_position.x -= map_width
	elif global_position.x<0:
		global_position.x+=map_width
func _physics_process(delta: float) -> void:

	move_and_slide()
