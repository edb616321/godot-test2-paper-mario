extends CharacterBody3D

# Player controller for park level with proper sprite system

signal player_moved
signal player_jumped
signal player_interacted

# Movement settings
const SPEED = 8.0
const WATER_SPEED = 3.5
const JUMP_VELOCITY = 8.0
const WATER_JUMP_MULTIPLIER = 0.6
const GRAVITY = -15.0

# Sprite references
@onready var sprite = $Sprite3D if has_node("Sprite3D") else null
@onready var shadow = $Shadow if has_node("Shadow") else null

# State tracking
var is_in_water = false
var facing_direction = Vector3.FORWARD
var is_moving = false
var current_frame = 0
var animation_timer = 0.0

# Sprite textures
var idle_texture: Texture2D
var walk_texture_1: Texture2D
var walk_texture_2: Texture2D

func _ready():
	print("Player Park Controller initialized")
	
	# Load player sprites
	idle_texture = load("res://sprites/MYGAIA_Sprite_Base_Idle1.png")
	walk_texture_1 = load("res://sprites/MYGAIA_Sprite_Base_Walk1.png")
	walk_texture_2 = load("res://sprites/MYGAIA_Sprite_Base_Walk1.png")  # Can alternate if we have more frames
	
	# Setup sprite if it doesn't exist
	if not sprite:
		_setup_sprite()
	
	# Setup shadow
	if not shadow:
		_setup_shadow()
	
	# Set initial sprite
	if sprite and idle_texture:
		sprite.texture = idle_texture

func _setup_sprite():
	"""Create sprite3D for player"""
	sprite = Sprite3D.new()
	sprite.name = "Sprite3D"
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.001  # Standard pixel size for MYGAIA sprites
	
	# Auto-alignment formula: sprite_offset_y = (sprite_height * pixel_size) / 2.0
	# For 800-pixel tall sprites: (800 * 0.001) / 2.0 = 0.4
	sprite.position.y = 0.4  # Properly aligned to ground
	
	if idle_texture:
		sprite.texture = idle_texture
	
	add_child(sprite)

func _setup_shadow():
	"""Create shadow under player"""
	shadow = MeshInstance3D.new()
	shadow.name = "Shadow"
	
	var shadow_mesh = QuadMesh.new()
	shadow_mesh.size = Vector2(0.8, 0.8)  # Smaller shadow for sprite
	shadow.mesh = shadow_mesh
	
	var shadow_material = StandardMaterial3D.new()
	shadow_material.albedo_color = Color(0, 0, 0, 0.3)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow.material_override = shadow_material
	
	shadow.position.y = 0.01  # Just above ground level
	shadow.rotation.x = -PI/2  # Flat on ground
	
	add_child(shadow)

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		var jump_force = JUMP_VELOCITY
		if is_in_water:
			jump_force *= WATER_JUMP_MULTIPLIER
		velocity.y = jump_force
		emit_signal("player_jumped")
	
	# Get input direction
	var input_dir = Vector2()
	if Input.is_action_pressed("ui_left"):
		input_dir.x -= 1
		facing_direction = Vector3.LEFT
	if Input.is_action_pressed("ui_right"):
		input_dir.x += 1
		facing_direction = Vector3.RIGHT
	if Input.is_action_pressed("ui_up"):
		input_dir.y -= 1
		facing_direction = Vector3.FORWARD
	if Input.is_action_pressed("ui_down"):
		input_dir.y += 1
		facing_direction = Vector3.BACK
	
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	# Apply movement with water speed modifier
	var current_speed = WATER_SPEED if is_in_water else SPEED
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		is_moving = true
		emit_signal("player_moved")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * delta)
		velocity.z = move_toward(velocity.z, 0, current_speed * delta)
		is_moving = false
	
	# Move and slide
	move_and_slide()
	
	# Update animation
	_update_animation(delta)
	
	# Check for interactions
	if Input.is_action_just_pressed("interact"):
		_check_interactions()

func _update_animation(delta):
	"""Update sprite animation based on movement"""
	if not sprite:
		return
	
	if is_moving:
		# Walking animation
		animation_timer += delta * 8.0  # Animation speed
		if animation_timer > 1.0:
			animation_timer = 0.0
			current_frame = 1 - current_frame  # Toggle between 0 and 1
			
			if current_frame == 0:
				sprite.texture = walk_texture_1
			else:
				sprite.texture = walk_texture_2 if walk_texture_2 else walk_texture_1
	else:
		# Idle
		sprite.texture = idle_texture
		current_frame = 0
		animation_timer = 0.0
	
	# Flip sprite based on direction
	if sprite:
		if facing_direction.x < 0:
			sprite.flip_h = true
		elif facing_direction.x > 0:
			sprite.flip_h = false

func _check_interactions():
	"""Check for nearby interactable objects"""
	# Emit signal for the park controller to handle
	emit_signal("player_interacted")
	
	# The park_level_controller will handle finding nearby NPCs and starting conversations

func set_water_state(in_water: bool):
	"""Update water state"""
	is_in_water = in_water
	
	# Add visual effect for being in water
	if sprite:
		if in_water:
			sprite.modulate = Color(0.7, 0.8, 1.0, 1.0)  # Slight blue tint
		else:
			sprite.modulate = Color.WHITE

func teleport_to(new_position: Vector3):
	"""Teleport player to a new position"""
	global_position = new_position
	velocity = Vector3.ZERO