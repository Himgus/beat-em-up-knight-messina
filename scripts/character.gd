extends CharacterBody2D

@export var velocidad :float
@export var hp :int
@export var daño :int


func _process(delta: float) -> void:
	
	var direccion=Input.get_axis("ui_left", "ui_right")
	velocity=Vector2(direccion*velocidad,velocity.y)
	if direccion != 0:
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = direccion < 0
	move_and_slide()
