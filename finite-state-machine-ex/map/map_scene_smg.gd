extends Node2D

@onready var red_mage = $RedMage

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	red_mage.set_values("smg")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
