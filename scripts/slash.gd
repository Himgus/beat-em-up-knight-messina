extends Area2D

@onready var animated_sprite:=$AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#look_at("vardirpj")
	animated_sprite.animation_finished.connect(_on_default_terminado)
	animated_sprite.play("default")
	pass


func _on_body_entered(body:Node2D)->void:
	pass
	
	
func _on_default_terminado()->void:
	pass
