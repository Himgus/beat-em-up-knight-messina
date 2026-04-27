extends baseCharacter
class_name Enemy

@export var player:Player
@export var duration_between_hits:int
@export var duration_prep_hit:int

@onready var collateral_damage_emitter:=$collateral_damage_emitter
@onready var sfx_walk:AudioStreamPlayer2D=$SFXWalk
@onready var sfx_attack:AudioStreamPlayer2D=$SFXAttack
@onready var sfx_do_damage:AudioStreamPlayer2D=$SFXDoDamage
@onready var sfx_take_damage:AudioStreamPlayer2D=$SFXTakeDamage
@onready var sfx_death:AudioStreamPlayer2D=$SFXDeath

enum Estado{IDLE,WALK,DEATH,HURT,ATTACK,ATTACK2,PREPATTACK}

var player_slot:EnemySlot=null
var state=Estado.IDLE
var altura:=0.0
var altura_velocidad:=0.0
var knocked_down:bool=false
var stun_timer:=0.0
var wall_launched:bool=false
var wall_bounce_done:bool=false
var pre_wall_velocity_x:float=0.0
var already_hit_collateral:Array=[]
var time_since_last_hit:=Time.get_ticks_msec()
var time_since_prep_hit:=Time.get_ticks_msec()

var animacion_map:Dictionary={
	Estado.IDLE: "idle",
	Estado.WALK: "walk",
	Estado.DEATH: "death",
	Estado.HURT: "hurt",
	Estado.ATTACK: "attack",
	Estado.ATTACK2: "attack2",
	Estado.PREPATTACK:"idle"
}

func _ready() -> void:
	super()
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	collateral_damage_emitter.area_entered.connect(on_collateral_area_entered)
	animated_sprite.frame_changed.connect(on_frame_changed)

func _process(delta: float) -> void:
	super(delta)


func handle_input(_delta: float) -> void:
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
				if collision and not collision.get_collider() is Enemy:
					velocity.x=-pre_wall_velocity_x*0.6
					velocity.y=-knockback*0.3
					wall_bounce_done=true
		if is_on_floor():
			velocity.x=move_toward(velocity.x, 0, 300*_delta)
			if wall_launched and wall_bounce_done:
				velocity.x=0
				wall_launched=false
				wall_bounce_done=false
				already_hit_collateral.clear()
				collateral_damage_emitter.monitoring=false
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
			velocity.x = move_toward(velocity.x, 0, 300 * _delta)
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
			else:
				velocity.x=direccion*velocidad
		


func handle_animations() -> void:
	if animacion_map.has(state):
		animated_sprite.play(animacion_map[state])

func player_on_range()->bool:
	return abs(player_slot.global_position.x-position.x)<1

func handle_movement() -> void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.HURT or state==Estado.DEATH or state==Estado.PREPATTACK or knocked_down:
		stop_walk_sfx()
		return
	if velocity.length()!=0 and is_on_floor():
		state=Estado.WALK
		play_walk_sfx()
	else:
		state=Estado.IDLE
		stop_walk_sfx()

func on_recieve_damage(damage:int, direccion:Vector2, hit_type:Damage_Reciever.Hit_type)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		sfx_death.play()
		state=Estado.DEATH
		player.free_slot(self)
		handle_fall(direccion)
	else:
		sfx_take_damage.play()
		match hit_type:
			Damage_Reciever.Hit_type.KNOCKDOWN:
				state=Estado.HURT
				knocked_down=true
				stun_timer=0.5
				velocity.x=direccion.x*knockback
				velocity.y=-knockback
				damage_reciever.monitorable=false
				print(current_hp)
			Damage_Reciever.Hit_type.POWER:
				state=Estado.HURT
				knocked_down=true
				stun_timer=1.0
				damage_reciever.monitorable=false
				wall_launched=true
				wall_bounce_done=false
				collateral_damage_emitter.monitoring=true
				velocity.x=direccion.x*knockback*3
				velocity.y=-knockback
				print(current_hp)
			_:
				state=Estado.HURT
				print(current_hp)
				velocity=Vector2.ZERO

func on_animation_finished()->void:
	if state==Estado.HURT:
		if stun_timer<=0:
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


func handle_damage()-> void:
	if damage_applied:
		return
	if state==Estado.ATTACK and (animated_sprite.animation=="attack"):
		if (animated_sprite.frame==3 or animated_sprite.frame==4):
			for area in damage_emitter.get_overlapping_areas():
				apply_damage_emitted(area, Damage_Reciever.Hit_type.NORMAL)
			damage_applied=true
			sfx_do_damage.play()


func on_collateral_area_entered(area:Area2D)->void:
	if not wall_launched or wall_bounce_done:
		return
	if not area is Damage_Reciever:
		return
	if area==damage_reciever:
		return
	if area not in already_hit_collateral and area is Damage_Reciever:
		already_hit_collateral.append(area)
		apply_damage_emitted(area,Damage_Reciever.Hit_type.KNOCKDOWN)
		
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
	else:
		return is_on_floor() and state!=Estado.HURT and state!=Estado.DEATH and state!=Estado.ATTACK and state!=Estado.PREPATTACK

func handle_prep_attack()->void:
	if state==Estado.PREPATTACK and (Time.get_ticks_msec()-time_since_prep_hit>duration_prep_hit):
		state=Estado.ATTACK
		time_since_last_hit=Time.get_ticks_msec()
		damage_applied=false
		sfx_attack.play()
		
func on_frame_changed() -> void:
	if state == Estado.ATTACK and animated_sprite.frame == 0:
		damage_applied = false


func play_walk_sfx()->void:
	if not sfx_walk.playing:
		sfx_walk.play()

func stop_walk_sfx()->void:
	if sfx_walk.playing:
		sfx_walk.stop()
