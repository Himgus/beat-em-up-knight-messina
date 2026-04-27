extends baseCharacter
class_name BossHelper

@export var player:Player
@export var duration_between_hits:int
@export var duration_prep_hit:int

enum Estado{IDLE,WALK,HURT,DEATH,ATTACK,PREPATTACK,JUMP,FALL}

var player_slot:EnemySlot=null
var state=Estado.IDLE
var knocked_down:bool=false
var stun_timer:=0.0
var wall_launched:bool=false
var wall_bounce_done:bool=false
var pre_wall_velocity_x:float=0.0
var time_since_last_hit:=Time.get_ticks_msec()
var time_since_prep_hit:=Time.get_ticks_msec()

var animacion_map:Dictionary={
	Estado.IDLE:"idle",
	Estado.WALK:"walk",
	Estado.DEATH:"death",
	Estado.HURT:"hurt",
	Estado.ATTACK:"attack",
	Estado.PREPATTACK:"idle",
	Estado.JUMP:"jump",
	Estado.FALL:"fall"
}

func _ready()->void:
	super()
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())

func _process(delta:float)->void:
	super(delta)
	handle_prep_attack()

func handle_input(_delta:float)->void:
	if not is_on_floor():
		velocity+=get_gravity()*_delta
	if state==Estado.HURT:
		if stun_timer>0:
			stun_timer-=_delta
			damage_reciever.monitorable=false
		if wall_launched and not wall_bounce_done:
			if not is_on_wall():
				pre_wall_velocity_x=velocity.x
			else:
				var collision=get_last_slide_collision()
				if collision and not collision.get_collider() is BossHelper:
					velocity.x=-pre_wall_velocity_x*0.6
					velocity.y=-knockback*0.3
					wall_bounce_done=true
		if is_on_floor():
			velocity.x=move_toward(velocity.x,0,300*_delta)
			if wall_launched and wall_bounce_done:
				velocity.x=0
				wall_launched=false
				wall_bounce_done=false
			elif knocked_down and wall_bounce_done:
				knocked_down=false
				damage_reciever.monitorable=true
		return
	if knocked_down:
		if is_on_floor():
			knocked_down=false
			damage_reciever.monitorable=true
		return
	if state==Estado.DEATH:
		if is_on_floor():
			velocity.x=move_toward(velocity.x,0,300*_delta)
		return
	if player!=null:
		if player_slot==null:
			player_slot=player.reserve_slot(self)
		if player_slot!=null:
			var direccion=sign(player_slot.global_position.x-position.x)
			if player_on_range():
				velocity=Vector2.ZERO
				if can_attack():
					state=Estado.PREPATTACK
					time_since_prep_hit=Time.get_ticks_msec()
			elif state==Estado.ATTACK or state==Estado.PREPATTACK:
				velocity.x=0
			else:
				velocity.x=direccion*velocidad

func handle_animations()->void:
	if animacion_map.has(state):
		animated_sprite.play(animacion_map[state])

func player_on_range()->bool:
	return abs(player_slot.global_position.x-position.x)<1

func handle_movement()->void:
	if state==Estado.ATTACK or state==Estado.HURT or state==Estado.DEATH or state==Estado.PREPATTACK or knocked_down:
		return
	if not is_on_floor() and velocity.y<0:
		state=Estado.JUMP
	elif not is_on_floor() and velocity.y>0:
		state=Estado.FALL
	elif velocity.length()!=0 and is_on_floor():
		state=Estado.WALK
	else:
		state=Estado.IDLE

func on_recieve_damage(damage:int,direccion:Vector2,hit_type:Damage_Reciever.Hit_type)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		state=Estado.DEATH
		player.free_slot(self)
		handle_fall(direccion)
	else:
		state=Estado.HURT
		knocked_down=true
		stun_timer=0.5
		velocity.x=direccion.x*knockback
		velocity.y=-knockback
		damage_reciever.monitorable=false

func on_animation_finished()->void:
	if state==Estado.HURT:
		state=Estado.IDLE
	elif state==Estado.DEATH:
		queue_free()
	elif state==Estado.ATTACK:
		state=Estado.IDLE

func handle_fall(direccion:Vector2)->void:
	velocity.x=randf_range(100,200)*direccion.x
	velocity.y=randf_range(-200,-100)
	animated_sprite.flip_h=direccion.x>0
	animated_sprite.rotation=randf_range(-0.5,0.5)

func handle_damage()->void:
	if damage_applied:
		return
	if state==Estado.ATTACK and animated_sprite.animation=="attack":
		if animated_sprite.frame==3 or animated_sprite.frame==4:
			for area in damage_emitter.get_overlapping_areas():
				apply_damage_emitted(area,Damage_Reciever.Hit_type.NORMAL)
			damage_applied=true

func flip_sprites()->void:
	if player==null or state==Estado.DEATH:
		return
	var facing_right=player.global_position.x>global_position.x
	animated_sprite.flip_h=!facing_right
	if facing_right:
		damage_emitter.scale.x=1
		damage_reciever.scale.x=1
	else:
		damage_emitter.scale.x=-1
		damage_reciever.scale.x=-1

func can_attack()->bool:
	if Time.get_ticks_msec()-time_since_last_hit<duration_between_hits:
		return false
	return is_on_floor() and state!=Estado.HURT and state!=Estado.DEATH and state!=Estado.ATTACK and state!=Estado.PREPATTACK

func handle_prep_attack()->void:
	if state==Estado.PREPATTACK and (Time.get_ticks_msec()-time_since_prep_hit>duration_prep_hit):
		state=Estado.ATTACK
		time_since_last_hit=Time.get_ticks_msec()
		damage_applied=false
