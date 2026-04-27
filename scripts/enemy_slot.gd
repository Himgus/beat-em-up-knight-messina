class_name EnemySlot
extends Node2D

var occupant:Node=null


func is_free()->bool:
	return occupant==null
	
func free_slot()->void:
	occupant=null
	
func take_slot(enemy:Node)->void:
	occupant=enemy
