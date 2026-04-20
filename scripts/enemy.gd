extends baseCharacter
class_name Enemy

@export var player:Player

enum Estado{IDLE,WALK,DEATH,HURT,ATTACK,ATTACK2}

var state=Estado.IDLE
var altura:=0.0
var altura_velocidad:=0.0

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
	$damage_reciever.damage_recieved.connect(on_recieve_damage.bind())


func _process(delta: float) -> void:
	super(delta)


func handle_input(_delta: float) -> void:
	if not is_on_floor():
		velocity+=get_gravity()*_delta
	if state==Estado.HURT:
		return
	if state==Estado.DEATH:
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, 300 * _delta)
		return
	if player!=null:
		var direccion=sign(player.position.x-position.x)
		velocity.x=direccion*velocidad

func handle_animations() -> void:
	if animacion_map.has(state):
		$AnimatedSprite2D.play(animacion_map[state])


func handle_movement() -> void:
	if state==Estado.ATTACK or state==Estado.ATTACK2 or state==Estado.HURT or state==Estado.DEATH:
		return
	if velocity.length()!=0 and is_on_floor():
		state=Estado.WALK
	else:
		state=Estado.IDLE

func on_recieve_damage(damage:int, direccion:Vector2)->void:
	current_hp=clamp(current_hp-damage,0,max_hp)
	velocity.x=direccion.x*knockback
	velocity.y=-knockback
	if current_hp<=0:
		state=Estado.DEATH
		handle_fall(direccion)
	else:
		state=Estado.HURT

func on_animation_finished()->void:
	if state==Estado.HURT:
		state=Estado.IDLE
	elif state==Estado.DEATH:
		queue_free()

func handle_fall(direccion:Vector2)->void:
	velocity.x=randf_range(100,200)*direccion.x
	velocity.y=randf_range(-200,-100)
	$AnimatedSprite2D.flip_h=direccion.x>0
	$AnimatedSprite2D.rotation=randf_range(-0.5,0.5)


func handle_damage()-> void:
	if damage_applied:
		return
	if ($AnimatedSprite2D.frame==2 or $AnimatedSprite2D.frame==3) and (state==Estado.ATTACK):
		for area in $damage_emitter.get_overlapping_areas():
			apply_damage_emitted(area)
		damage_applied=true
