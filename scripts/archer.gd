extends baseCharacter

class_name Archer

@export var player:Player
@export var shot_interval:float=2.0
@export var arrow:PackedScene
@export var duration_prep_shot:int
@export var archer_slot:ArcherSlot

var state=Estado.IDLE
var shoot_timer:float=0.0
var time_since_prep_shot:int=0

enum Estado{IDLE,WALK,HURT,DEATH,ATTACK,PREPATTACK}

var animacion_map:Dictionary={
	Estado.IDLE:"idle",
	Estado.WALK:"walk",
	Estado.HURT:"hurt",
	Estado.DEATH:"death",
	Estado.ATTACK:"attack",
	Estado.PREPATTACK:"idle"
}

func _ready()->void:
	super()
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())
	shoot_timer=shot_interval

func _process(delta:float)->void:
	super(delta)
	handle_prep_attack()

func handle_input(delta)->void:
	if not is_on_floor():
		velocity+=get_gravity()*delta
	if state==Estado.HURT or state==Estado.DEATH or state==Estado.ATTACK or state==Estado.PREPATTACK:
		return
	if player==null:
		return
	if archer_slot==null:
		archer_slot=player.reserve_archer_slot(self)
	if archer_slot!=null:
		var dist_to_slot=abs(global_position.x-archer_slot.global_position.x)
		if dist_to_slot>20.0:
			velocity.x=sign(archer_slot.global_position.x-global_position.x)*velocidad
		else:
			velocity.x=0
			shoot_timer+=delta
			if shoot_timer>=shot_interval:
				shoot_timer=0.0
				state=Estado.PREPATTACK
				time_since_prep_shot=Time.get_ticks_msec()
				damage_applied=false


func handle_movement()->void:
	if state==Estado.ATTACK or state==Estado.HURT or state==Estado.DEATH or state==Estado.PREPATTACK:
		return
	if velocity.length()!=0 and is_on_floor():
		state=Estado.WALK
	else:
		state=Estado.IDLE

func handle_animations()->void:
	if animacion_map.has(state):
		animated_sprite.play(animacion_map[state])

func handle_damage() -> void:
	pass

func handle_prep_attack()->void:
	if state==Estado.PREPATTACK and (Time.get_ticks_msec()-time_since_prep_shot>duration_prep_shot):
		print("entering ATTACK state")
		state=Estado.ATTACK

func on_recieve_damage(damage:int,_direccion:Vector2,hit_type:Damage_Reciever.Hit_type)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		state=Estado.DEATH
		player.free_archer_slot(self)
	else:
		state=Estado.HURT
		velocity.x=0
		shoot_timer=0.0

func on_animation_finished()->void:
	print("animation finished, state: ", state)
	if state==Estado.ATTACK:
		shoot_arrow()
		state=Estado.IDLE
		return
	if state==Estado.HURT:
		state=Estado.IDLE
		damage_reciever.monitoring=true
		return
	if state==Estado.DEATH:
		queue_free()

func shoot_arrow()->void:
	if arrow==null or player==null:
		return
	var flecha=arrow.instantiate()
	get_parent().add_child(flecha)
	flecha.global_position=global_position+Vector2(-30,-30)
	flecha.launch(sign(player.global_position.x-global_position.x),self)

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
