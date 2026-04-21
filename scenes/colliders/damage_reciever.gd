class_name Damage_Reciever
extends Area2D

enum Hit_type{NORMAL,KNOCKDOWN,POWER}

signal damage_recieved(damage:int, direccion:Vector2, hit_type:Hit_type)
