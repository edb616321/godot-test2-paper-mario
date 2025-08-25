extends Node3D

# World boundary settings
var boundary_size = 50.0
var boundary_height = 20.0

func _ready():
    create_boundaries()
    print("World boundaries created")

func create_boundaries():
    # Create invisible walls around the play area
    var boundaries = [
        {"pos": Vector3(boundary_size, 0, 0), "rot": Vector3(0, 0, PI/2)},  # Right
        {"pos": Vector3(-boundary_size, 0, 0), "rot": Vector3(0, 0, PI/2)}, # Left
        {"pos": Vector3(0, 0, boundary_size), "rot": Vector3(PI/2, 0, 0)}, # Back
        {"pos": Vector3(0, 0, -boundary_size), "rot": Vector3(PI/2, 0, 0)}  # Front
    ]
    
    for boundary in boundaries:
        var wall = StaticBody3D.new()
        wall.position = boundary.pos
        wall.rotation = boundary.rot
        
        var collision = CollisionShape3D.new()
        var shape = BoxShape3D.new()
        shape.size = Vector3(boundary_height * 2, 0.1, boundary_size * 2)
        collision.shape = shape
        
        wall.add_child(collision)
        wall.collision_layer = 1  # World layer
        add_child(wall)
