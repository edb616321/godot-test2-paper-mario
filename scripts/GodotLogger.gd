extends Node

# GodotLogger - Comprehensive logging system for Godot errors and console output
# This captures all errors, warnings, and prints to a log file

var log_file_path = "user://godot_console.log"
var error_log_path = "user://godot_errors.log"
var project_log_path = "res://godot_runtime.log"
var file_handle: FileAccess
var error_handle: FileAccess
var max_log_size = 1048576  # 1MB max log size before rotation

var error_count = 0
var warning_count = 0
var last_errors = []

func _ready():
	print("=== GODOT LOGGER INITIALIZED ===")
	
	# Set this as the custom error handler
	_setup_error_handling()
	
	# Open log files
	_open_log_files()
	
	# Log system info
	_log_system_info()
	
	# Start monitoring
	_start_monitoring()
	
	# Log initial scene state
	_log_scene_state()

func _setup_error_handling():
	"""Setup custom error handling"""
	# Connect to various debug signals if available
	if OS.has_feature("debug"):
		print("Debug mode enabled - enhanced logging active")
	
	# Override the default print handlers
	set_process(true)

func _open_log_files():
	"""Open log files for writing"""
	# Main console log
	var user_dir = OS.get_user_data_dir()
	print("Log files location: ", user_dir)
	
	# Create main log file
	file_handle = FileAccess.open(log_file_path, FileAccess.WRITE)
	if file_handle:
		file_handle.store_line("=== GODOT CONSOLE LOG ===")
		file_handle.store_line("Started: " + Time.get_datetime_string_from_system())
		file_handle.store_line("Project: Template1")
		file_handle.store_line("=====================================\n")
	
	# Create error-only log
	error_handle = FileAccess.open(error_log_path, FileAccess.WRITE)
	if error_handle:
		error_handle.store_line("=== GODOT ERROR LOG ===")
		error_handle.store_line("Started: " + Time.get_datetime_string_from_system())
		error_handle.store_line("========================\n")
	
	# Also create a log in the project folder for easy access
	var project_handle = FileAccess.open(project_log_path, FileAccess.WRITE)
	if project_handle:
		project_handle.store_line("=== TEMPLATE1 RUNTIME LOG ===")
		project_handle.store_line("Started: " + Time.get_datetime_string_from_system())
		project_handle.close()

func _log_system_info():
	"""Log system and project information"""
	log_message("SYSTEM", "Godot Version: " + Engine.get_version_info().string)
	log_message("SYSTEM", "OS: " + OS.get_name())
	log_message("SYSTEM", "Video Adapter: " + RenderingServer.get_video_adapter_name())
	log_message("SYSTEM", "Debug Build: " + str(OS.has_feature("debug")))

func _log_scene_state():
	"""Log current scene structure and potential issues"""
	var root = get_tree().root
	var park_level = root.get_node_or_null("ParkLevel")
	
	if not park_level:
		log_error("ParkLevel node not found in scene tree!")
		return
	
	log_message("SCENE", "ParkLevel found - checking structure...")
	
	# Check Player
	var player = park_level.get_node_or_null("Player")
	if player:
		log_message("SCENE", "✓ Player found at: " + str(player.position))
		var sprite = player.get_node_or_null("Sprite3D")
		if sprite:
			log_message("SCENE", "  ✓ Player Sprite3D found")
			log_message("SCENE", "    - Y position: " + str(sprite.position.y))
			log_message("SCENE", "    - Pixel size: " + str(sprite.pixel_size))
			if sprite.position.y != 4.0:
				log_error("SPRITE ALIGNMENT ERROR: Player sprite Y should be 4.0, but is " + str(sprite.position.y))
			if sprite.pixel_size != 0.01:
				log_error("SPRITE SIZE ERROR: Player pixel_size should be 0.01, but is " + str(sprite.pixel_size))
		else:
			log_error("Player Sprite3D not found!")
	else:
		log_error("Player node not found!")
	
	# Check NPCs
	var npcs = park_level.get_node_or_null("NPCs")
	if npcs:
		log_message("SCENE", "✓ NPCs node found")
		for npc in npcs.get_children():
			log_message("SCENE", "  - NPC: " + npc.name + " at " + str(npc.position))
			
			# Check for Sprite3D
			var sprite = npc.get_node_or_null("Sprite3D")
			if sprite:
				log_message("SCENE", "    ✓ Sprite3D found (Y=" + str(sprite.position.y) + ", pixel_size=" + str(sprite.pixel_size) + ")")
			else:
				log_error("NPC " + npc.name + " missing Sprite3D!")
			
			# Check for AnimatedSprite3D (from error messages)
			var anim_sprite = npc.get_node_or_null("AnimatedSprite3D")
			if anim_sprite:
				log_message("SCENE", "    ✓ AnimatedSprite3D found")
			else:
				log_warning("NPC " + npc.name + " has no AnimatedSprite3D (might be looking for it in scripts)")
	else:
		log_error("NPCs node not found!")

func _start_monitoring():
	"""Start monitoring for errors and warnings"""
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(_periodic_check)
	timer.autostart = true
	add_child(timer)

func _periodic_check():
	"""Periodic check for issues"""
	if error_count > 0 or warning_count > 0:
		log_message("STATUS", "Errors: " + str(error_count) + ", Warnings: " + str(warning_count))
	
	# Flush logs
	if file_handle:
		file_handle.flush()
	if error_handle:
		error_handle.flush()

func log_message(category: String, message: String):
	"""Log a general message"""
	var timestamp = Time.get_datetime_string_from_system()
	var log_line = "[" + timestamp + "] [" + category + "] " + message
	
	print(log_line)
	
	if file_handle:
		file_handle.store_line(log_line)
	
	# Also append to project log
	var project_handle = FileAccess.open(project_log_path, FileAccess.WRITE_READ)
	if project_handle:
		project_handle.seek_end()
		project_handle.store_line(log_line)
		project_handle.close()

func log_error(message: String):
	"""Log an error message"""
	error_count += 1
	last_errors.append(message)
	if last_errors.size() > 10:
		last_errors.pop_front()
	
	var timestamp = Time.get_datetime_string_from_system()
	var error_line = "[" + timestamp + "] [ERROR] " + message
	
	push_error(message)
	
	if file_handle:
		file_handle.store_line(error_line)
	
	if error_handle:
		error_handle.store_line(error_line)
		error_handle.flush()
	
	# Also append to project log
	var project_handle = FileAccess.open(project_log_path, FileAccess.WRITE_READ)
	if project_handle:
		project_handle.seek_end()
		project_handle.store_line(error_line)
		project_handle.close()

func log_warning(message: String):
	"""Log a warning message"""
	warning_count += 1
	
	var timestamp = Time.get_datetime_string_from_system()
	var warning_line = "[" + timestamp + "] [WARNING] " + message
	
	push_warning(message)
	
	if file_handle:
		file_handle.store_line(warning_line)

func _notification(what):
	"""Handle system notifications"""
	if what == NOTIFICATION_CRASH:
		log_error("CRASH DETECTED!")
		close_logs()
	elif what == NOTIFICATION_EXIT_TREE:
		log_message("SYSTEM", "Shutting down logger...")
		close_logs()

func close_logs():
	"""Close all log files"""
	if file_handle:
		file_handle.store_line("\n=== LOG CLOSED ===")
		file_handle.store_line("Ended: " + Time.get_datetime_string_from_system())
		file_handle.store_line("Total Errors: " + str(error_count))
		file_handle.store_line("Total Warnings: " + str(warning_count))
		file_handle.close()
	
	if error_handle:
		error_handle.store_line("\n=== ERROR LOG CLOSED ===")
		error_handle.store_line("Total Errors: " + str(error_count))
		error_handle.close()

func get_log_path() -> String:
	"""Get the full path to the main log file"""
	return OS.get_user_data_dir() + "/" + log_file_path.replace("user://", "")

func get_error_log_path() -> String:
	"""Get the full path to the error log file"""
	return OS.get_user_data_dir() + "/" + error_log_path.replace("user://", "")

func export_logs_to_project():
	"""Export logs to project folder for easy access"""
	var export_path = "res://exported_logs_" + Time.get_datetime_string_from_system().replace(":", "_") + ".txt"
	var export_handle = FileAccess.open(export_path, FileAccess.WRITE)
	
	if export_handle:
		export_handle.store_line("=== EXPORTED GODOT LOGS ===")
		export_handle.store_line("Exported: " + Time.get_datetime_string_from_system())
		export_handle.store_line("Errors: " + str(error_count))
		export_handle.store_line("Warnings: " + str(warning_count))
		export_handle.store_line("\n=== RECENT ERRORS ===")
		
		for err in last_errors:
			export_handle.store_line(err)
		
		export_handle.close()
		log_message("EXPORT", "Logs exported to: " + export_path)
		return export_path
	
	return ""