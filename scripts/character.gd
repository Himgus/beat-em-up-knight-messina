extends CharacterBody2D

@export var velocidad :float
@export var hp :int
@export var daño :int
@export var JUMP_VELOCITY:int

enum Estado{IDLE,WALK,ATTACK,ATTACK2}

var state=Estado.IDLE

func handle_movement() -> void:
	if velocity.length()==0:
		state=Estado.IDLE
	else:
		state=Estado.WALK

func handle_input(delta)->void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var direccion=Input.get_axis("ui_left", "ui_right")
	velocity.x=direccion*velocidad



func _process(delta: float) -> void:
	
	
	if direccion != 0 and is_on_floor(): 
		$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.flip_h = direccion < 0
	elif not is_on_floor() and velocity.y<0:
		$AnimatedSprite2D.play("jump")
		$AnimatedSprite2D.flip_h = direccion < 0
	elif not is_on_floor() and velocity.y>0:
		$AnimatedSprite2D.play("fall")
		$AnimatedSprite2D.flip_h = direccion < 0
	else:
		$AnimatedSprite2D.play("idle")
	move_and_slide()
