extends Area2D
class_name Flecha

@export var velocidad:float=200.0
@export var arch_height:float=25
@export var gravity_strength:float=300.0

@onready var sprite:Sprite2D=$Sprite2D
@onready var sfx_do_damage:AudioStreamPlayer2D=$SFXDoDamage

var direction:float=1.0
var shooter:Node=null
var velocity:Vector2=Vector2.ZERO
var already_hit:Array=[]

func launch(dir:float,archer:Archer)->void:
	direction=dir
	shooter=archer
	var initial_vy=-sqrt(2.0*gravity_strength*arch_height)
	velocity=Vector2(velocidad*direction,initial_vy)
	sprite.flip_h=direction<0


func _process(delta:float)->void:
	velocity.y+=gravity_strength*delta
	global_position+=velocity*delta
	if global_position.y>1000:
		queue_free()

func _on_area_entered(area:Area2D)->void:
	if area==shooter.damage_reciever:
		return
	if area not in already_hit:
		sfx_do_damage.play()
		already_hit.append(area)
		shooter.apply_damage_emitted(area,Damage_Reciever.Hit_type.NORMAL)
		queue_free()
