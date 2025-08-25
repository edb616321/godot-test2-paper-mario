extends Node3D

# Creates a simple shadow quad under the character
# This is a workaround for billboard sprites not casting shadows properly

@export var shadow_size: float = 1.5
@export var shadow_opacity: float = 0.4
@export var shadow_offset_y: float = 0.05

func _ready():
	create_shadow()

func create_shadow():
	# Create a simple quad mesh for the shadow
	var shadow_mesh_instance = MeshInstance3D.new()
	shadow_mesh_instance.name = "ShadowQuad"
	
	# Create a quad mesh
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(shadow_size, shadow_size)
	shadow_mesh_instance.mesh = quad_mesh
	
	# Create a shadow material
	var shadow_material = StandardMaterial3D.new()
	shadow_material.albedo_color = Color(0, 0, 0, shadow_opacity)
	shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.vertex_color_use_as_albedo = false
	shadow_material.no_depth_test = false
	shadow_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Apply material
	shadow_mesh_instance.material_override = shadow_material
	
	# Position the shadow under the parent
	shadow_mesh_instance.position = Vector3(0, shadow_offset_y, 0)
	shadow_mesh_instance.rotation.x = deg_to_rad(-90)  # Flat on ground
	
	# Add to scene
	add_child(shadow_mesh_instance)