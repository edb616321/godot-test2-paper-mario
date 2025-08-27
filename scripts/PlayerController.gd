extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const INTERACT_DISTANCE = 3.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var sprite: Node3D  # Can be Sprite3D or AnimatedSprite3D
var chat_ui: Control = null
var nearby_npc: CharacterBody3D = null
var is_chatting: bool = false

func _ready():
    add_to_group("player")
    
    # Get the sprite child (either Sprite3D or AnimatedSprite3D)
    sprite = get_node_or_null("Sprite3D")
    if not sprite:
        sprite = get_node_or_null("AnimatedSprite3D")
    
    if sprite:
        # Only set animation properties if it's an AnimatedSprite3D
        if sprite is AnimatedSprite3D:
            sprite.animation = "walk"
            sprite.frame = 0  # Start with Idle1/Walk1 frame
            sprite.stop()  # Start in idle state
            sprite.flip_h = false  # Face forward/camera
        print("Player sprite found: ", sprite.get_class())
    else:
        push_error("Player: No Sprite3D or AnimatedSprite3D found!")
    
    # Load and instance the chat UI (deferred to avoid setup conflicts)
    call_deferred("_setup_chat_ui")
    
    print("Player controller ready with sprite and chat system - starting in idle state")

func _physics_process(delta):
    # Don't move if chatting
    if is_chatting:
        velocity = Vector3.ZERO
        move_and_slide()
        return
    
    # Check for nearby NPCs
    _check_for_npcs()
    
    # Add gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Handle jump
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY
    
    # Handle interaction with E key
    if Input.is_action_just_pressed("interact") and nearby_npc:
        _start_chat_with_npc(nearby_npc)
        return
    
    # Get input direction - SIMPLE, no camera relative
    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
    
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
        
        # Animate walking (player now has 2 frames: Walk1 and Idle1)
        if sprite:
            sprite.play()  # Play the walking animation
            # Flip sprite based on horizontal movement direction (REVERSED)
            if abs(direction.x) > 0.1:  # Only flip if there's significant horizontal movement
                sprite.flip_h = direction.x > 0  # Flip when moving RIGHT (positive X)
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)
        
        # Stop animation when not moving - show idle state
        if sprite:
            sprite.stop()
            sprite.frame = 0  # Show Idle1/Walk1 frame when idle
    
    move_and_slide()

func _check_for_npcs():
    """Check for nearby NPCs the player can interact with"""
    nearby_npc = null
    var npcs = get_tree().get_nodes_in_group("npcs")
    
    for npc in npcs:
        if npc is CharacterBody3D:
            var distance = global_position.distance_to(npc.global_position)
            if distance < INTERACT_DISTANCE:
                nearby_npc = npc
                break

func _start_chat_with_npc(npc: CharacterBody3D):
    """Start chat with an NPC - NPC IS the LLM"""
    if not chat_ui:
        return
    
    is_chatting = true
    
    # Get NPC name and sprite
    var npc_name = "NPC"
    if npc.has_method("get_npc_name"):
        npc_name = npc.get_npc_name()
    elif npc.name:
        npc_name = str(npc.name)
    
    # Get NPC sprite texture if available
    var npc_texture = null
    var npc_sprite = npc.get_node_or_null("Sprite3D")
    if not npc_sprite:
        npc_sprite = npc.get_node_or_null("AnimatedSprite3D")
    
    if npc_sprite:
        if npc_sprite is Sprite3D and npc_sprite.texture:
            npc_texture = npc_sprite.texture
        elif npc_sprite is AnimatedSprite3D and npc_sprite.sprite_frames:
            var frames = npc_sprite.sprite_frames.get_frame_texture("walk", 0)
            if frames:
                npc_texture = frames
    
    # Open chat UI
    chat_ui.open_chat(npc_name, npc_texture)

func _on_chat_closed():
    """Called when chat UI is closed"""
    is_chatting = false

func _setup_chat_ui():
    """Setup chat UI after scene is ready"""
    var chat_scene = load("res://scenes/ChatUI.tscn")
    if chat_scene:
        chat_ui = chat_scene.instantiate()
        get_tree().root.add_child(chat_ui)
        chat_ui.chat_closed.connect(_on_chat_closed)
        print("Chat UI loaded successfully")