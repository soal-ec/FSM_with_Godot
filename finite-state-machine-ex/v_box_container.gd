extends VBoxContainer
@onready var normal: Button = $Normal
@onready var smg: Button = $SMG
@onready var flamethrower: Button = $Flamethrower
@onready var beam: Button = $Beam

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_normal_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")

func _on_rapid_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene_rapid.tscn")

func _on_beam_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene.tscn")

func _on_smg_pressed() -> void:
	get_tree().change_scene_to_file("res://map/map_scene_smg.tscn")
