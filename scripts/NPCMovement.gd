extends CharacterBody3D

@export var npc_name: String = "NPC"
@export var patrol_speed: float = 2.0
@export var patrol_radius: float = 5.0
@export var wait_time: float = 2.0
@export var animation_speed: float = 5.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var start_position: Vector3
var patrol_points: Array = []
var current_patrol_index: int = 0
var wait_timer: float = 0.0
var is_waiting: bool = false
var sprite: Node3D  # Can be either Sprite3D or AnimatedSprite3D
var is_moving: bool = false
var last_direction: Vector3 = Vector3.FORWARD

func _ready():
	add_to_group("npcs")
	start_position = global_position
	
	# Debug NPC position
	print(npc_name, " initial position: ", global_position)
	
	# Find the sprite child (either Sprite3D or AnimatedSprite3D)
	sprite = get_node_or_null("Sprite3D")
	if not sprite:
		sprite = get_node_or_null("AnimatedSprite3D")
	
	if not sprite:
		push_error("NPC " + npc_name + ": No Sprite3D or AnimatedSprite3D found!")
		return
	
	# Ensure sprite has animations and start in idle state (only for AnimatedSprite3D)
	if sprite is AnimatedSprite3D and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("walk"):
			sprite.animation = "walk"
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.animation = "idle"
		sprite.frame = 0  # Start with Idle1/Walk1 frame
		sprite.stop()  # Start in idle state
		sprite.flip_h = false  # Always face forward/camera
	
	# Start in waiting/idle state (just like TEST2)
	is_waiting = true
	wait_timer = wait_time  # Use the full wait_time set by each NPC controller
	
	# Generate patrol points in a square pattern
	generate_patrol_points()
	
	print("NPC ", npc_name, " movement initialized with ", patrol_points.size(), " waypoints - starting in idle state")
	print("First patrol point: ", patrol_points[0] if patrol_points.size() > 0 else "NONE")

func generate_patrol_points():
	# Create 4 patrol points in a square around start position
	patrol_points.clear()
	patrol_points.append(start_position + Vector3(patrol_radius, 0, 0))
	patrol_points.append(start_position + Vector3(patrol_radius, 0, patrol_radius))
	patrol_points.append(start_position + Vector3(0, 0, patrol_radius))
	patrol_points.append(start_position + Vector3(-patrol_radius, 0, patrol_radius))
	patrol_points.append(start_position + Vector3(-patrol_radius, 0, 0))
	patrol_points.append(start_position + Vector3(-patrol_radius, 0, -patrol_radius))
	patrol_points.append(start_position + Vector3(0, 0, -patrol_radius))
	patrol_points.append(start_position + Vector3(patrol_radius, 0, -patrol_radius))

var debug_timer: float = 0.0
var first_frame: bool = true

func _physics_process(delta):
	# Debug output on first frame and every 5 seconds
	if first_frame:
		first_frame = false
		print(npc_name, " FIRST FRAME - waiting: ", is_waiting, ", position: ", global_position)
	
	debug_timer += delta
	if debug_timer > 2.0:  # Debug every 2 seconds instead of 5
		debug_timer = 0.0
		print(npc_name, " status - waiting: ", is_waiting, ", pos: ", global_position.x, ",", global_position.z, ", timer: ", wait_timer)
	
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle waiting between patrol points
	if is_waiting:
		wait_timer -= delta
		if wait_timer <= 0:
			is_waiting = false
			current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
			print(npc_name, " starting to move to waypoint ", current_patrol_index, " at ", patrol_points[current_patrol_index])
		
		# Show idle state while waiting (use frame 0 of walk animation as idle)
		if sprite:
			# Only call stop() if it's an AnimatedSprite3D
			if sprite is AnimatedSprite3D:
				sprite.stop()
				sprite.frame = 0  # Show Idle1/Walk1 frame
			# flip_h works on both Sprite3D and AnimatedSprite3D
			if sprite.has_method("set_flip_h"):
				sprite.flip_h = false  # Always face forward
		
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
	
	# Move to current patrol point
	if patrol_points.size() > 0:
		var target = patrol_points[current_patrol_index]
		var direction = (target - global_position).normalized()
		direction.y = 0  # Keep movement horizontal
		
		# Check if we reached the patrol point
		var distance = global_position.distance_to(target)
		if distance < 0.5:
			# Start waiting
			is_waiting = true
			wait_timer = wait_time
			is_moving = false
		else:
			# Move towards target
			velocity.x = direction.x * patrol_speed
			velocity.z = direction.z * patrol_speed
			is_moving = true
			last_direction = direction
			
			# Update sprite direction based on movement
			update_sprite_direction(direction)
			
			# Play walking animation (for Sprite3D, just keep the texture visible)
			if sprite is AnimatedSprite3D and sprite.sprite_frames:
				if sprite.sprite_frames.has_animation("walk"):
					sprite.animation = "walk"
					sprite.speed_scale = animation_speed
				sprite.play()
			# For regular Sprite3D, the texture is already set
	
	move_and_slide()

func update_sprite_direction(direction: Vector3):
	if not sprite:
		return
	
	# Flip sprite based on horizontal movement direction (REVERSED)
	if abs(direction.x) > 0.1:  # Only flip if there's significant horizontal movement
		sprite.flip_h = direction.x > 0  # Flip when moving RIGHT (positive X)
	
	# Keep sprite facing camera (billboard mode)
	# This is handled by the Sprite3D's billboard setting in the scene

func set_patrol_points(points: Array):
	"""Allow custom patrol points"""
	patrol_points = points
	current_patrol_index = 0

func stop_patrol():
	"""Stop patrolling"""
	is_waiting = true
	wait_timer = 999999.0
	velocity = Vector3.ZERO
	if sprite:
		if sprite is AnimatedSprite3D:
			sprite.stop()
			sprite.frame = 0  # Show Idle1/Walk1 frame
		if sprite.has_method("set_flip_h"):
			sprite.flip_h = false  # Face forward

func resume_patrol():
	"""Resume patrolling"""
	is_waiting = false
	wait_timer = 0.0

func get_npc_name():
	"""Return the NPC's name for chat system"""
	return npc_name
