extends baseCharacter
class_name Enemy

@export var player:Player

enum Estado{IDLE,WALK,DEATH,HURT,ATTACK,ATTACK2}

var player_slot:EnemySlot=null
var state=Estado.IDLE
var altura:=0.0
var altura_velocidad:=0.0
var knocked_down:bool=false
var stun_timer:=0.0

var animacion_map:Dictionary={
	Estado.IDLE: "idle",
	Estado.WALK: "walk",
	Estado.DEATH: "death",
	Estado.HURT: "hurt",
	Estado.ATTACK: "attack",
	Estado.ATTACK2: "attack2",
}

func _ready() -> void:
	super()
	damage_reciever.damage_recieved.connect(on_recieve_damage.bind())


func _process(delta: float) -> void:
	super(delta)


func handle_input(_delta: float) -> void:
	if not is_on_floor():
		velocity+=get_gravity()*_delta
	if state==Estado.HURT:
		if stun_timer>0:
			stun_timer-=_delta
		if is_on_floor():
			velocity.x=move_toward(velocity.x, 0, 300*_delta)
		return
	if knocked_down:
		if is_on_floor():
			knocked_down=false
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
			if abs(player_slot.global_position.x-position.x)<1:
				velocity=Vector2.ZERO
			else:
				velocity.x=direccion*velocidad
				

func handle_animations() -> void:
	if animacion_map.has(state):
		animated_sprite.play(animacion_map[state])


func handle_movement() -> void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.HURT or state==Estado.DEATH or knocked_down:
		return
	if velocity.length()!=0 and is_on_floor():
		state=Estado.WALK
	else:
		state=Estado.IDLE

func on_recieve_damage(damage:int, direccion:Vector2, hit_type:Damage_Reciever.Hit_type)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	if current_hp<=0:
		state=Estado.DEATH
		player.free_slot(self)
		handle_fall(direccion)
	else:
		match hit_type:
			Damage_Reciever.Hit_type.KNOCKDOWN:
				state=Estado.HURT
				knocked_down=true
				stun_timer=0.5
				velocity.x=direccion.x*knockback
				velocity.y=-knockback
			Damage_Reciever.Hit_type.POWER:
				state=Estado.HURT
				queue_free()
			_:
				state=Estado.HURT
				velocity=Vector2.ZERO

func on_animation_finished()->void:
	if state==Estado.HURT:
		if stun_timer<=0:
			state=Estado.IDLE
	elif state==Estado.DEATH:
		queue_free()

func handle_fall(direccion:Vector2)->void:
	velocity.x=randf_range(100,200)*direccion.x
	velocity.y=randf_range(-200,-100)
	animated_sprite.flip_h=direccion.x>0
	animated_sprite.rotation=randf_range(-0.5,0.5)


func handle_damage()-> void:
	if damage_applied:
		return
	if (animated_sprite.frame==2 or animated_sprite.frame==3) and (state==Estado.ATTACK):
		for area in damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area, Damage_Reciever.Hit_type.NORMAL)
		damage_applied=true
