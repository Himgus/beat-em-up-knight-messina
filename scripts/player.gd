extends "res://scripts/character.gd"

class_name Player

@export var map_width:float=320
@export var run_velocity:float
@export var roll_velocity:float
@export var jump_attack_velocity:float

@onready var enemy_slots:Array=$EnemySlots.get_children()
@onready var damage_emitter_jump_attack:=$damage_emitter

enum Estado{IDLE,WALK,ATTACK,ATTACK2,ATTACKNOMOVEMENT2,JUMP,FALL,ATTACKNOMOVEMENT,ROLL,TURN_AROUND,RUN,JUMPSPECIFICATTACK,HURT,DEATH,DASH}

var animacion_map:Dictionary={
	Estado.IDLE: "idle",
	Estado.WALK: "walk",
	Estado.JUMP: "jump",
	Estado.FALL: "fall",
	Estado.ATTACK: "attack",
	Estado.ATTACK2: "attack2",
	Estado.ATTACKNOMOVEMENT: "attackNoMovement",
	Estado.ATTACKNOMOVEMENT2:"attack2NoMovement",
	Estado.TURN_AROUND: "turn_around",
	Estado.ROLL: "roll",
	Estado.RUN: "walk",
	Estado.JUMPSPECIFICATTACK: "jump_specific_attack",
	Estado.HURT:"hurt",
	Estado.DEATH:"death",
	Estado.DASH:"dash"
}

var state=Estado.IDLE
var attack2_queued:bool=false
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
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and state!=Estado.ROLL and state!=Estado.DASH:
		velocity.y = JUMP_VELOCITY
		jumped_from_run=state==Estado.RUN
	var direccion=Input.get_axis("left", "right")
	
	
	if state==Estado.JUMPSPECIFICATTACK:
		velocity.x=last_dir*jump_attack_velocity
	elif state==Estado.RUN or (jumped_from_run and (state==Estado.JUMP or state==Estado.FALL)):
		velocity.x=direccion*run_velocity
	elif state==Estado.ROLL:
		velocity.x=last_dir*roll_velocity
	elif state==Estado.DASH:
		velocity.x=last_dir*(roll_velocity*1.3)
	else:
		velocity.x=direccion*velocidad

	if Input.is_action_just_pressed("roll") and state!=Estado.ROLL and state!=Estado.RUN and state!=Estado.DASH:
		if is_on_floor():
			state=Estado.ROLL
		else:
			state=Estado.DASH

	if Input.is_action_just_released("roll") and state==Estado.RUN:
		state=Estado.IDLE

	if Input.is_action_just_pressed("attack"):
		if !attack_on_cooldown and state!=Estado.ATTACK2 and state!=Estado.ATTACKNOMOVEMENT2:
			if not is_on_floor() and jumped_from_run:
				state=Estado.JUMPSPECIFICATTACK
				attack_on_cooldown=true
				damage_applied=false
				cooldown_timer.start()
			elif is_on_floor() and direccion!=0:
				state=Estado.ATTACK
				attack_on_cooldown=true
				damage_applied=false
				cooldown_timer.start()
			elif is_on_floor() and direccion==0:
				state=Estado.ATTACKNOMOVEMENT
				attack_on_cooldown=true
				damage_applied=false
				cooldown_timer.start()
		elif state==Estado.ATTACK or state==Estado.ATTACKNOMOVEMENT:
			attack2_queued=true

func handle_animations()->void:
	if animacion_map.has(state):
		animated_sprite.play(animacion_map[state])

func handle_movement() -> void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.TURN_AROUND or state==Estado.ROLL or state==Estado.JUMPSPECIFICATTACK or state==Estado.DASH or state==Estado.ATTACKNOMOVEMENT2:
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
			animated_sprite.flip_h=false
			damage_emitter.scale.x=1
			damage_reciever.scale.x=1
		elif pending_flip<0:
			animated_sprite.flip_h=true
			damage_emitter.scale.x=-1
			damage_reciever.scale.x=-1
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
	if state==Estado.DASH:
		state=Estado.FALL
		return
	if state==Estado.ATTACK or state==Estado.ATTACKNOMOVEMENT or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT2 or state==Estado.JUMPSPECIFICATTACK:
		if attack2_queued and state==Estado.ATTACK:
			state=Estado.ATTACK2
			attack2_queued=false
			damage_applied=false
			cooldown_timer.start()
		elif attack2_queued and state==Estado.ATTACKNOMOVEMENT:
			state=Estado.ATTACKNOMOVEMENT2
			attack2_queued=false
			damage_applied=false
			cooldown_timer.start()
		else:
			attack2_queued=false
			state=Estado.IDLE

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


func on_recieve_damage(damage:int, _direccion:Vector2, hit_type:Damage_Reciever.Hit_type)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		state=Estado.DEATH
	else:
		state=Estado.HURT

func handle_damage()-> void:
	if damage_applied:
		return
	if (state==Estado.ATTACK or state==Estado.ATTACKNOMOVEMENT) and (animated_sprite.frame==2 or animated_sprite.frame==3):
		for area in damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area, Damage_Reciever.Hit_type.NORMAL)
		damage_applied=true
	if (state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT2) and (animated_sprite.frame==2 or animated_sprite.frame==3):
		for area in damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area, Damage_Reciever.Hit_type.KNOCKDOWN)
		damage_applied=true
	if state==Estado.JUMPSPECIFICATTACK and animated_sprite.frame==2:
		for area in damage_emitter_jump_attack.get_overlapping_areas():
			apply_damage_emitted(area, Damage_Reciever.Hit_type.POWER)
		damage_applied=true


func reserve_slot(enemy:Enemy)->EnemySlot:
	var available_slots:=enemy_slots.filter(func(slot):return slot.is_free())
	
	if available_slots.size()==0:
		return null
	
	available_slots.sort_custom(
		func(a:EnemySlot,b:EnemySlot):
			var dist_a=(enemy.global_position-a.global_position).length()
			var dist_b=(enemy.global_position-b.global_position).length()
			return dist_a<dist_b
	)
	available_slots[0].take_slot(enemy)
	return available_slots[0]


func free_slot(enemy:Enemy)->void:
	var target_slots:=enemy_slots.filter(
		func(slot:EnemySlot):return slot.occupant==enemy
	)
	if target_slots.size()==1:
		target_slots[0].free_slot()
