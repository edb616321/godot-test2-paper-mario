extends "res://scripts/NPCMovement.gd"

func _ready():
	npc_name = "Captain"
	patrol_speed = 0.8  # Nice walking pace
	patrol_radius = 8.0  # Larger patrol area
	wait_time = 3.0
	animation_speed = 1.5  # Slower animation for walking
	super._ready()
	print("Captain patrol system activated")
