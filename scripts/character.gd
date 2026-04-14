extends CharacterBody2D

@export var velocidad :float
@export var hp :int
@export var daño :int
@export var JUMP_VELOCITY:int

enum Estado{IDLE,WALK,ATTACK,ATTACK2,JUMP,FALL,ATTACKNOMOVEMENT}

var animacion_map:={
	Estado.IDLE:"idle",
	Estado.WALK:"walk",
	Estado.ATTACK:"attack",
	Estado.ATTACK2:"attack2",
	Estado.ATTACKNOMOVEMENT:"attackNoMovement",
	Estado.JUMP:"jump",
	Estado.FALL:"fall"
}

var attack_on_cooldown:bool=false
var damage_applied:bool=false
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
	handle_damage()

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
		damage_applied=false
		$CooldownTimer.start()
	elif Input.is_action_just_pressed("attack") and !attack_on_cooldown and direccion==0:
		state=Estado.ATTACKNOMOVEMENT
		attack_on_cooldown=true
		damage_applied=false
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
		$damage_emitter.scale.x=1
	elif velocity.x<0:
		$AnimatedSprite2D.flip_h=true
		$damage_emitter.scale.x=-1

func on_animation_finished()->void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT:
		state=Estado.IDLE

func on_cooldown_timer_timeout()->void:
	attack_on_cooldown=false

func can_attack()->bool:
	return state==Estado.IDLE or state==Estado.WALK or state==Estado.JUMP or state==Estado.FALL
func can_move()->bool:
	return state==Estado.IDLE or state==Estado.WALK or state==Estado.JUMP or state==Estado.FALL

func handle_damage()-> void:
	if damage_applied:
		return
	if ($AnimatedSprite2D.frame==2 or $AnimatedSprite2D.frame==3) and (state==Estado.ATTACK or state==Estado.ATTACKNOMOVEMENT):
		for area in $damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area)
		damage_applied=true
		
func apply_damage_emitted(damage_reciever: damage_Reciever)->void:
	var direccion:Vector2
	if damage_reciever.global_position.x<global_position.x:
		direccion=Vector2.LEFT
	else:
		direccion=Vector2.RIGHT
	damage_reciever.damage_recieved.emit(daño, direccion)
	print(damage_reciever)
