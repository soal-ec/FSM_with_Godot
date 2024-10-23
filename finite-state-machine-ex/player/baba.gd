extends Area2D

@onready var forward_ray: RayCast2D = $forward_ray
@onready var sprite_2d: Sprite2D = $Sprite2D

var tile_size = 64
var inputs = {
	"ui_right": Vector2.RIGHT,
	"ui_left": Vector2.LEFT,
	"ui_up": Vector2.UP,
	"ui_down": Vector2.DOWN,
}
var animation_speed = 6
var moving = false
var dead = false

var spr_idle = load("res://player/baba_idle.png")
var spr_move = load("res://player/baba_move.png")
var spr_dead = load("res://player/baba_dead.png")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2
	add_to_group("player")

func _process(delta: float) -> void:
	#if has_overlapping_bodies():
		#print("BABA: BODY FOUND")
		#print(get_overlapping_bodies())
		#for body in get_overlapping_bodies():
			#coll_action(body)
	if dead:
		return
	if has_overlapping_areas():
		for body in get_overlapping_areas():
			coll_action(body)

func _unhandled_input(event):
	if moving or dead:
		return
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			move(dir)
		if event.is_action_pressed("ui_end"):
			dead = true
			sprite_2d.texture = spr_dead
			remove_from_group("player")

func move(dir):
	forward_ray.target_position = inputs[dir] * tile_size
	forward_ray.force_raycast_update()
	if !forward_ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "position",
			position + inputs[dir] *    tile_size, 1.0/animation_speed).set_trans(Tween.TRANS_SINE)
		moving = true
		sprite_2d.texture = spr_move
		await tween.finished
		moving = false
		if (!dead):
			sprite_2d.texture = spr_idle


func coll_action(body):
	#print("PLAYER COLLISION")
	if body.is_in_group("projectile"):
		dead = true
		sprite_2d.texture = spr_dead
		remove_from_group("player")
