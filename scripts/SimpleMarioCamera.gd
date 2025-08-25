extends Node3D

# Simple Mario-style camera - just maintains fixed offset from player

func _ready():
    print("Paper Mario Camera initialized - elevated view")
    
    # Position camera child at fixed offset - elevated to see more above
    var camera = $Camera3D
    if camera:
        # Higher camera position to see more above the player
        # Player will appear lower in the frame
        camera.position = Vector3(0, 18, 18)  # Same height, moved further back
        camera.rotation.x = deg_to_rad(-50)  # Steeper angle to see more of the world above