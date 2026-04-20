extends "res://scripts/character.gd"

class_name Player

@export var map_width:float=320
@export var run_velocity:float
@export var roll_velocity:float
@export var jump_attack_velocity:float



enum Estado{IDLE,WALK,ATTACK,ATTACK2,JUMP,FALL,ATTACKNOMOVEMENT,ROLL,TURN_AROUND,RUN,JUMPSPECIFICATTACK,HURT,DEATH}

var animacion_map:Dictionary={
	Estado.IDLE: "idle",
	Estado.WALK: "walk",
	Estado.JUMP: "jump",
	Estado.FALL: "fall",
	Estado.ATTACK: "attack",
	Estado.ATTACKNOMOVEMENT: "attackNoMovement",
	Estado.TURN_AROUND: "turn_around",
	Estado.ROLL: "roll",
	Estado.RUN: "walk",
	Estado.JUMPSPECIFICATTACK: "jump_specific_attack",
	Estado.HURT:"hurt",
	Estado.DEATH:"death"
}

var state=Estado.IDLE

var state_after_turn:int=Estado.IDLE
var last_dir:=1.0
var pending_flip:float=0.0
var jumped_from_run:bool=false

func _ready() -> void:
	super()
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())

func _process(delta: float) -> void:
	super(delta)


func handle_input(delta)->void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and state!=Estado.ROLL:
		velocity.y = JUMP_VELOCITY
		jumped_from_run=state==Estado.RUN
	var direccion=Input.get_axis("left", "right")
	
	
	if state==Estado.JUMPSPECIFICATTACK:
		velocity.x=last_dir*jump_attack_velocity
	elif state==Estado.RUN or (jumped_from_run and (state==Estado.JUMP or state==Estado.FALL)):
		velocity.x=direccion*run_velocity
	elif state==Estado.ROLL:
		velocity.x=last_dir*roll_velocity
	else:
		velocity.x=direccion*velocidad

	if Input.is_action_just_pressed("roll") and state!=Estado.ROLL and state!=Estado.RUN:
		state=Estado.ROLL

	if Input.is_action_just_released("roll") and state==Estado.RUN:
		state=Estado.IDLE

	if Input.is_action_just_pressed("attack") and !attack_on_cooldown:
		if not is_on_floor() and jumped_from_run:
			state=Estado.JUMPSPECIFICATTACK
			attack_on_cooldown=true
			damage_applied=false
			$CooldownTimer.start()
		elif is_on_floor() and direccion!=0:
			state=Estado.ATTACK
			attack_on_cooldown=true
			damage_applied=false
			$CooldownTimer.start()
		elif is_on_floor() and direccion==0:
			state=Estado.ATTACKNOMOVEMENT
			attack_on_cooldown=true
			damage_applied=false
			$CooldownTimer.start()
		else:
			return

func handle_animations()->void:
	if animacion_map.has(state):
		$AnimatedSprite2D.play(animacion_map[state])

func handle_movement() -> void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.TURN_AROUND or state==Estado.ROLL or state==Estado.JUMPSPECIFICATTACK:
		return
	if state==Estado.RUN:
		if not is_on_floor() and velocity.y<0:
			state=Estado.JUMP
		elif not is_on_floor() and velocity.y>0:
			state=Estado.FALL
		return
	if velocity.length()!=0 and is_on_floor():
		jumped_from_run=false
		if Input.is_action_pressed("roll"):
			state=Estado.RUN
		else:
			state=Estado.WALK
	elif not is_on_floor() and velocity.y<0:
		state=Estado.JUMP
	elif not is_on_floor() and velocity.y>0:
		state=Estado.FALL
	else:
		state=Estado.IDLE


func on_animation_finished()->void:
	if state==Estado.TURN_AROUND:
		if pending_flip>0:
			$AnimatedSprite2D.flip_h=false
			$damage_emitter.scale.x=1
			damage_reciever.scale.x=1
			$character_collision.position.x=abs($character_collision.position.x)
		elif pending_flip<0:
			$AnimatedSprite2D.flip_h=true
			$damage_emitter.scale.x=-1
			damage_reciever.scale.x=-1
			$character_collision.position.x=-abs($character_collision.position.x)
		last_dir=pending_flip
		pending_flip=0.0
		state=state_after_turn as Estado
		state_after_turn=Estado.IDLE
		return
	if state==Estado.ROLL:
		if Input.is_action_pressed("roll") and Input.get_axis("left", "right")!=0:
			state=Estado.RUN
		else:
			state=Estado.IDLE
		return
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.JUMPSPECIFICATTACK:
		state=Estado.IDLE


func can_attack()->bool:
	return state==Estado.IDLE or state==Estado.WALK or state==Estado.JUMP or state==Estado.FALL
func can_move()->bool:
	return state==Estado.IDLE or state==Estado.WALK or state==Estado.JUMP or state==Estado.FALL
	

func flip_sprites()->void:
	if state==Estado.TURN_AROUND or state==Estado.ROLL or state==Estado.JUMP or state==Estado.FALL:
		return
	if velocity.x>0 and last_dir<0:
		state_after_turn = state
		state=Estado.TURN_AROUND
		pending_flip=1.0
	elif velocity.x<0 and last_dir>0:
		state_after_turn = state
		state=Estado.TURN_AROUND
		pending_flip=-1.0


func on_recieve_damage(damage:int, direccion:Vector2)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		state=Estado.DEATH
	else:
		state=Estado.HURT

func handle_damage()-> void:
	if damage_applied:
		return
	if ($AnimatedSprite2D.frame==2 or $AnimatedSprite2D.frame==3) and (state==Estado.ATTACK or state==Estado.ATTACKNOMOVEMENT):
		for area in $damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area)
		damage_applied=true
