extends Node3D

# Enhanced Weather System with rain, snow, and dynamic effects

signal weather_changed(weather_type: String)

enum WeatherType {
	CLEAR,
	CLOUDY,
	RAINY,
	STORMY,
	FOGGY,
	SNOWY
}

# Current weather state
var current_weather: WeatherType = WeatherType.CLEAR
var weather_intensity: float = 0.0
var transition_speed: float = 1.0

# Weather components
var rain_particles: GPUParticles3D
var snow_particles: GPUParticles3D
var fog_node: Node3D
var thunder_timer: Timer
var lightning_flash: DirectionalLight3D

# Environment references
@onready var world_env = get_node("/root/ParkLevel/WorldEnvironment") if has_node("/root/ParkLevel/WorldEnvironment") else null
@onready var directional_light = get_node("/root/ParkLevel/DirectionalLight3D") if has_node("/root/ParkLevel/DirectionalLight3D") else null

# Weather parameters
var clear_fog_density = 0.001
var cloudy_fog_density = 0.005
var rainy_fog_density = 0.008
var stormy_fog_density = 0.01
var foggy_fog_density = 0.02

func _ready():
	print("Weather System initialized")
	
	# Setup weather effects
	_setup_rain()
	_setup_snow()
	_setup_thunder_and_lightning()
	
	# Start with clear weather
	set_weather(WeatherType.CLEAR)

func _setup_rain():
	"""Create rain particle system"""
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 1000
	rain_particles.lifetime = 2.0
	rain_particles.visibility_aabb = AABB(Vector3(-50, -5, -50), Vector3(100, 30, 100))
	rain_particles.emitting = false
	
	var process_material = ParticleProcessMaterial.new()
	process_material.initial_velocity_min = 15.0
	process_material.initial_velocity_max = 20.0
	process_material.direction = Vector3(0, -1, 0)
	process_material.spread = 5.0
	process_material.gravity = Vector3(0, -5, 0)
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(50, 0.1, 50)
	process_material.scale_min = 0.1
	process_material.scale_max = 0.2
	
	rain_particles.process_material = process_material
	rain_particles.position.y = 25
	
	# Rain drop mesh
	var rain_mesh = CylinderMesh.new()
	rain_mesh.height = 0.5
	rain_mesh.top_radius = 0.02
	rain_mesh.bottom_radius = 0.02
	rain_particles.draw_pass_1 = rain_mesh
	
	# Rain material
	var rain_material = StandardMaterial3D.new()
	rain_material.albedo_color = Color(0.4, 0.5, 0.6, 0.6)
	rain_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain_mesh.surface_set_material(0, rain_material)
	
	add_child(rain_particles)

func _setup_snow():
	"""Create snow particle system"""
	snow_particles = GPUParticles3D.new()
	snow_particles.name = "SnowParticles"
	snow_particles.amount = 500
	snow_particles.lifetime = 10.0
	snow_particles.visibility_aabb = AABB(Vector3(-50, -5, -50), Vector3(100, 30, 100))
	snow_particles.emitting = false
	
	var process_material = ParticleProcessMaterial.new()
	process_material.initial_velocity_min = 1.0
	process_material.initial_velocity_max = 2.0
	process_material.direction = Vector3(0, -1, 0.2)
	process_material.spread = 45.0
	process_material.gravity = Vector3(0, -1, 0)
	process_material.damping_min = 0.5
	process_material.damping_max = 1.0
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process_material.emission_box_extents = Vector3(50, 0.1, 50)
	process_material.scale_min = 0.1
	process_material.scale_max = 0.3
	# Add swaying motion
	process_material.turbulence_enabled = true
	process_material.turbulence_noise_strength = 2.0
	process_material.turbulence_noise_scale = 0.5
	
	snow_particles.process_material = process_material
	snow_particles.position.y = 25
	
	# Snowflake mesh
	var snow_mesh = SphereMesh.new()
	snow_mesh.radius = 0.05
	snow_mesh.height = 0.1
	snow_particles.draw_pass_1 = snow_mesh
	
	# Snow material
	var snow_material = StandardMaterial3D.new()
	snow_material.albedo_color = Color(1, 1, 1, 0.9)
	snow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	snow_mesh.surface_set_material(0, snow_material)
	
	add_child(snow_particles)

func _setup_thunder_and_lightning():
	"""Setup thunder and lightning effects for storms"""
	# Lightning flash light
	lightning_flash = DirectionalLight3D.new()
	lightning_flash.name = "LightningFlash"
	lightning_flash.light_energy = 0.0
	lightning_flash.rotation_degrees = Vector3(-45, -45, 0)
	add_child(lightning_flash)
	
	# Thunder timer
	thunder_timer = Timer.new()
	thunder_timer.name = "ThunderTimer"
	thunder_timer.wait_time = randf_range(5.0, 15.0)
	thunder_timer.timeout.connect(_trigger_lightning)
	add_child(thunder_timer)

func set_weather(weather_type: WeatherType, intensity: float = 1.0):
	"""Change the current weather"""
	current_weather = weather_type
	weather_intensity = clamp(intensity, 0.0, 1.0)
	
	# Stop all weather effects first
	rain_particles.emitting = false
	snow_particles.emitting = false
	thunder_timer.stop()
	lightning_flash.light_energy = 0.0
	
	# Apply weather-specific settings
	match weather_type:
		WeatherType.CLEAR:
			_set_clear_weather()
		WeatherType.CLOUDY:
			_set_cloudy_weather()
		WeatherType.RAINY:
			_set_rainy_weather()
		WeatherType.STORMY:
			_set_stormy_weather()
		WeatherType.FOGGY:
			_set_foggy_weather()
		WeatherType.SNOWY:
			_set_snowy_weather()
	
	emit_signal("weather_changed", WeatherType.keys()[weather_type])

func _set_clear_weather():
	"""Clear, sunny weather"""
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_density = clear_fog_density
		env.ambient_light_energy = 0.6
	
	if directional_light:
		directional_light.light_energy = 0.8
		directional_light.light_color = Color(1, 0.95, 0.8)

func _set_cloudy_weather():
	"""Cloudy weather"""
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_density = cloudy_fog_density
		env.ambient_light_energy = 0.5
	
	if directional_light:
		directional_light.light_energy = 0.6
		directional_light.light_color = Color(0.9, 0.9, 0.95)

func _set_rainy_weather():
	"""Rainy weather"""
	rain_particles.emitting = true
	rain_particles.amount = int(500 * weather_intensity)
	
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_density = rainy_fog_density
		env.ambient_light_energy = 0.4
		env.fog_light_color = Color(0.7, 0.7, 0.75)
	
	if directional_light:
		directional_light.light_energy = 0.5
		directional_light.light_color = Color(0.8, 0.8, 0.85)

func _set_stormy_weather():
	"""Stormy weather with thunder and lightning"""
	rain_particles.emitting = true
	rain_particles.amount = int(1000 * weather_intensity)
	thunder_timer.start()
	
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_density = stormy_fog_density
		env.ambient_light_energy = 0.3
		env.fog_light_color = Color(0.6, 0.6, 0.65)
	
	if directional_light:
		directional_light.light_energy = 0.3
		directional_light.light_color = Color(0.7, 0.7, 0.75)

func _set_foggy_weather():
	"""Dense fog"""
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_density = foggy_fog_density * weather_intensity
		env.ambient_light_energy = 0.5
		env.fog_light_color = Color(0.85, 0.85, 0.85)
	
	if directional_light:
		directional_light.light_energy = 0.4
		directional_light.light_color = Color(0.95, 0.95, 1.0)

func _set_snowy_weather():
	"""Snowy weather"""
	snow_particles.emitting = true
	snow_particles.amount = int(300 * weather_intensity)
	
	if world_env and world_env.environment:
		var env = world_env.environment
		env.fog_density = cloudy_fog_density
		env.ambient_light_energy = 0.6
		env.fog_light_color = Color(0.95, 0.95, 1.0)
		# Make everything slightly brighter for snow
		env.ambient_light_color = Color(0.9, 0.95, 1.0)
	
	if directional_light:
		directional_light.light_energy = 0.7
		directional_light.light_color = Color(0.95, 0.95, 1.0)

func _trigger_lightning():
	"""Create lightning flash effect"""
	# Visual flash
	lightning_flash.light_energy = 3.0
	
	# Fade out the flash
	var tween = create_tween()
	tween.tween_property(lightning_flash, "light_energy", 0.0, 0.3)
	
	# Schedule next lightning
	thunder_timer.wait_time = randf_range(5.0, 15.0)
	
	# Could add thunder sound here
	print("Lightning strike!")

func cycle_weather():
	"""Randomly change to a new weather pattern"""
	var weather_options = [
		WeatherType.CLEAR,
		WeatherType.CLEAR,  # More likely to be clear
		WeatherType.CLOUDY,
		WeatherType.RAINY,
		WeatherType.FOGGY,
		WeatherType.SNOWY if randf() > 0.7 else WeatherType.CLEAR  # Snow is rarer
	]
	
	if current_weather == WeatherType.RAINY and randf() < 0.3:
		# 30% chance rain becomes storm
		set_weather(WeatherType.STORMY, randf_range(0.5, 1.0))
	else:
		var new_weather = weather_options[randi() % weather_options.size()]
		var new_intensity = randf_range(0.3, 1.0)
		set_weather(new_weather, new_intensity)

func get_weather_name() -> String:
	"""Get current weather as string"""
	return WeatherType.keys()[current_weather]