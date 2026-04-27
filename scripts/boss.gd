extends "res://scripts/character.gd"
class_name Boss

@export var player:Player
@export var run_velocity:float
@export var roll_velocity:float
@export var jump_attack_velocity:float
@onready var damage_emitter_jump_attack:=$damage_emitter_jump_attack

enum Estado{IDLE,WALK,ATTACK,ATTACK2,ATTACKNOMOVEMENT2,JUMP,FALL,ATTACKNOMOVEMENT,ROLL,TURN_AROUND,RUN,JUMPSPECIFICATTACK,HURT,DEATH,DASH}

var animacion_map:Dictionary={
	Estado.IDLE:"idle",
	Estado.WALK:"walk",
	Estado.JUMP:"jump",
	Estado.FALL:"fall",
	Estado.ATTACK:"attack",
	Estado.ATTACK2:"attack2",
	Estado.ATTACKNOMOVEMENT:"attackNoMovement",
	Estado.ATTACKNOMOVEMENT2:"attack2NoMovement",
	Estado.TURN_AROUND:"turn_around",
	Estado.ROLL:"roll",
	Estado.RUN:"walk",
	Estado.JUMPSPECIFICATTACK:"jump_specific_attack",
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
var decision_timer:float=0.0
var decision_interval:float=0.8
var chase_player:bool=true

func _ready()->void:
	super()
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	animated_sprite.frame_changed.connect(on_frame_changed)

func _process(delta:float)->void:
	super(delta)
	if player!=null:
		decision_timer+=delta
		if decision_timer>=decision_interval:
			decision_timer=0.0
			_make_decision()

func _make_decision()->void:
	if state==Estado.HURT or state==Estado.DEATH or state==Estado.ROLL or state==Estado.DASH or state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.ATTACKNOMOVEMENT2 or state==Estado.JUMPSPECIFICATTACK:
		return
	var dist=global_position.distance_to(player.global_position)
	# react to player attacking — roll or dash away
	if player.state in [Player.Estado.ATTACK,Player.Estado.ATTACK2,Player.Estado.ATTACKNOMOVEMENT,Player.Estado.ATTACKNOMOVEMENT2]:
		var roll=randf()
		if roll<0.5:
			state=Estado.ROLL
			return
		elif roll<0.7:
			state=Estado.DASH
			return
	# close range decisions
	if dist<80:
		var roll=randf()
		if roll<0.3:
			_do_attack()
		elif roll<0.5:
			state=Estado.ROLL
		elif roll<0.65:
			chase_player=false
		else:
			chase_player=true
	# mid range decisions
	elif dist<200:
		var roll=randf()
		if roll<0.4:
			_do_attack()
		elif roll<0.55:
			_do_jump_attack()
		elif roll<0.7:
			chase_player=true
		else:
			chase_player=false
	# far range decisions
	else:
		var roll=randf()
		if roll<0.3:
			_do_jump_attack()
		elif roll<0.5:
			state=Estado.RUN
		else:
			chase_player=true

func _do_attack()->void:
	if attack_on_cooldown:
		return
	var moving=abs(velocity.x)>10
	if randf()<0.5 and moving:
		state=Estado.ATTACK
	else:
		state=Estado.ATTACKNOMOVEMENT
	attack_on_cooldown=true
	damage_applied=false
	cooldown_timer.start()
	if randf()<0.4:
		attack2_queued=true

func _do_jump_attack()->void:
	if is_on_floor() and not attack_on_cooldown:
		velocity.y=JUMP_VELOCITY
		jumped_from_run=true

func handle_input(delta)->void:
	if not is_on_floor():
		velocity+=get_gravity()*delta
	if state==Estado.HURT or state==Estado.DEATH:
		return
	if player==null:
		return
	var dir_to_player=sign(player.global_position.x-global_position.x)
	if state==Estado.JUMPSPECIFICATTACK:
		velocity.x=last_dir*jump_attack_velocity
	elif state==Estado.RUN or (jumped_from_run and (state==Estado.JUMP or state==Estado.FALL)):
		velocity.x=dir_to_player*run_velocity
		if not is_on_floor() and jumped_from_run and not attack_on_cooldown:
			state=Estado.JUMPSPECIFICATTACK
			attack_on_cooldown=true
			damage_applied=false
			damage_emitter_jump_attack.scale.x=last_dir
			cooldown_timer.start()
	elif state==Estado.ROLL:
		velocity.x=last_dir*roll_velocity
	elif state==Estado.DASH:
		velocity.x=last_dir*(roll_velocity*1.3)
	elif state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.ATTACKNOMOVEMENT2:
		velocity.x=0
	elif chase_player:
		velocity.x=dir_to_player*velocidad
	else:
		velocity.x=move_toward(velocity.x,0,velocidad)

func handle_animations()->void:
	if animacion_map.has(state):
		var anim=animacion_map[state]
		if animated_sprite.animation!=anim or not animated_sprite.is_playing():
			animated_sprite.play(anim)

func handle_movement()->void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.TURN_AROUND or state==Estado.ROLL or state==Estado.JUMPSPECIFICATTACK or state==Estado.DASH or state==Estado.ATTACKNOMOVEMENT2 or state==Estado.HURT or state==Estado.DEATH:
		return
	if state==Estado.RUN:
		if not is_on_floor() and velocity.y<0:
			state=Estado.JUMP
		elif not is_on_floor() and velocity.y>0:
			state=Estado.FALL
		return
	if velocity.length()!=0 and is_on_floor():
		jumped_from_run=false
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
			damage_emitter_jump_attack.scale.x=1
			damage_reciever.scale.x=1
		elif pending_flip<0:
			animated_sprite.flip_h=true
			damage_emitter_jump_attack.scale.x=-1
			damage_emitter.scale.x=-1
			damage_reciever.scale.x=-1
		last_dir=pending_flip
		pending_flip=0.0
		state=state_after_turn as Estado
		state_after_turn=Estado.IDLE
		return
	if state==Estado.ROLL:
		state=Estado.IDLE
		return
	if state==Estado.DASH:
		state=Estado.FALL
		return
	if state==Estado.HURT:
		state=Estado.IDLE
		damage_reciever.monitoring=true
		return
	if state==Estado.DEATH:
		queue_free()
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
	if state==Estado.TURN_AROUND or state==Estado.ROLL or state==Estado.JUMP or state==Estado.FALL or state==Estado.JUMPSPECIFICATTACK:
		return
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT or state==Estado.ATTACKNOMOVEMENT2:
		return
	if velocity.x>0 and last_dir<0:
		state_after_turn=state
		state=Estado.TURN_AROUND
		pending_flip=1.0
	elif velocity.x<0 and last_dir>0:
		state_after_turn=state
		state=Estado.TURN_AROUND
		pending_flip=-1.0

func on_recieve_damage(damage:int,_direccion:Vector2,hit_type:Damage_Reciever.Hit_type)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		state=Estado.DEATH
	else:
		state=Estado.HURT
		velocity.x=0
		# chance to immediately counter after being hit
		if randf()<0.3:
			attack2_queued=true

func handle_damage()->void:
	if damage_applied:
		return
	if (state==Estado.ATTACK or state==Estado.ATTACKNOMOVEMENT) and (animated_sprite.frame==2 or animated_sprite.frame==3):
		for area in damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area,Damage_Reciever.Hit_type.NORMAL)
		damage_applied=true
	if (state==Estado.ATTACK2 or state==Estado.ATTACKNOMOVEMENT2) and (animated_sprite.frame==2 or animated_sprite.frame==3):
		for area in damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area,Damage_Reciever.Hit_type.KNOCKDOWN)
		damage_applied=true
	if state==Estado.JUMPSPECIFICATTACK and (animated_sprite.frame==1 or animated_sprite.frame==2 or animated_sprite.frame==3):
		for area in damage_emitter_jump_attack.get_overlapping_areas():
			apply_damage_emitted(area,Damage_Reciever.Hit_type.POWER)
		damage_applied=true

func on_frame_changed()->void:
	if not is_inside_tree():
		return
	if state==Estado.ROLL or state==Estado.HURT or state==Estado.DEATH:
		damage_reciever.monitoring=animated_sprite.frame not in [2,3,4,5,6,7,8,9]
	elif state==Estado.DASH:
		damage_reciever.monitoring=false
	else:
		damage_reciever.monitoring=true
