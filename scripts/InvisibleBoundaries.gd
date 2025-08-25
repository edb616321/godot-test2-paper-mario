extends Node3D

# Invisible boundary walls to prevent falling off the map
# Automatically creates walls around the ground area

func _ready():
    print("Setting up invisible boundary walls")
    
    # Get the ground size from parent scene
    var ground_size = Vector3(30, 10, 30)  # Match the ground mesh size
    
    # Create invisible walls on all four sides
    _create_wall("North", Vector3(0, 5, -ground_size.z/2), Vector3(ground_size.x, ground_size.y, 0.5))
    _create_wall("South", Vector3(0, 5, ground_size.z/2), Vector3(ground_size.x, ground_size.y, 0.5))
    _create_wall("East", Vector3(ground_size.x/2, 5, 0), Vector3(0.5, ground_size.y, ground_size.z))
    _create_wall("West", Vector3(-ground_size.x/2, 5, 0), Vector3(0.5, ground_size.y, ground_size.z))
    
    print("Boundary walls created - player cannot fall off map")

func _create_wall(wall_name: String, wall_position: Vector3, size: Vector3):
    # Create a static body for the wall
    var wall = StaticBody3D.new()
    wall.name = "BoundaryWall_" + wall_name
    wall.position = wall_position
    
    # Add collision shape
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    wall.add_child(collision)
    
    # Add to scene
    add_child(wall)
    
    # Make walls invisible (no mesh needed)