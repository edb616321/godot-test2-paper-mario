extends "res://scripts/NPCMovement.gd"

func _ready():
	npc_name = "Hickory"
	patrol_speed = 0.6  # Slower, methodical pace for blacksmith
	patrol_radius = 6.0  # Medium patrol area
	wait_time = 4.0  # Longer waits between movements
	animation_speed = 1.2  # Slower animation
	super._ready()
	print("Hickory patrol system activated")
