extends "res://scripts/NPCMovement.gd"

func _ready():
    npc_name = "Hickory"
    patrol_speed = 0.6  # Casual walking pace
    patrol_radius = 3.0
    wait_time = 4.0
    animation_speed = 1.2  # Relaxed walking animation
    super._ready()
    print("Hickory patrol system activated")
