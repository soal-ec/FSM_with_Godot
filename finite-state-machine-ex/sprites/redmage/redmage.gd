extends Node2D

@onready var area_box: Area2D = $Body
@onready var hearing_scan_coll: CollisionShape2D = $Body/scanners/hearing_scan/CollisionShape2D
@onready var main_body_sprite: Sprite2D = $Body/main_body_sprite
@onready var stored_fire: Sprite2D = $Body/stored_fire
@onready var thoughts: Sprite2D = $Body/thoughts

#@onready var last_seen: Sprite2D = $last_seen
#@onready var last_seen: RemoteTransform2D = $Body/RemoteTransform2D
@onready var last_seen: Sprite2D = $Node2D/last_seen

@onready var ammo_count: Label = $Body/ammo_count
@onready var hearing_scan: Area2D = $Body/scanners/hearing_scan
@onready var north_scan: RayCast2D = $Body/scanners/north_scan
@onready var south_scan: RayCast2D = $Body/scanners/south_scan
@onready var east_scan: RayCast2D = $Body/scanners/east_scan
@onready var west_scan: RayCast2D = $Body/scanners/west_scan

const FIREBALL = preload("res://sprites/redmage/projectile.tscn")
const FIRESTORE_1 = preload("res://sprites/redmage/firestore_1.png")
const FIRESTORE_2 = preload("res://sprites/redmage/firestore_2.png")

var inputs = {
	"ui_right": Vector2.RIGHT,
	"ui_left": Vector2.LEFT,
	"ui_up": Vector2.UP,
	"ui_down": Vector2.DOWN,
}

var tile_size = 64
var animation_speed = 2
var moving = false

var max_stored_chages = 2
var stored_charges = 0
var max_cast_delay = 0.2
var cast_delay = 0.0
var max_charge_timer = 2
var charge_timer = max_charge_timer

var max_scan_timer = .5
var scan_timer = 0.0
var idle_timer = 0

var hearing_shape : CircleShape2D

var mana = 4

var state = "sleep"
const FSM = {
	"sleep":{"detect":"idle", "decay":"sleep", "outrange":"sleep", "sight":"sleep", "sight_weak":"sleep", "die":"death"},
	"idle":{"detect":"investigate", "decay":"idle", "outrange":"idle", "sight":"attack", "sight_weak":"run", "die":"death"},
	"investigate":{"detect":"investigate", "decay":"idle", "outrange":"investigate", "sight":"attack", "sight_weak":"run", "die":"death"},
	"attack":{"detect":"investigate", "decay":"attack", "outrange":"investigate", "sight":"attack", "sight_weak":"run", "die":"death"},
	"run": {"detect":"run", "decay":"run", "outrange":"idle", "sight":"attack", "sight_weak":"run", "die":"death"},
	"death": {"detect":"death", "decay":"death", "outrange":"death", "sight":"death", "sight_weak":"death", "die":"death"}
}
var ray_was_colliding = false
var hide_lines = false

@onready var solids: TileMapLayer = $"../layer_holder/solids"
# removd type definition to allow func calls
@onready var layer_holder = $"../layer_holder"

var current_path: Array[Vector2i]
# init
func _ready() -> void:
	position = snap_pos(position)
	scan_timer = max_scan_timer
	if hearing_scan_coll.shape is CircleShape2D:
		hearing_shape = hearing_scan_coll.shape as CircleShape2D
	ammo_count.visible = false
	update_label()
	update_stored_charges()
	update_behaviour("outrange")

func _draw() -> void:
	if !hide_lines:
		draw_arc(Vector2.ZERO, hearing_shape.radius, 0, 2*PI, 64, Color.SEA_GREEN) 
		if state != "sleep":
			draw_line(Vector2.ZERO, north_scan.target_position, Color.GOLDENROD, 2)
			draw_line(Vector2.ZERO, south_scan.target_position, Color.GOLDENROD, 2)
			draw_line(Vector2.ZERO, east_scan.target_position, Color.GOLDENROD, 2)
			draw_line(Vector2.ZERO, west_scan.target_position, Color.GOLDENROD, 2)
			for vec in current_path:
				draw_rect(Rect2(vec, Vector2(64, 64)), Color.RED, false)

func _process(delta: float) -> void:
	if state == "death":
		return
	all_counters(delta)
	if scan_timer <= 0:
		all_scans()
	if current_path.is_empty():
		return
	if state != "run":
		move()


func update_behaviour(input: String):
	var thou_texture
	var sprite
	# FSM inputs: detect, decay, out_range, sight, sight_weak, die
	state = FSM[state][input]
	# change visuals
	match(state):
		"sleep":
			thou_texture = load("res://sprites/redmage/sleep_thought.png")
			sprite = load("res://sprites/redmage/redmage_sleep1.png")
		"idle":
			thou_texture = load("res://sprites/redmage/ellipses_thought.png")
			sprite = load("res://sprites/redmage/redmage_active.png")
		"investigate":
			thou_texture = load("res://sprites/redmage/patrol_thought.png")
			sprite = load("res://sprites/redmage/redmage_active.png")
		"attack":
			thou_texture = load("res://sprites/redmage/hunt_thought.png")
			sprite = load("res://sprites/redmage/redmage_cast1.png")
		"run":
			thou_texture = load("res://sprites/redmage/fear_thought.png")
			sprite = load("res://sprites/redmage/redmage_fear.png")
		"death":
			sprite = load("res://sprites/redmage/redmage_stagger.png")
			thou_texture = null
			ammo_count.visible = false
			hide_lines = true
	main_body_sprite.texture = sprite
	thoughts.texture = thou_texture


func all_scans():
	# detect line of sight
	if state == "sleep":
		if area_scan():
			queue_redraw()
			ammo_count.visible = true
			update_behaviour("detect")
	else:
		update_curr_path()
		if !ray_scan():
			# detect detection radius
			if area_scan():
				if mana == 0 and stored_charges == 0:
					update_behaviour("sight_weak")
				else:
					if state == "sleep":
						queue_redraw()
						ammo_count.visible = true
					update_behaviour("detect")
			elif ray_was_colliding and state != "sleep":
				update_behaviour("outrange")
				ray_was_colliding = false
				last_seen.visible = true
	
	# death
	if area_box.has_overlapping_areas():
		for body in area_box.get_overlapping_areas():
			if body.is_in_group("player"):
				update_behaviour("die")
				last_seen.visible = false

func update_curr_path():
	# if traversable, set current_path
	if layer_holder.is_point_traversable(last_seen.global_position):
		current_path = layer_holder.astar.get_id_path(
			solids.local_to_map(global_position),
			solids.local_to_map(last_seen.global_position)
		).slice(1)

func ray_scan() -> bool:
	var a_ray_has_coll = false
	# sight, sight_weak and run:outrange
	for scan in [north_scan, south_scan, east_scan, west_scan]:
		if scan.is_colliding():
			var collider = scan.get_collider()
			if collider.is_in_group("player"):
				last_seen.visible = false
				if !ray_was_colliding:
					if mana > 0 or stored_charges > 0:
						update_behaviour("sight")
					else:
						update_behaviour("sight_weak")
					last_seen.global_position = collider.global_position
					ray_was_colliding = true
				a_ray_has_coll = true
				fire_projectile(scan)
	return a_ray_has_coll

func area_scan() -> bool:
	var det: bool
	# detect, investigate:decay
	if hearing_scan.has_overlapping_areas():
		for area in hearing_scan.get_overlapping_areas():
			if area.is_in_group("player"):
				last_seen.global_position = area.global_position
				if !ray_was_colliding:
					if state == "run":
						update_behaviour("sight_weak")
					else:
						update_behaviour("detect")
					last_seen.visible = false
				det = true
	return det


func _on_hearing_scan_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		if !ray_scan():
			update_behaviour("outrange")
			last_seen.global_position = area.global_position
			last_seen.visible = true


func fire_projectile(ray: RayCast2D):
	if stored_charges > 0 && state != "run" && cast_delay <= 0:
		var projectile = FIREBALL.instantiate()
		projectile.global_position = global_position + Vector2(-12, -12)
		projectile.set_dir(ray.target_position.normalized())
		get_parent().add_child(projectile)
		
		cast_delay = max_cast_delay
		stored_charges -= 1
		update_label()
		update_stored_charges()

func update_label():
	ammo_count.text = "%d/%d" % [stored_charges, mana]
func update_stored_charges():
	if stored_charges >= 2:
		stored_fire.texture = FIRESTORE_2
	elif stored_charges == 1:
		stored_fire.texture = FIRESTORE_1
	elif stored_charges <= 0:
		stored_fire.texture = null
	update_label()
func all_counters(delta: float):
	if state != "sleep":
		if cast_delay > 0:
			cast_delay -= delta
		if charge_timer > 0 && stored_charges < max_stored_chages:
			charge_timer -= delta
		elif stored_charges < max_stored_chages && mana > 0:
			stored_charges += 1
			mana -= 1
			if stored_charges < 2:
				charge_timer = max_charge_timer
			update_stored_charges()
	scan_timer -= delta

func snap_pos(pos):
	pos = pos.snapped(Vector2.ONE * tile_size)
	pos += Vector2.ONE * tile_size/2
	return pos

func move():
	if state == "death":
		return
	if global_position.x < current_path.front().x:
		main_body_sprite.flip_h = false
		stored_fire.flip_h = false
	else:
		main_body_sprite.flip_h = true
		stored_fire.flip_h = true
	# move code
	var dist = 2
	if state == "idle":
		dist = 0
	if current_path.size() > dist and !moving:
		var target_position = solids.map_to_local(current_path.front())
		# move method 1 
		#global_position = global_position.move_toward(target_position, animation_speed/4)
		# move method 2
		var tween = create_tween()
		tween.tween_property(self, "position",
			target_position,
			1.0/animation_speed).set_trans(Tween.TRANS_SINE)
		moving = true
		await tween.finished
		moving = false
		if global_position == target_position:
			current_path.pop_front
	#elif state == "run":
		#var target_position = 
		#
		#var tween = create_tween()
		#tween.tween_property(self, "position",
			#target_position,
			#1.0/animation_speed).set_trans(Tween.TRANS_SINE)
		#moving = true
		#await tween.finished
		#moving = false
		#else:
			#global_position = global_position.move_toward(snap_pos(global_position), animation_speed/4)

func set_values(str: String):
	match str:
		"rapid":
			mana = 3000
			max_cast_delay = 0.001
			max_stored_chages = 1000
			max_charge_timer = 0.01
		"smg":
			north_scan.target_position /= 2
			south_scan.target_position /= 2
			east_scan.target_position /= 2
			west_scan.target_position /= 2
			mana = 60
			max_cast_delay = 0.02
			max_stored_chages = 30
			max_charge_timer = 0.3
