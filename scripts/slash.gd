extends Area2D

@onready var animated_sprite:=$AnimatedSprite2D
var player:baseCharacter
var hit_type:int
var already_hit:Array=[]
var on_hit:Callable

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_default_terminado)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.play("default")

func _on_frame_changed()->void:
	for area in get_overlapping_areas():
		if area not in already_hit:
			player.apply_damage_emitted(area,hit_type)
			already_hit.append(area)
			if on_hit.is_valid():
				on_hit.call(player.daño)
	
	
func _on_default_terminado()->void:
	queue_free()
