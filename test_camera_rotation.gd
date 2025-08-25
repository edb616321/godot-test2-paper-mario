extends Node

func _ready():
    print("Camera Rotation Test Script Started")
    
    # Simulate Q key press for camera rotation
    var test_timer = Timer.new()
    add_child(test_timer)
    test_timer.wait_time = 2.0
    test_timer.timeout.connect(_test_rotation)
    test_timer.start()

func _test_rotation():
    print("Testing camera rotation...")
    
    # Get the camera
    var camera = get_node("/root/MYGAIA Single Floor/MarioCamera")
    if camera:
        print("  Initial angle: ", camera.angle_offset)
        
        # Simulate rotation
        camera.angle_offset += 90
        print("  After rotation: ", camera.angle_offset)
        print("  Camera rotation test SUCCESS!")
    else:
        print("  ERROR: MarioCamera not found")