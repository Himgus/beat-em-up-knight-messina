class_name ArcherSlot
extends Node2D

var occupant:Archer=null


func is_free()->bool:
	return occupant==null
	
func free_slot()->void:
	occupant=null
	
func take_slot(enemy:Archer)->void:
	occupant=enemy
