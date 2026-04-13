extends CharacterBody2D

@export var velocidad :float
@export var hp :int
@export var daño :int
@export var JUMP_VELOCITY:int

enum Estado{IDLE,WALK,ATTACK,ATTACK2,JUMP,FALL,ATTACKNOMOVEMENT}
var attack_on_cooldown=false
var state=Estado.IDLE

func _ready() -> void:
	$AnimatedSprite2D.animation_finished.connect(on_animation_finished)
	$CooldownTimer.timeout.connect(on_cooldown_timer_timeout)

func _process(delta: float) -> void:
	handle_input(delta)
	handle_movement()
	handle_animations()
	flip_sprites()
	move_and_slide()

func handle_movement() -> void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT:
		return
	if velocity.length()!=0 and is_on_floor():
		state=Estado.WALK
	elif not is_on_floor() and velocity.y<0:
		state=Estado.JUMP
	elif not is_on_floor() and velocity.y>0:
		state=Estado.FALL
	else:
		state=Estado.IDLE

func handle_input(delta)->void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var direccion=Input.get_axis("ui_left", "ui_right")
	velocity.x=direccion*velocidad
	
	if Input.is_action_just_pressed("attack") and !attack_on_cooldown and direccion!=0:
		state=Estado.ATTACK
		attack_on_cooldown=true
		$CooldownTimer.start()
	elif Input.is_action_just_pressed("attack") and !attack_on_cooldown and direccion==0:
		state=Estado.ATTACKNOMOVEMENT
		attack_on_cooldown=true
		$CooldownTimer.start()
		

func handle_animations()->void:
	if state==Estado.IDLE:
		$AnimatedSprite2D.play("idle")
	elif state==Estado.WALK:
		$AnimatedSprite2D.play("walk")
	elif state==Estado.JUMP:
		$AnimatedSprite2D.play("jump")
	elif state==Estado.FALL:
		$AnimatedSprite2D.play("fall")
	elif state==Estado.ATTACK:
		$AnimatedSprite2D.play("attack")
	elif state==Estado.ATTACKNOMOVEMENT:
		$AnimatedSprite2D.play("attackNoMovement")
	
func flip_sprites()->void:
	if velocity.x>0:
		$AnimatedSprite2D.flip_h=false
	elif velocity.x<0:
		$AnimatedSprite2D.flip_h=true

func on_animation_finished()->void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT:
		state=Estado.IDLE

func on_cooldown_timer_timeout()->void:
	attack_on_cooldown=false

func can_attack()->bool:
	return state==Estado.IDLE or state==Estado.WALK or state==Estado.JUMP or state==Estado.FALL
func can_move()->bool:
	return state==Estado.IDLE or state==Estado.WALK or state==Estado.JUMP or state==Estado.FALL
