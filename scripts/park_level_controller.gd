extends Node3D

# Park Level Controller - Main game logic for Template1
signal level_loaded
signal player_entered_water
signal player_exited_water

@onready var player = null  # Will be created dynamically
@onready var camera = $Camera3D
@onready var pond_water_area = $Pond/WaterArea if has_node("Pond/WaterArea") else null
@onready var particle_effects = $ParticleEffects
@onready var trees = $Trees
@onready var bushes = $Bushes

# Player movement
const MOVE_SPEED = 8.0
const WATER_MOVE_SPEED = 3.5  # Slower movement in water
const ROTATION_SPEED = 3.0
const GRAVITY = -9.8
const JUMP_VELOCITY = 6.0
const WATER_JUMP_MULTIPLIER = 0.5  # Reduced jump in water

# Environmental physics
var is_in_water = false
var water_depth = 0.0
var wind_strength = 1.0
var time_of_day = 12.0  # 24-hour cycle

# Bush/grass interaction
var nearby_bushes = []
var bush_shimmy_intensity = 0.0

# Camera control
var camera_rotation = 0.0
var camera_distance = 20.0
var camera_height = 15.0

func _ready():
	print("Park Level Controller initialized")
	
	# Connect water area signals
	if pond_water_area:
		pond_water_area.body_entered.connect(_on_water_entered)
		pond_water_area.body_exited.connect(_on_water_exited)
	
	# Setup environmental elements
	_setup_trees()
	_setup_bushes()
	_setup_benches()
	_setup_particle_effects()
	
	# Initialize player
	_setup_player()
	
	# Setup wind system
	_setup_wind_system()
	
	# Start environmental cycles
	_start_environmental_cycles()
	
	emit_signal("level_loaded")

func _setup_player():
	"""Initialize player character with sprite system"""
	# Check if Player node exists in scene
	if has_node("Player"):
		player = $Player
		print("Using existing player from scene")
		
		# Add the park player script if not already attached
		if not player.has_method("set_water_state"):
			var player_script = load("res://scripts/player_park.gd")
			if player_script:
				player.set_script(player_script)
	else:
		print("Creating player character dynamically...")
		player = CharacterBody3D.new()
		player.name = "Player"
		
		# Add the park player script
		var player_script = load("res://scripts/player_park.gd")
		if player_script:
			player.set_script(player_script)
		
		add_child(player)
		
		# Add collision
		var collision_shape = CollisionShape3D.new()
		var capsule_shape = CapsuleShape3D.new()
		capsule_shape.height = 2.0
		capsule_shape.radius = 0.5
		collision_shape.shape = capsule_shape
		player.add_child(collision_shape)
		
		# Position player above ground
		player.position = Vector3(0, 2, 10)
		player.collision_layer = 2
		player.collision_mask = 1  # Collide with world
	
	# Ensure player is valid
	if player:
		print("Player initialized at position: ", player.position)
		
		# Connect player signals
		if player.has_signal("player_interacted"):
			player.player_interacted.connect(_on_player_interacted)

func _setup_trees():
	"""Create tree instances around the park"""
	var tree_positions = [
		Vector3(-30, 0, -30), Vector3(30, 0, -30),
		Vector3(-30, 0, 30), Vector3(30, 0, 30),
		Vector3(-45, 0, 0), Vector3(45, 0, 0),
		Vector3(0, 0, -45), Vector3(0, 0, 45),
		Vector3(-20, 0, -40), Vector3(20, 0, -40),
		Vector3(-40, 0, -20), Vector3(40, 0, -20),
		Vector3(-20, 0, 40), Vector3(20, 0, 40),
		Vector3(-40, 0, 20), Vector3(40, 0, 20)
	]
	
	for pos in tree_positions:
		_create_tree(pos)

func _create_tree(position: Vector3):
	"""Create a single tree at the given position"""
	var tree = StaticBody3D.new()
	tree.position = position
	tree.collision_layer = 1
	
	# Tree trunk
	var trunk = MeshInstance3D.new()
	var trunk_mesh = CylinderMesh.new()
	trunk_mesh.height = 6.0
	trunk_mesh.top_radius = 0.3
	trunk_mesh.bottom_radius = 0.5
	trunk.mesh = trunk_mesh
	trunk.position.y = 3.0
	
	# Tree trunk material
	var trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_color = Color(0.3, 0.2, 0.1)
	trunk.material_override = trunk_material
	tree.add_child(trunk)
	
	# Tree leaves (3 sphere clusters)
	for i in range(3):
		var leaves = MeshInstance3D.new()
		var leaves_mesh = SphereMesh.new()
		leaves_mesh.radius = 2.5 - (i * 0.3)
		leaves_mesh.height = 5.0 - (i * 0.6)
		leaves.mesh = leaves_mesh
		leaves.position.y = 6.0 + (i * 1.5)
		
		# Leaves material
		var leaves_material = StandardMaterial3D.new()
		leaves_material.albedo_color = Color(0.1 + (i * 0.05), 0.4 + (i * 0.1), 0.1)
		leaves_material.roughness = 1.0
		leaves.material_override = leaves_material
		tree.add_child(leaves)
	
	# Collision for trunk
	var collision = CollisionShape3D.new()
	var collision_shape = CylinderShape3D.new()
	collision_shape.height = 6.0
	collision_shape.radius = 0.5
	collision.shape = collision_shape
	collision.position.y = 3.0
	tree.add_child(collision)
	
	trees.add_child(tree)

func _setup_bushes():
	"""Create bushes with physics interaction"""
	var bush_positions = [
		Vector3(-15, 0, -15), Vector3(15, 0, -15),
		Vector3(-15, 0, 15), Vector3(15, 0, 15),
		Vector3(-25, 0, -5), Vector3(25, 0, -5),
		Vector3(-25, 0, 5), Vector3(25, 0, 5),
		Vector3(-5, 0, -25), Vector3(5, 0, -25),
		Vector3(-5, 0, 25), Vector3(5, 0, 25)
	]
	
	for pos in bush_positions:
		_create_interactive_bush(pos)

func _create_interactive_bush(position: Vector3):
	"""Create a bush that shimmers when walked through"""
	var bush = Area3D.new()
	bush.position = position
	bush.collision_layer = 16  # Unique layer for bushes
	bush.collision_mask = 2  # Detect player
	
	# Bush mesh
	var mesh_instance = MeshInstance3D.new()
	var bush_mesh = SphereMesh.new()
	bush_mesh.radius = 1.2
	bush_mesh.height = 1.8
	mesh_instance.mesh = bush_mesh
	mesh_instance.position.y = 0.9
	
	# Bush material
	var bush_material = StandardMaterial3D.new()
	bush_material.albedo_color = Color(0.2, 0.45, 0.15)
	bush_material.roughness = 1.0
	mesh_instance.material_override = bush_material
	bush.add_child(mesh_instance)
	
	# Detection area
	var detection = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = 1.5
	detection.shape = detection_shape
	detection.position.y = 0.9
	bush.add_child(detection)
	
	# Connect signals for shimmy effect
	bush.body_entered.connect(_on_bush_entered.bind(bush))
	bush.body_exited.connect(_on_bush_exited.bind(bush))
	
	# Store mesh instance reference for animation
	bush.set_meta("mesh_instance", mesh_instance)
	bush.set_meta("original_position", position)
	bush.set_meta("shimmy_amount", 0.0)
	
	bushes.add_child(bush)

func _setup_particle_effects():
	"""Setup environmental particle effects"""
	# Falling leaves particle system
	var leaves_particles = GPUParticles3D.new()
	leaves_particles.amount = 50
	leaves_particles.lifetime = 15.0
	leaves_particles.position = Vector3(0, 20, 0)
	leaves_particles.visibility_aabb = AABB(Vector3(-64, -20, -64), Vector3(128, 40, 128))
	leaves_particles.emitting = true
	
	# Create process material for leaves
	var process_material = ParticleProcessMaterial.new()
	process_material.initial_velocity_min = 0.5
	process_material.initial_velocity_max = 1.5
	process_material.angular_velocity_min = -180.0
	process_material.angular_velocity_max = 180.0
	process_material.gravity = Vector3(0, -0.5, 0)
	process_material.damping_min = 0.5
	process_material.damping_max = 1.0
	process_material.scale_min = 0.3
	process_material.scale_max = 0.8
	process_material.color = Color(0.8, 0.6, 0.2)
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(60, 0.1, 60)
	
	# Add wind effect
	process_material.direction = Vector3(0.5, -1, 0.2)
	process_material.spread = 45.0
	
	leaves_particles.process_material = process_material
	
	# Create leaf mesh
	var leaf_mesh = QuadMesh.new()
	leaf_mesh.size = Vector2(0.5, 0.5)
	leaves_particles.draw_pass_1 = leaf_mesh
	
	particle_effects.add_child(leaves_particles)
	
	# Add fireflies for evening (disabled by default)
	_create_firefly_particles()

func _create_firefly_particles():
	"""Create firefly particle effect for evening ambiance"""
	var fireflies = GPUParticles3D.new()
	fireflies.name = "Fireflies"
	fireflies.amount = 30
	fireflies.lifetime = 20.0
	fireflies.position = Vector3(0, 2, 0)
	fireflies.visibility_aabb = AABB(Vector3(-64, 0, -64), Vector3(128, 10, 128))
	fireflies.emitting = false  # Will enable in evening
	
	var process_material = ParticleProcessMaterial.new()
	process_material.initial_velocity_min = 0.1
	process_material.initial_velocity_max = 0.3
	process_material.gravity = Vector3(0, 0, 0)
	process_material.damping_min = 1.0
	process_material.damping_max = 2.0
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(60, 2, 60)
	process_material.color = Color(1.0, 1.0, 0.3, 1.0)
	
	fireflies.process_material = process_material
	
	# Glowing point mesh
	var firefly_mesh = SphereMesh.new()
	firefly_mesh.radius = 0.1
	firefly_mesh.height = 0.2
	
	# Emissive material for glow
	var firefly_material = StandardMaterial3D.new()
	firefly_material.albedo_color = Color(1.0, 1.0, 0.3)
	firefly_material.emission_enabled = true
	firefly_material.emission = Color(1.0, 0.9, 0.3)
	firefly_material.emission_energy = 2.0
	firefly_mesh.surface_set_material(0, firefly_material)
	
	fireflies.draw_pass_1 = firefly_mesh
	particle_effects.add_child(fireflies)

func _setup_benches():
	"""Setup interactive benches"""
	var bench_script = load("res://scripts/bench_controller.gd")
	
	for bench in $Benches.get_children():
		if bench_script:
			bench.set_script(bench_script)

func _setup_wind_system():
	"""Initialize wind system"""
	var wind_system = Node3D.new()
	wind_system.name = "WindSystem"
	wind_system.set_script(load("res://scripts/wind_system.gd"))
	add_child(wind_system)
	
	# Register all trees and bushes with wind system
	await get_tree().process_frame
	var wind = $WindSystem
	if wind:
		for tree in trees.get_children():
			wind.register_tree(tree)
		for bush in bushes.get_children():
			wind.register_bush(bush)
		for particles in particle_effects.get_children():
			if particles is GPUParticles3D:
				wind.register_particles(particles)

func _start_environmental_cycles():
	"""Start time of day and weather cycles"""
	# Create weather system
	var weather_system = Node3D.new()
	weather_system.name = "WeatherSystem"
	weather_system.set_script(load("res://scripts/weather_system.gd"))
	add_child(weather_system)
	
	# Create a timer for day/night cycle
	var day_cycle_timer = Timer.new()
	day_cycle_timer.wait_time = 60.0  # 1 minute = 1 game hour
	day_cycle_timer.timeout.connect(_update_time_of_day)
	day_cycle_timer.autostart = true
	add_child(day_cycle_timer)
	
	# Create timer for weather changes
	var weather_timer = Timer.new()
	weather_timer.wait_time = 120.0  # Weather changes every 2 minutes
	weather_timer.timeout.connect(_change_weather)
	weather_timer.autostart = true
	add_child(weather_timer)

func _physics_process(delta):
	"""Handle physics-based movement and interactions"""
	if not player:
		# Try to find or create player if missing
		if has_node("Player"):
			player = $Player
		else:
			_setup_player()
		return
	
	# Get input
	var input_vector = Vector2()
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	
	input_vector = input_vector.normalized()
	
	# Calculate movement
	var direction = Vector3()
	direction.x = input_vector.x
	direction.z = input_vector.y
	
	# Apply speed modifier if in water
	var current_speed = WATER_MOVE_SPEED if is_in_water else MOVE_SPEED
	
	# Move player
	if direction.length() > 0:
		player.velocity.x = direction.x * current_speed
		player.velocity.z = direction.z * current_speed
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, current_speed * delta)
		player.velocity.z = move_toward(player.velocity.z, 0, current_speed * delta)
	
	# Apply gravity
	if not player.is_on_floor():
		player.velocity.y += GRAVITY * delta
	
	# Handle jump
	if Input.is_action_just_pressed("ui_accept") and player.is_on_floor():
		var jump_force = JUMP_VELOCITY
		if is_in_water:
			jump_force *= WATER_JUMP_MULTIPLIER
		player.velocity.y = jump_force
	
	# Move and slide
	player.move_and_slide()
	
	# Update camera to follow player
	_update_camera(delta)
	
	# Update bush shimmy effects
	_update_bush_physics(delta)

func _update_camera(delta):
	"""Update camera to follow player"""
	if not camera or not player:
		return
	
	# Handle camera rotation
	if Input.is_action_pressed("camera_rotate_left"):
		camera_rotation -= ROTATION_SPEED * delta
	if Input.is_action_pressed("camera_rotate_right"):
		camera_rotation += ROTATION_SPEED * delta
	
	# Calculate camera position
	var cam_x = sin(camera_rotation) * camera_distance
	var cam_z = cos(camera_rotation) * camera_distance
	
	# Ensure camera stays above minimum height
	var player_pos = player.global_position if player else Vector3(0, 1, 10)
	var target_pos = player_pos + Vector3(cam_x, camera_height, cam_z)
	
	# Clamp camera height to avoid going below ground
	target_pos.y = max(target_pos.y, 5.0)
	
	# Smooth camera movement
	camera.position = camera.position.lerp(target_pos, 5.0 * delta)
	
	# Look at player position
	var look_target = player_pos + Vector3(0, 1, 0)
	camera.look_at(look_target, Vector3.UP)

func _update_bush_physics(delta):
	"""Update shimmy effect for bushes player is moving through"""
	for bush in bushes.get_children():
		var shimmy = bush.get_meta("shimmy_amount", 0.0)
		if shimmy > 0:
			var mesh = bush.get_meta("mesh_instance")
			if mesh:
				# Apply shimmy animation
				var offset = sin(Time.get_ticks_msec() * 0.02) * shimmy * 0.1
				mesh.position.x = offset
				
				# Decay shimmy over time
				shimmy = max(0, shimmy - delta * 2.0)
				bush.set_meta("shimmy_amount", shimmy)

func _on_water_entered(body):
	"""Handle player entering water"""
	if body == player:
		is_in_water = true
		emit_signal("player_entered_water")
		print("Player entered water - movement slowed")
		
		# Update player water state
		if player.has_method("set_water_state"):
			player.set_water_state(true)
		
		# Add water splash effect
		_create_water_splash(player.global_position)
		
		# Add water ripple effect
		_start_water_ripples()

func _on_water_exited(body):
	"""Handle player exiting water"""
	if body == player:
		is_in_water = false
		emit_signal("player_exited_water")
		print("Player exited water - normal movement restored")
		
		# Update player water state
		if player.has_method("set_water_state"):
			player.set_water_state(false)
		
		# Stop water ripples
		_stop_water_ripples()

func _on_bush_entered(body, bush):
	"""Handle player entering bush area"""
	if body == player:
		bush.set_meta("shimmy_amount", 1.0)
		nearby_bushes.append(bush)
		print("Walking through bush - shimmy effect activated")

func _on_bush_exited(body, bush):
	"""Handle player exiting bush area"""
	if body == player:
		nearby_bushes.erase(bush)

func _create_water_splash(position: Vector3):
	"""Create water splash particle effect"""
	var splash = CPUParticles3D.new()
	splash.position = position
	splash.amount = 30
	splash.lifetime = 0.5
	splash.one_shot = true
	splash.emitting = true
	
	splash.initial_velocity_min = 2.0
	splash.initial_velocity_max = 4.0
	splash.direction = Vector3(0, 1, 0)
	splash.spread = 45.0
	splash.gravity = Vector3(0, -9.8, 0)
	splash.scale_amount_min = 0.1
	splash.scale_amount_max = 0.3
	
	# Water droplet mesh
	var droplet_mesh = SphereMesh.new()
	droplet_mesh.radius = 0.05
	droplet_mesh.height = 0.1
	splash.mesh = droplet_mesh
	
	# Water material
	var water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.3, 0.5, 0.7, 0.8)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	droplet_mesh.surface_set_material(0, water_mat)
	
	add_child(splash)
	
	# Clean up after emission
	splash.finished.connect(splash.queue_free)

func set_time_of_day(hour: float):
	"""Update environment based on time of day"""
	time_of_day = hour
	
	# Enable fireflies in evening
	var fireflies = particle_effects.get_node("Fireflies")
	if fireflies:
		fireflies.emitting = (hour >= 19.0 or hour <= 5.0)
	
	# Adjust lighting and fog based on time
	var world_env = $WorldEnvironment
	if world_env and world_env.environment:
		var env = world_env.environment
		
		# Dawn (5-7)
		if hour >= 5.0 and hour < 7.0:
			env.ambient_light_energy = lerp(0.2, 0.6, (hour - 5.0) / 2.0)
			env.fog_density = lerp(0.005, 0.001, (hour - 5.0) / 2.0)
		# Day (7-17)
		elif hour >= 7.0 and hour < 17.0:
			env.ambient_light_energy = 0.6
			env.fog_density = 0.001
		# Dusk (17-19)
		elif hour >= 17.0 and hour < 19.0:
			env.ambient_light_energy = lerp(0.6, 0.3, (hour - 17.0) / 2.0)
			env.fog_density = lerp(0.001, 0.003, (hour - 17.0) / 2.0)
		# Night (19-5)
		else:
			env.ambient_light_energy = 0.2
			env.fog_density = 0.005

func _update_time_of_day():
	"""Called by timer to advance time"""
	time_of_day += 1.0
	if time_of_day >= 24.0:
		time_of_day = 0.0
	set_time_of_day(time_of_day)
	print("Time of day: ", int(time_of_day), ":00")

func _change_weather():
	"""Randomly change weather conditions"""
	# Change weather patterns
	var weather = $WeatherSystem
	if weather and weather.has_method("cycle_weather"):
		weather.cycle_weather()
	
	# Also update wind
	var wind = $WindSystem
	if wind:
		var new_strength = randf_range(0.5, 2.5)
		var new_direction = Vector3(
			randf_range(-1, 1),
			0,
			randf_range(-1, 1)
		).normalized()
		var new_gustiness = randf_range(0.1, 0.6)
		
		wind.set_wind_conditions(new_strength, new_direction, new_gustiness)
		
		# Stronger wind during storms
		if weather and weather.has_method("get_weather_name"):
			var weather_name = weather.get_weather_name()
			if weather_name == "STORMY":
				new_strength *= 2.0
				wind.set_wind_conditions(new_strength, new_direction, 0.8)

func _start_water_ripples():
	"""Start water ripple effect when player is in water"""
	# This could animate the water shader parameters
	var water_surface = $Pond/WaterSurface if has_node("Pond/WaterSurface") else null
	if water_surface and water_surface.material_override:
		var mat = water_surface.material_override
		if mat.has_method("set_shader_parameter"):
			mat.set_shader_parameter("wave_amplitude", 0.1)
			mat.set_shader_parameter("wave_speed", 0.8)

func _stop_water_ripples():
	"""Stop water ripple effect when player exits water"""
	var water_surface = $Pond/WaterSurface if has_node("Pond/WaterSurface") else null
	if water_surface and water_surface.material_override:
		var mat = water_surface.material_override
		if mat.has_method("set_shader_parameter"):
			mat.set_shader_parameter("wave_amplitude", 0.05)
			mat.set_shader_parameter("wave_speed", 0.5)

func _on_player_interacted():
	"""Handle player interaction attempts"""
	print("Player attempted interaction")
	# This would check for nearby NPCs, benches, etc.