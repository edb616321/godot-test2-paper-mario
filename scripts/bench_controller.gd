extends StaticBody3D

# Bench Controller - Handles bench interactions and visuals

signal player_sat_down
signal player_stood_up

var is_occupied = false
var sitting_player = null

func _ready():
	# Create visual representation
	_create_bench_visual()
	
	# Add interaction area
	_create_interaction_area()

func _create_bench_visual():
	"""Create the visual mesh for the bench"""
	# Bench seat
	var seat = MeshInstance3D.new()
	var seat_mesh = BoxMesh.new()
	seat_mesh.size = Vector3(3, 0.1, 1)
	seat.mesh = seat_mesh
	seat.position.y = 0.5
	
	# Bench material
	var wood_material = StandardMaterial3D.new()
	wood_material.albedo_color = Color(0.4, 0.25, 0.15)
	wood_material.roughness = 0.8
	seat.material_override = wood_material
	add_child(seat)
	
	# Bench back
	var back = MeshInstance3D.new()
	var back_mesh = BoxMesh.new()
	back_mesh.size = Vector3(3, 0.8, 0.1)
	back.mesh = back_mesh
	back.position = Vector3(0, 0.9, -0.4)
	back.material_override = wood_material
	add_child(back)
	
	# Bench legs
	for x in [-1.3, 1.3]:
		for z in [-0.4, 0.4]:
			var leg = MeshInstance3D.new()
			var leg_mesh = BoxMesh.new()
			leg_mesh.size = Vector3(0.15, 0.5, 0.15)
			leg.mesh = leg_mesh
			leg.position = Vector3(x, 0.25, z)
			leg.material_override = wood_material
			add_child(leg)
	
	# Collision shape for the bench
	var collision = CollisionShape3D.new()
	var collision_shape = BoxShape3D.new()
	collision_shape.size = Vector3(3, 1.5, 1)
	collision.shape = collision_shape
	collision.position.y = 0.75
	add_child(collision)

func _create_interaction_area():
	"""Create area for player interaction"""
	var interaction_area = Area3D.new()
	interaction_area.collision_layer = 0
	interaction_area.collision_mask = 2  # Detect player
	
	var area_collision = CollisionShape3D.new()
	var area_shape = BoxShape3D.new()
	area_shape.size = Vector3(4, 2, 2)
	area_collision.shape = area_shape
	area_collision.position.y = 1.0
	interaction_area.add_child(area_collision)
	
	# Connect signals
	interaction_area.body_entered.connect(_on_player_near)
	interaction_area.body_exited.connect(_on_player_left)
	
	add_child(interaction_area)

func _on_player_near(body):
	"""Handle player approaching bench"""
	if body.collision_layer == 2:  # Is player
		# Could show interaction prompt here
		pass

func _on_player_left(body):
	"""Handle player leaving bench area"""
	if body.collision_layer == 2:  # Is player
		if sitting_player == body:
			_stand_up(body)

func interact_with_player(player):
	"""Handle player sitting/standing"""
	if is_occupied:
		if sitting_player == player:
			_stand_up(player)
	else:
		_sit_down(player)

func _sit_down(player):
	"""Make player sit on bench"""
	is_occupied = true
	sitting_player = player
	
	# Position player on bench
	var sit_position = global_position + Vector3(0, 0.6, 0)
	player.global_position = sit_position
	
	# Could disable player movement here
	emit_signal("player_sat_down")

func _stand_up(player):
	"""Make player stand up from bench"""
	is_occupied = false
	sitting_player = null
	
	# Move player in front of bench
	var stand_position = global_position + Vector3(0, 0, 1.5)
	player.global_position = stand_position
	
	# Re-enable player movement
	emit_signal("player_stood_up")