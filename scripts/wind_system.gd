extends Node3D

# Wind System - Manages environmental wind effects

signal wind_changed(strength: float, direction: Vector3)

# Wind properties
var wind_strength: float = 1.0
var wind_direction: Vector3 = Vector3(1, 0, 0.5).normalized()
var wind_gustiness: float = 0.3
var wind_cycle_time: float = 0.0

# Wind variation parameters
const BASE_WIND_SPEED = 1.0
const GUST_FREQUENCY = 0.1
const GUST_STRENGTH = 2.0

# Affected objects
var affected_trees: Array = []
var affected_bushes: Array = []
var affected_particles: Array = []

func _ready():
	print("Wind System initialized")
	set_process(true)

func _process(delta):
	"""Update wind patterns"""
	wind_cycle_time += delta
	
	# Calculate wind variations
	var base_wind = sin(wind_cycle_time * 0.3) * 0.5 + 0.5
	var gust = sin(wind_cycle_time * GUST_FREQUENCY * 10.0) * wind_gustiness
	
	# Random gusts
	if randf() < 0.01:  # 1% chance per frame for a gust
		gust += randf_range(0.5, GUST_STRENGTH)
	
	# Update wind strength
	wind_strength = BASE_WIND_SPEED * base_wind + gust
	wind_strength = clamp(wind_strength, 0.0, 3.0)
	
	# Slightly vary wind direction
	var dir_variation = Vector3(
		sin(wind_cycle_time * 0.7) * 0.2,
		0,
		cos(wind_cycle_time * 0.5) * 0.2
	)
	wind_direction = (wind_direction + dir_variation * 0.1).normalized()
	
	# Apply wind to affected objects
	_apply_wind_to_objects(delta)

func _apply_wind_to_objects(delta):
	"""Apply wind effects to registered objects"""
	# Trees sway more at the top
	for tree in affected_trees:
		if is_instance_valid(tree):
			_apply_wind_to_tree(tree, delta)
	
	# Bushes shake
	for bush in affected_bushes:
		if is_instance_valid(bush):
			_apply_wind_to_bush(bush, delta)
	
	# Particles drift
	for particles in affected_particles:
		if is_instance_valid(particles) and particles.process_material:
			var mat = particles.process_material
			# Update particle wind direction
			mat.direction = wind_direction
			mat.initial_velocity_min = wind_strength * 0.5
			mat.initial_velocity_max = wind_strength * 1.5

func _apply_wind_to_tree(tree: Node3D, delta):
	"""Apply wind sway to tree"""
	# Use delta to smooth animation
	var _delta_used = delta
	# Find leaf meshes (usually children of the tree)
	for child in tree.get_children():
		if child is MeshInstance3D and child.position.y > 3.0:  # Leaves are higher up
			var sway_amount = wind_strength * 0.05
			var sway_speed = wind_strength * 2.0
			
			# Calculate sway
			var offset_x = sin(wind_cycle_time * sway_speed) * sway_amount * wind_direction.x
			var offset_z = sin(wind_cycle_time * sway_speed * 0.8) * sway_amount * wind_direction.z
			
			# Apply as slight rotation for more natural look
			child.rotation.x = offset_x
			child.rotation.z = offset_z

func _apply_wind_to_bush(bush: Node3D, delta):
	"""Apply wind shake to bush"""
	# Use delta to smooth animation
	var _delta_used = delta
	if bush.has_meta("mesh_instance"):
		var mesh = bush.get_meta("mesh_instance")
		if is_instance_valid(mesh):
			var shake_amount = wind_strength * 0.02
			var shake_speed = wind_strength * 5.0
			
			# Quick shaking motion
			var offset = sin(wind_cycle_time * shake_speed + bush.position.x) * shake_amount
			mesh.position.x = offset * wind_direction.x
			mesh.position.z = offset * wind_direction.z

func register_tree(tree: Node3D):
	"""Register a tree for wind effects"""
	if not affected_trees.has(tree):
		affected_trees.append(tree)

func register_bush(bush: Node3D):
	"""Register a bush for wind effects"""
	if not affected_bushes.has(bush):
		affected_bushes.append(bush)

func register_particles(particles: GPUParticles3D):
	"""Register particle system for wind effects"""
	if not affected_particles.has(particles):
		affected_particles.append(particles)

func set_wind_conditions(strength: float, direction: Vector3, gustiness: float = 0.3):
	"""Manually set wind conditions"""
	wind_strength = clamp(strength, 0.0, 3.0)
	wind_direction = direction.normalized()
	wind_gustiness = clamp(gustiness, 0.0, 1.0)
	emit_signal("wind_changed", wind_strength, wind_direction)

func get_wind_at_position(wind_position: Vector3) -> Vector3:
	"""Get wind vector at a specific position (for localized effects)"""
	# Could add position-based variations here
	# Use wind_position to avoid shadowing Node3D.position
	var _pos = wind_position
	return wind_direction * wind_strength