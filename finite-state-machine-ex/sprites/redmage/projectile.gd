extends Area2D

@onready var fireball_sp: Sprite2D = $fireball_sp
@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var dir = {
	"right": Vector2.RIGHT,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"down": Vector2.DOWN
}
var curr_dir = dir["right"]
var tile_size = 64
var animation_speed = 12
var moving = false
var opacity = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# snap to grid
	position = position.snapped(Vector2.ONE * tile_size)
	position += Vector2.ONE * tile_size/2
	# set sprite to match dir value
	orient()
	fireball_sp.modulate.a = 0
	add_to_group("projectile")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !moving:
		move()
	if opacity < 1:
		opacity += .005
		fireball_sp.modulate.a = opacity
		
	#if has_overlapping_bodies():
		#print("PROJ: BODY FOUND")
		#print(get_overlapping_bodies())
		#for body in get_overlapping_bodies():
			#coll_action(body)
	if has_overlapping_areas():
		#print("PROJ: AREA FOUND")
		#print(get_overlapping_areas())
		for body in get_overlapping_areas():
			coll_action(body)

func move():
	# copied move from redmage
	var tween = create_tween()
	tween.tween_property(self, "position",
		position + curr_dir * tile_size,
		1.0/animation_speed).set_trans(Tween.TRANS_SINE)
	moving = true
	await tween.finished
	moving = false

func set_dir(todir: Vector2):
	#print(todir)
	# init
	match todir:
		Vector2(0, -1):
			curr_dir = dir['up']
		Vector2(0, 1):
			curr_dir = dir['down']
		Vector2(-1, 0):
			curr_dir = dir['left']
		Vector2(1, 0):
			curr_dir = dir['right']

func orient():
	if (curr_dir == dir['up']):
		fireball_sp.rotation_degrees = -90
	elif (curr_dir == dir['down']):
		fireball_sp.rotation_degrees = 90 
	elif (curr_dir == dir['left']):
		fireball_sp.flip_h = true
	elif (curr_dir == dir['right']):
		pass

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func coll_action(body):
	if body.is_in_group("player"):
		queue_free()
	elif body.is_in_group("wall"):
		queue_free()
