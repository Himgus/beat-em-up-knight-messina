extends baseCharacter

class_name Archer

@export var player:Player
@export var shot_interval:float=2.0
@export var arrow:PackedScene
@export var duration_prep_shot:int
@export var archer_slot:ArcherSlot

@onready var collateral_damage_emitter:=$collateral_damage_emitter

var knocked_down:bool=false
var stun_timer:float=0.0
var wall_launched:bool=false
var wall_bounce_done:bool=false
var pre_wall_velocity_x:float=0.0
var already_hit_collateral:Array=[]
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
	collateral_damage_emitter.area_entered.connect(on_collateral_area_entered)
	shoot_timer=shot_interval

func _process(delta:float)->void:
	super(delta)
	handle_prep_attack()

func handle_input(delta) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if state == Estado.HURT:
		if stun_timer > 0:
			stun_timer -= delta
			damage_reciever.monitorable = false
		if wall_launched and not wall_bounce_done:
			if not is_on_wall():
				pre_wall_velocity_x = velocity.x
			else:
				var collision = get_last_slide_collision()
				if collision and not collision.get_collider() is Archer:
					velocity.x = -pre_wall_velocity_x * 0.6
					velocity.y = -knockback * 0.3
					wall_bounce_done = true
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 300 * delta)
			if wall_launched and wall_bounce_done:
				velocity.x = 0
				wall_launched = false
				wall_bounce_done = false
				already_hit_collateral.clear()
				collateral_damage_emitter.monitoring = false
			elif knocked_down and wall_bounce_done:
				knocked_down = false
				damage_reciever.monitorable = true
		return
	if knocked_down:
		if is_on_floor():
			knocked_down = false
			damage_reciever.monitorable = true
		return
	if state == Estado.DEATH:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 300 * delta)
		return
	if player == null:
		return
	if archer_slot == null:
		archer_slot = player.reserve_archer_slot(self)
	if archer_slot != null:
		var dist_to_slot = abs(global_position.x - archer_slot.global_position.x)
		if dist_to_slot > 20.0:
			velocity.x = sign(archer_slot.global_position.x - global_position.x) * velocidad
		else:
			velocity.x = 0
			shoot_timer += delta
			if shoot_timer >= shot_interval:
				shoot_timer = 0.0
				state = Estado.PREPATTACK
				time_since_prep_shot = Time.get_ticks_msec()
				damage_applied = false


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
		state=Estado.ATTACK

func on_recieve_damage(damage: int, direccion: Vector2, hit_type: Damage_Reciever.Hit_type) -> void:
	current_hp = clamp(current_hp - damage, 0, max_hp)
	if current_hp <= 0:
		state = Estado.DEATH
		player.free_archer_slot(self)
		handle_fall(direccion)
	else:
		match hit_type:
			Damage_Reciever.Hit_type.KNOCKDOWN:
				state = Estado.HURT
				knocked_down = true
				stun_timer = 0.5
				velocity.x = direccion.x * knockback
				velocity.y = -knockback
				damage_reciever.monitorable = false
				shoot_timer = 0.0
			Damage_Reciever.Hit_type.POWER:
				state = Estado.HURT
				knocked_down = true
				stun_timer = 1.0
				damage_reciever.monitorable = false
				wall_launched = true
				wall_bounce_done = false
				collateral_damage_emitter.monitoring = true
				velocity.x = direccion.x * knockback * 3
				velocity.y = -knockback
				shoot_timer = 0.0
			_:
				state = Estado.HURT
				velocity.x = 0
				shoot_timer = 0.0
	print(current_hp)

func handle_fall(direccion: Vector2) -> void:
	velocity.x = randf_range(100, 200) * direccion.x
	velocity.y = randf_range(-200, -100)
	animated_sprite.flip_h = direccion.x > 0
	animated_sprite.rotation = randf_range(-0.5, 0.5)

func on_collateral_area_entered(area: Area2D) -> void:
	if not wall_launched or wall_bounce_done:
		return
	if not area is Damage_Reciever:
		return
	if area == damage_reciever:
		return
	if area not in already_hit_collateral:
		already_hit_collateral.append(area)
		apply_damage_emitted(area, Damage_Reciever.Hit_type.KNOCKDOWN)

func on_animation_finished()->void:
	if state == Estado.HURT:
		if stun_timer <= 0:
			state = Estado.IDLE
		return
	if state==Estado.ATTACK:
		shoot_arrow()
		state=Estado.IDLE
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
